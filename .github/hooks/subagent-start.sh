#!/bin/bash
# SubagentStart Hook - Load memory for subagent
# Loads specific memory based on agent type

python3 -c '
import sys, json, os

try:
    input_str = sys.stdin.read()
    if not input_str:
        sys.exit(0)

    data = json.loads(input_str)
    agent_type = data.get("agent_type")
    agent_id = data.get("agent_id")
    memory_dir = ".github/memory"
    
    memory_map = {
        "Crawler Expert": "crawler-memory.json",
        "Database Expert": "database-memory.json",
        "Frontend Engineer": "frontend-memory.json"
    }
    
    memory_file = memory_map.get(agent_type)
    
    if memory_file:
        file_path = os.path.join(memory_dir, memory_file)
        if os.path.exists(file_path):
            with open(file_path, "r") as f:
                agent_memory = json.load(f)
            
            solved_problems_json = json.dumps(agent_memory.get("solved_problems", []), indent=2, ensure_ascii=False)
            best_practices = "\n- ".join(agent_memory.get("best_practices", []))
            tools_libs = ", ".join(agent_memory.get("tools_and_libraries", []))
            last_update = agent_memory.get("last_update", "Unknown")
            
            context = f"""
## {agent_type} Memory Loaded (Agent ID: {agent_id})

**Last Update**: {last_update}

### Solved Problems:
{solved_problems_json}

### Best Practices:
- {best_practices}

### Tools & Libraries:
{tools_libs}

---
**IMPORTANT**: Check solved problems before starting task to avoid repetition.
"""
            output = {
                "continue": True,
                "hookSpecificOutput": {
                    "hookEventName": "SubagentStart",
                    "additionalContext": context
                }
            }
        else:
            output = {
                "continue": True,
                "systemMessage": f"Memory file not found for {agent_type}"
            }
    else:
        # Unknown agent type or no memory mapping
        output = {
            "continue": True
            # Optional: systemMessage could be added if we want to warn
        }

    print(json.dumps(output))

except Exception as e:
     print(json.dumps({"continue": True, "systemMessage": f"SubagentStart Hook Error: {str(e)}"}))
'
