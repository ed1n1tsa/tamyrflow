//
//  SupabaseManager.swift
//  TamyrFlowApp
//  Created by Macbook on 17.02.2026.
//

import Foundation
import Supabase

enum SupabaseManager {
    // Вставь свои данные:
    static let supabaseURL = URL(string: "https://utabnczoilfzvfmfkadn.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV0YWJuY3pvaWxmenZmbWZrYWRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExMjk0MzQsImV4cCI6MjA4NjcwNTQzNH0.1_E82Zc7Y-6PbrG-c9vxhm5cYN1qE_U4Nr2OmH6-pKk"

    static let client = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseAnonKey
    )
}
