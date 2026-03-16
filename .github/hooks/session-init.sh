#!/bin/bash
# SessionStart Hook - Initialize session and load memory
# This script runs at the start of an Agent session

# Use python to handle JSON robustly
python3 -c '
import sys, json, os, datetime

try:
    # Read input from stdin
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)
    
    data = json.loads(input_str)
    session_id = data.get("sessionId", "unknown")
    memory_dir = ".github/memory"
    
    # Read project state
    project_state_path = os.path.join(memory_dir, "project-state.json")
    
    if os.path.exists(project_state_path):
        with open(project_state_path, "r") as f:
            project_state = json.load(f)
            
        # Construct context
        context_data = {
            "project_name": project_state.get("project_name"),
            "last_update": project_state.get("last_update"),
            "active_tasks": project_state.get("active_tasks"),
            "known_issues": project_state.get("known_issues"),
            "session_id": session_id
        }
        
        # Format additional context string
        # We format it as a markdown/text block similar to the PS1 script
        additional_context = f"""
## Project Memory Loaded
Project: {context_data["project_name"]}
Last Update: {context_data["last_update"]}

### Active Tasks:
"""
        for task in context_data.get("active_tasks", []):
             additional_context += f"- {task}\n"
             
        additional_context += "\n### Known Issues:\n"
        for issue in context_data.get("known_issues", []):
            additional_context += f"- {issue}\n"

        output = {
            "continue": True,
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": additional_context
            }
        }
        
        print(json.dumps(output))
    else:
        # If no memory file, just continue
        print(json.dumps({"continue": True}))

except Exception as e:
    # Returning continue: true ensures the session allows to start even if hook fails
    print(json.dumps({"continue": True, "systemMessage": f"SessionStart Hook Error: {str(e)}"}))
'
