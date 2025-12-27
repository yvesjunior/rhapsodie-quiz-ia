"""
pdf_to_qcm_full.py

Full-featured PDF -> QCM generator using Ollama (local) or any compatible chat API.
Features included (all as requested):
 1) Automatic PDF chunking
 2) Automatic retry if JSON invalid (configurable retries)
 3) Explanations per question
 4) Streamlit web interface
 5) Tkinter desktop app
 6) JSON output option
 7) YAML output option

Notes & requirements:
 - Python 3.10+
 - Recommended packages (pip install):
     pip install pypdf ollama streamlit pyyaml
 - Ollama must be installed & a model pulled (e.g., `ollama pull llama3`)
 - This script is intentionally monolithic for convenience; feel free to split into modules.

Usage (CLI):
  python pdf_to_qcm_full.py --input input.pdf --outdir outputs --model llama3

Or run streamlit UI:
  streamlit run pdf_to_qcm_full.py -- --ui streamlit

Or run Tkinter UI:
  python pdf_to_qcm_full.py --ui tk

"""

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass
from typing import List, Dict, Any, Optional

# PDF reading
from pypdf import PdfReader

# Ollama client (assumes ollama python package)
import ollama

# Exports
import yaml

# Streamlit and Tkinter (optional)
try:
    import streamlit as st
except Exception:
    st = None

try:
    import tkinter as tk
    from tkinter import filedialog, messagebox
except Exception:
    tk = None

# ---------------------------
# Configuration dataclass
# ---------------------------
@dataclass
class Config:
    model: str = "llama3"
    n_questions: int = 10
    min_options: int = 3
    max_options: int = 5
    include_explanations: bool = True
    retries: int = 3
    chunk_size_words: int = 1400  # conservative chunk size for small models
    outdir: str = "outputs"
    api_url: Optional[str] = None  # Laravel API URL (e.g., "http://localhost:8000/api/qcm")
    api_token: Optional[str] = None  # API authentication token

# ---------------------------
# Utilities
# ---------------------------

def ensure_outdir(path: str):
    os.makedirs(path, exist_ok=True)


def extract_text_from_pdf(pdf_path: str) -> str:
    reader = PdfReader(pdf_path)
    text_parts = []
    for i, page in enumerate(reader.pages):
        txt = page.extract_text()
        if txt:
            text_parts.append(txt)
    return "\n\n".join(text_parts)


def extract_text_from_multiple_pdfs(pdf_paths: List[str]) -> str:
    """Extract and combine text from multiple PDF files."""
    all_text_parts = []
    for pdf_path in pdf_paths:
        text = extract_text_from_pdf(pdf_path)
        if text.strip():
            all_text_parts.append(text)
    return "\n\n---\n\n".join(all_text_parts)  # Separator between PDFs


def chunk_text_by_words(text: str, words_per_chunk: int) -> List[str]:
    words = text.split()
    chunks = []
    for i in range(0, len(words), words_per_chunk):
        chunk = " ".join(words[i:i + words_per_chunk])
        chunks.append(chunk)
    return chunks


def clean_json_like(s: str) -> str:
    # Attempt to find the first JSON array or object in the output
    # Simple heuristic: locate first '[' or '{' and last matching ']' or '}'
    first = min([idx for idx in [s.find('['), s.find('{')] if idx >= 0]) if ('[' in s or '{' in s) else 0
    if first is None:
        return s
    trimmed = s[first:]
    # Try to balance brackets by trimming trailing junk
    # This is heuristic and not perfect
    stack = []
    for i, ch in enumerate(trimmed):
        if ch in '[{':
            stack.append(ch)
        elif ch in ']}':
            if stack:
                stack.pop()
            if not stack:
                return trimmed[:i+1]
    return trimmed

# ---------------------------
# Ollama interaction
# ---------------------------

