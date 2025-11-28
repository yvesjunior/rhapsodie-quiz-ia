<?php
/**
 * Environment Variables Helper
 * 
 * Loads environment variables from .env file for local development
 * In production, use system environment variables or Docker environment variables
 */

if (!function_exists('load_env_file')) {
    /**
     * Load environment variables from .env file
     * 
     * @param string $path Path to .env file
     * @return void
     */
    function load_env_file($path = null)
    {
        if ($path === null) {
            // Default to project root
            $path = FCPATH . '../../.env';
        }

        if (!file_exists($path)) {
            return;
        }

        $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            // Skip comments
            if (strpos(trim($line), '#') === 0) {
                continue;
            }

            // Parse KEY=VALUE
            if (strpos($line, '=') !== false) {
                list($key, $value) = explode('=', $line, 2);
                $key = trim($key);
                $value = trim($value);

                // Remove quotes if present
                $value = trim($value, '"\'');
                
                // Only set if not already set (environment variables take precedence)
                if (!getenv($key)) {
                    putenv("$key=$value");
                    $_ENV[$key] = $value;
                    $_SERVER[$key] = $value;
                }
            }
        }
    }
}

