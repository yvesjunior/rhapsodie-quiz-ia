<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Http\Resources\QcmResource;
use App\Models\Qcm;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class QcmController extends Controller
{
    /**
     * Display a listing of QCMs
     */
    public function index()
    {
        $qcms = Qcm::where('is_active', true)
            ->orderBy('created_at', 'desc')
            ->get();
        
        return QcmResource::collection($qcms);
    }

    /**
     * Store a newly created QCM (from Python generator)
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'questions' => 'required|array|min:1',
            'questions.*.question' => 'required|string',
            'questions.*.options' => 'required|array|min:2',
            'questions.*.correct_answers' => 'required|array|min:1',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors()
            ], 422);
        }

        $qcm = Qcm::create([
            'title' => $request->title,
            'questions' => $request->questions,
            'total_questions' => count($request->questions),
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'QCM created successfully',
            'data' => new QcmResource($qcm),
            'id' => $qcm->id,
        ], 201);
    }

    /**
     * Display the specified QCM
     */
    public function show($id)
    {
        $qcm = Qcm::findOrFail($id);
        
        return new QcmResource($qcm);
    }

    /**
     * Remove the specified QCM
     */
    public function destroy($id)
    {
        $qcm = Qcm::findOrFail($id);
        $qcm->delete();

        return response()->json([
            'success' => true,
            'message' => 'QCM deleted successfully'
        ]);
    }
}