def build_prompt_for_chunk(text_chunk: str, cfg: Config) -> str:
    # Instruction to generate questions with multiple correct answers and explanations
    explanation_requirement = "MUST include a detailed explanation for each question explaining why the correct answer(s) is/are correct." if cfg.include_explanations else "You may include explanations if helpful."
    
    prompt = f"""
You are a helpful exam generator. Using only the content provided, produce exactly {cfg.n_questions} multiple-choice questions (QCM).

Requirements:
- Each question must have between {cfg.min_options} and {cfg.max_options} options, labelled A, B, C, ...
- One or more options may be correct for each question.
- Provide a list of correct answers as a list of letters, e.g. ["A"] or ["A","C"].
- {explanation_requirement}
- If the content contains reference verses (e.g., Bible verses like "John 18:36", "Luke 17:21", "Isaiah 53:10"), you MUST include them in a "reference" field for each question.
- Output MUST be valid JSON and contain ONLY the JSON (no preface, no trailing commentary).

Output format (example):
[
  {{
    "question": "...",
    "options": ["A. ...", "B. ...", "C. ..."],
    "correct_answers": ["A","C"],
    "explanation": "A and C are correct because...",
    "reference": "John 18:36"
  }},
  ...
]

IMPORTANT: 
- Every question MUST have a non-empty explanation field with meaningful content explaining the correct answer(s).
- Explanations must be direct and concise. Do NOT use introductory phrases like "According to the provided content", "Based on the text", "The content states", etc. Start directly with the explanation of why the answer is correct.
- If a reference verse is mentioned in the content related to the question, include it in the "reference" field. If no specific verse is mentioned, use an empty string "" for the reference field.

CONTENT:
{text_chunk}
"""
    return prompt


def call_model_for_json(prompt: str, cfg: Config) -> Optional[List[Dict[str, Any]]]:
    # Uses ollama.chat
    for attempt in range(1, cfg.retries + 1):
        try:
            resp = ollama.chat(model=cfg.model, messages=[{"role": "user", "content": prompt}])
            raw = resp.get("message", {}).get("content", "")
            candidate = clean_json_like(raw)
            data = json.loads(candidate)
            return data
        except ConnectionError as e:
            print(f"Connection error: Ollama may not be running. Please start Ollama service.")
            raise
        except Exception as e:
            error_msg = str(e)
            if "model" in error_msg.lower() or "not found" in error_msg.lower():
                print(f"Model '{cfg.model}' not found. Please pull it with: ollama pull {cfg.model}")
                raise
            print(f"Attempt {attempt} failed to parse JSON: {e}")
            if attempt == cfg.retries:
                print("All retries exhausted.")
                return None
            print("Retrying...")
    return None

# ---------------------------
# Aggregation & validation
# ---------------------------

def merge_question_lists(lists: List[List[Dict[str, Any]]], n_questions: int) -> List[Dict[str, Any]]:
    # Flatten and take up to n_questions, with simple deduplication by question text
    seen = set()
    out = []
    for lst in lists:
        if not lst:
            continue
        for q in lst:
            qtext = q.get("question", "").strip()
            if not qtext:
                continue
            if qtext.lower() in seen:
                continue
            seen.add(qtext.lower())
            out.append(q)
            if len(out) >= n_questions:
                return out
    return out

# ---------------------------
# Exporters
# ---------------------------

def export_json(qcm: List[Dict[str, Any]], path: str):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(qcm, f, indent=2, ensure_ascii=False)


def export_yaml(qcm: List[Dict[str, Any]], path: str):
    with open(path, "w", encoding="utf-8") as f:
        yaml.safe_dump(qcm, f, allow_unicode=True)


def push_to_api(qcm: List[Dict[str, Any]], api_url: str, api_token: Optional[str] = None, title: Optional[str] = None) -> bool:
    """Push QCM JSON to Laravel API endpoint."""
    try:
        import requests
        
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        
        if api_token:
            headers["Authorization"] = f"Bearer {api_token}"
        
        payload = {
            "questions": qcm,
            "title": title or f"QCM Generated {os.path.basename(__file__)}"
        }
        
        response = requests.post(api_url, json=payload, headers=headers, timeout=30)
        
        if response.status_code in [200, 201]:
            print(f"✅ Successfully pushed QCM to API: {api_url}")
            result = response.json()
            # Handle nested response structure
            qcm_id = result.get('id') or (result.get('data', {}).get('id') if isinstance(result.get('data'), dict) else None)
            if qcm_id:
                print(f"   QCM ID: {qcm_id}")
            return True
        else:
            print(f"❌ Failed to push to API. Status: {response.status_code}")
            try:
                error_data = response.json()
                print(f"   Error: {error_data.get('message', 'Unknown error')}")
                if 'errors' in error_data:
                    print(f"   Details: {error_data['errors']}")
            except:
                print(f"   Response: {response.text}")
            return False
            
    except ImportError:
        print("❌ 'requests' library not installed. Install it with: pip install requests")
        return False
    except Exception as e:
        print(f"❌ Error pushing to API: {e}")
        return False

# ---------------------------
# Main pipeline
# ---------------------------

def generate_qcm_from_pdf(pdf_path: str, cfg: Config) -> Optional[List[Dict[str, Any]]]:
    """Generate QCM from a single PDF file."""
    return generate_qcm_from_pdfs([pdf_path], cfg)


def generate_qcm_from_pdfs(pdf_paths: List[str], cfg: Config) -> Optional[List[Dict[str, Any]]]:
    """Generate QCM from one or multiple PDF files."""
    if len(pdf_paths) == 1:
        print(f"Extracting PDF: {pdf_paths[0]}")
    else:
        print(f"Extracting text from {len(pdf_paths)} PDF files...")
    
    text = extract_text_from_multiple_pdfs(pdf_paths)
    if not text.strip():
        print("No text extracted from PDF(s).")
        return None

    print("Chunking text...")
    chunks = chunk_text_by_words(text, cfg.chunk_size_words)
    print(f"Created {len(chunks)} chunk(s).")

    all_results = []
    for i, chunk in enumerate(chunks):
        print(f"Processing chunk {i+1}/{len(chunks)}...")
        prompt = build_prompt_for_chunk(chunk, cfg)
        res = call_model_for_json(prompt, cfg)
        if res is None:
            print(f"Chunk {i+1} failed to produce valid JSON.")
            continue
        all_results.append(res)

    merged = merge_question_lists(all_results, cfg.n_questions)
    if not merged:
        print("No questions generated.")
        return None

    # If we have fewer than requested, warn but return what we have
    if len(merged) < cfg.n_questions:
        print(f"Warning: only {len(merged)} questions generated (requested {cfg.n_questions}).")

    return merged

# ---------------------------
# CLI & UI
# ---------------------------

def parse_args():
    parser = argparse.ArgumentParser(description="PDF -> QCM full tool")
    parser.add_argument('--input', '-i', type=str, help='Input PDF path')
    parser.add_argument('--outdir', '-o', type=str, default='outputs')
    parser.add_argument('--model', type=str, default='llama3')
    parser.add_argument('--n_questions', type=int, default=10)
    parser.add_argument('--ui', type=str, choices=['cli', 'streamlit', 'tk'], default='cli')
    parser.add_argument('--chunk_words', type=int, default=1400)
    parser.add_argument('--retries', type=int, default=3)
    parser.add_argument('--include_explanations', action='store_true')
    parser.add_argument('--no-explanations', dest='include_explanations', action='store_false')
    parser.add_argument('--api-url', type=str, help='Laravel API URL to push QCM (e.g., http://localhost:8000/api/qcm)')
    parser.add_argument('--api-token', type=str, help='API authentication token')
    parser.add_argument('--api-title', type=str, help='Title for the QCM when pushing to API')
    return parser.parse_args()


# Streamlit app
def run_streamlit_ui(cfg: Config):
    if st is None:
        print("Streamlit not installed. Please install streamlit to use the UI.")
        return
    st.title("PDF → QCM Generator (Local Ollama)")
    uploaded_files = st.file_uploader("Upload PDF file(s)", type=['pdf'], accept_multiple_files=True)
    cfg.n_questions = st.number_input("Number of questions", min_value=1, max_value=100, value=cfg.n_questions)
    cfg.include_explanations = st.checkbox("Include explanations", value=cfg.include_explanations)
    cfg.model = st.text_input("Model (ollama)", value=cfg.model)
    
    # API Push Options
    st.subheader("📤 Push to Laravel API (Optional)")
    push_to_api_enabled = st.checkbox("Push QCM to API after generation", value=False)
    if push_to_api_enabled:
        cfg.api_url = st.text_input("API URL", value=cfg.api_url or "http://localhost:8000/api/qcm", help="Laravel API endpoint URL")
        cfg.api_token = st.text_input("API Token (Required)", value=cfg.api_token or "", type="password", help="Bearer token for authentication. Get it from Laravel: docker-compose exec app php artisan tinker")
        qcm_title = st.text_input("QCM Title (Optional)", value="", help="Title for this QCM set")
        
        # Show current token info
        if cfg.api_token:
            st.info(f"🔑 Token configured: {cfg.api_token[:10]}...{cfg.api_token[-10:] if len(cfg.api_token) > 20 else ''}")
        else:
            st.warning("⚠️ API Token is required. Generate one with: `docker-compose exec app php artisan tinker` then: `$user->createToken('qcm-generator')->plainTextToken`")

    # Check if Ollama is available
    try:
        result = subprocess.run(['ollama', 'list'], capture_output=True, text=True, timeout=5)
        if result.returncode != 0:
            st.warning("⚠️ Ollama may not be installed or running. Please install Ollama from https://ollama.ai")
    except (FileNotFoundError, subprocess.TimeoutExpired):
        st.warning("⚠️ Ollama is not installed. Please install it from https://ollama.ai and ensure it's running.")
    except Exception:
        pass  # Silently continue if check fails
    
    if uploaded_files:
        if len(uploaded_files) == 1:
            st.info(f"📄 1 PDF file ready: {uploaded_files[0].name}")
        else:
            st.info(f"📄 {len(uploaded_files)} PDF files ready: {', '.join([f.name for f in uploaded_files])}")
        
        if st.button("Generate QCM"):
            with st.spinner('Generating...'):
                try:
                    # Save all uploaded PDFs to temporary files
                    temp_pdf_paths = []
                    for i, uploaded_file in enumerate(uploaded_files):
                        temp_path = f'tmp_input_{i}_{uploaded_file.name}'
                        with open(temp_path, 'wb') as f:
                            f.write(uploaded_file.getbuffer())
                        temp_pdf_paths.append(temp_path)
                    
                    # Generate QCM from all PDFs combined
                    qcm = generate_qcm_from_pdfs(temp_pdf_paths, cfg)
                    
                    # Clean up temporary files
                    for temp_path in temp_pdf_paths:
                        try:
                            os.remove(temp_path)
                        except:
                            pass
                    
                    if qcm:
                        st.success(f"Generated {len(qcm)} questions from {len(uploaded_files)} PDF file(s)")
                        st.download_button("Download JSON", json.dumps(qcm, ensure_ascii=False, indent=2), file_name='qcm.json')
                        
                        # Push to API if enabled
                        if push_to_api_enabled and cfg.api_url:
                            if not cfg.api_token or cfg.api_token.strip() == "":
                                st.error("❌ API Token is required to push to API. Please enter your token.")
                            else:
                                with st.spinner('Pushing to API...'):
                                    title = qcm_title if qcm_title else f"QCM from {', '.join([f.name for f in uploaded_files])}"
                                    if push_to_api(qcm, cfg.api_url, cfg.api_token.strip(), title):
                                        st.success("✅ QCM pushed to API successfully!")
                                    else:
                                        st.error("❌ Failed to push to API. Check the details below.")
                                        st.info("💡 Make sure your API token is valid. Generate a new one if needed.")
                    else:
                        st.error('Failed to generate QCM. Check the console for details.')
                except ConnectionError:
                    st.error("❌ Cannot connect to Ollama. Please ensure Ollama is installed and running.")
                    st.info("Install Ollama from https://ollama.ai, then start it and pull a model: `ollama pull llama3`")
                except Exception as e:
                    error_msg = str(e)
                    if "model" in error_msg.lower() or "not found" in error_msg.lower():
                        st.error(f"❌ Model '{cfg.model}' not found. Please pull it with: `ollama pull {cfg.model}`")
                    else:
                        st.error(f"❌ Error: {error_msg}")
                        st.info("Check the console output for more details.")

# Tkinter app

def run_tk_ui(cfg: Config):
    if tk is None:
        print("Tkinter not available in this environment.")
        return
    root = tk.Tk()
    root.title('PDF → QCM Generator')
    root.geometry('500x200')

    def choose_file():
        path = filedialog.askopenfilename(filetypes=[('PDF files','*.pdf')])
        entry.delete(0, tk.END)
        entry.insert(0, path)

    def on_generate():
        pdf_path = entry.get().strip()
        if not pdf_path or not os.path.exists(pdf_path):
            messagebox.showerror('Error', 'Please select a valid PDF file')
            return
        cfg.model = model_entry.get().strip() or cfg.model
        cfg.n_questions = int(nq_entry.get())
        cfg.include_explanations = bool(explain_var.get())
        qcm = generate_qcm_from_pdf(pdf_path, cfg)
        if qcm:
            ensure_outdir(cfg.outdir)
            export_json(qcm, os.path.join(cfg.outdir, 'qcm.json'))
            export_yaml(qcm, os.path.join(cfg.outdir, 'qcm.yaml'))
            messagebox.showinfo('Done', f'Generated {len(qcm)} questions. Files saved in {cfg.outdir}')
        else:
            messagebox.showerror('Error', 'Failed to generate QCM')

    tk.Label(root, text='PDF:').pack()
    entry = tk.Entry(root, width=60)
    entry.pack()
    tk.Button(root, text='Browse', command=choose_file).pack()

    tk.Label(root, text='Model:').pack()
    model_entry = tk.Entry(root, width=30)
    model_entry.insert(0, cfg.model)
    model_entry.pack()

    tk.Label(root, text='Number of questions:').pack()
    nq_entry = tk.Entry(root, width=5)
    nq_entry.insert(0, str(cfg.n_questions))
    nq_entry.pack()

    explain_var = tk.IntVar(value=1 if cfg.include_explanations else 0)
    tk.Checkbutton(root, text='Include explanations', variable=explain_var).pack()

    tk.Button(root, text='Generate', command=on_generate).pack(pady=10)

    root.mainloop()

# ---------------------------
# Entry
# ---------------------------

def main():
    # Check if running under Streamlit by checking if st is available and we're not in CLI mode
    # When streamlit run is used, st module is available and we should run the UI directly
    if st is not None and len(sys.argv) == 1:
        # Likely running under Streamlit without arguments
        cfg = Config()
        run_streamlit_ui(cfg)
        return
    
    args = parse_args()
    cfg = Config(
        model=args.model,
        n_questions=args.n_questions,
        include_explanations=args.include_explanations,
        retries=args.retries,
        chunk_size_words=args.chunk_words,
        outdir=args.outdir,
        api_url=args.api_url,
        api_token=args.api_token
    )

    ensure_outdir(cfg.outdir)

    if args.ui == 'streamlit':
        run_streamlit_ui(cfg)
        return
    if args.ui == 'tk':
        run_tk_ui(cfg)
        return

    # CLI flow
    if not args.input:
        print("Please provide --input PDF when running in CLI mode.")
        sys.exit(1)

    qcm = generate_qcm_from_pdf(args.input, cfg)
    if not qcm:
        print("Failed to generate QCM.")
        sys.exit(2)

    # Export everything
    base = cfg.outdir
    ensure_outdir(base)
    json_path = os.path.join(base, 'qcm.json')
    yaml_path = os.path.join(base, 'qcm.yaml')

    export_json(qcm, json_path)
    export_yaml(qcm, yaml_path)

    print(f"Exports saved to {base}:")
    print(" -", json_path)
    print(" -", yaml_path)
    
    # Push to API if configured
    if cfg.api_url:
        title = args.api_title or f"QCM from {os.path.basename(args.input)}"
        push_to_api(qcm, cfg.api_url, cfg.api_token, title)

if __name__ == '__main__':
    main()
