#!/usr/bin/env python3
"""
MCP Connection Test Script

Run this script to verify your Grasshopper MCP setup is working correctly.

Usage:
    uv run python test_mcp_connection.py

Requirements:
    - Rhino 8 must be running
    - Grasshopper must be open
    - The MCP server must be active (check Grasshopper menu)
    - A Python 3 Script component should be on the canvas (for full test)
"""

import sys
import json

# Check Python version
if sys.version_info < (3, 10):
    print("❌ Python 3.10+ required")
    sys.exit(1)

try:
    import httpx
except ImportError:
    print("❌ httpx not installed. Run: uv sync")
    sys.exit(1)

MCP_URL = "http://127.0.0.1:8089/mcp"
TIMEOUT = 10  # seconds


def test_connection() -> bool:
    """Test basic connectivity to the MCP server."""
    print("\n" + "=" * 50)
    print("TEST 1: MCP Server Connection")
    print("=" * 50)

    try:
        with httpx.Client(timeout=TIMEOUT) as client:
            # Just try to connect - even a failed request means server is there
            response = client.post(MCP_URL, json={"jsonrpc": "2.0", "id": 1, "method": "ping"})
            print(f"✅ Server responding at {MCP_URL}")
            return True
    except httpx.ConnectError:
        print(f"❌ Cannot connect to {MCP_URL}")
        print("\n   Possible causes:")
        print("   1. Rhino/Grasshopper is not running")
        print("   2. MCP server is not started in Grasshopper")
        print("   3. Wrong port (default is 8089)")
        return False
    except httpx.TimeoutException:
        print(f"❌ Connection timed out")
        print("   The server may be starting up. Try again in a few seconds.")
        return False
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return False


def test_tools_list() -> tuple[bool, list]:
    """Test fetching the tools list from MCP."""
    print("\n" + "=" * 50)
    print("TEST 2: Fetching Available Tools")
    print("=" * 50)

    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/list",
        "params": {}
    }

    try:
        with httpx.Client(timeout=TIMEOUT) as client:
            with client.stream("POST", MCP_URL, json=payload) as response:
                for line in response.iter_lines():
                    if line.startswith("data: "):
                        data = json.loads(line[6:])
                        if "result" in data and "tools" in data["result"]:
                            tools = data["result"]["tools"]
                            print(f"✅ Found {len(tools)} tools available")

                            # Check for the specific tools we need
                            tool_names = [t["name"] for t in tools]
                            required_tools = [
                                "List_Python_Scripts",
                                "Get_Python_Script",
                                "Edit_Python_Script",
                                "Get_Python_Script_Errors"
                            ]

                            missing = [t for t in required_tools if t not in tool_names]
                            if missing:
                                print(f"⚠️  Missing tools: {missing}")
                            else:
                                print("✅ All required Python script tools available")

                            return True, tools

        print("❌ No tools returned from server")
        return False, []

    except Exception as e:
        print(f"❌ Error fetching tools: {e}")
        return False, []


def test_python_scripts() -> bool:
    """Test listing Python script components in Grasshopper."""
    print("\n" + "=" * 50)
    print("TEST 3: Detecting Python Script Components")
    print("=" * 50)

    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": "List_Python_Scripts",
            "arguments": {}
        }
    }

    try:
        with httpx.Client(timeout=TIMEOUT) as client:
            with client.stream("POST", MCP_URL, json=payload) as response:
                for line in response.iter_lines():
                    if line.startswith("data: "):
                        data = json.loads(line[6:])
                        if "result" in data:
                            result = data["result"]

                            # Parse the nested response
                            if "content" in result:
                                for content in result["content"]:
                                    if content.get("type") == "text":
                                        scripts = json.loads(content["text"])
                                        if scripts:
                                            print(f"✅ Found {len(scripts)} Python script component(s):")
                                            for script in scripts:
                                                name = script.get("nickName") or script.get("name", "Unknown")
                                                script_id = script.get("id", "?")[:8]
                                                print(f"   • {name} (ID: {script_id}...)")
                                            return True
                                        else:
                                            print("⚠️  No Python script components found on canvas")
                                            print("\n   To complete the tutorial:")
                                            print("   1. Open examples/task_template.gh in Grasshopper")
                                            print("   2. Or add a Python 3 Script component manually")
                                            return False

        print("❌ Could not parse response")
        return False

    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def test_groq_api() -> bool:
    """Test Groq API connectivity (optional)."""
    print("\n" + "=" * 50)
    print("TEST 4: Groq API Key (Optional)")
    print("=" * 50)

    import os
    api_key = os.environ.get("GROQ_API_KEY", "")

    if not api_key:
        print("⚠️  GROQ_API_KEY not set in environment")
        print("   You can still set it directly in the notebook")
        return False

    if api_key == "your-api-key-here":
        print("⚠️  GROQ_API_KEY is placeholder value")
        return False

    try:
        from groq import Groq
        client = Groq(api_key=api_key)
        response = client.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=[{"role": "user", "content": "Say 'test'"}],
            max_tokens=5
        )
        print("✅ Groq API key is valid")
        return True
    except ImportError:
        print("⚠️  groq package not installed. Run: uv sync")
        return False
    except Exception as e:
        print(f"❌ Groq API error: {e}")
        return False


def main():
    print("\n" + "=" * 50)
    print("   MCP Connection Test for ReAct Tutorial")
    print("=" * 50)
    print(f"\nTesting connection to: {MCP_URL}")

    results = {}

    # Test 1: Basic connection
    results["connection"] = test_connection()

    if results["connection"]:
        # Test 2: Tools list
        results["tools"], _ = test_tools_list()

        if results["tools"]:
            # Test 3: Python scripts
            results["scripts"] = test_python_scripts()

    # Test 4: Groq API (independent)
    results["groq"] = test_groq_api()

    # Summary
    print("\n" + "=" * 50)
    print("   SUMMARY")
    print("=" * 50)

    all_required_passed = results.get("connection", False) and results.get("tools", False)

    if all_required_passed and results.get("scripts", False):
        print("\n✅ All tests passed! You're ready for the tutorial.")
    elif all_required_passed:
        print("\n⚠️  MCP server works, but no Python script component found.")
        print("   Open examples/task_template.gh in Grasshopper before starting.")
    else:
        print("\n❌ Setup incomplete. Please check the errors above.")
        print("\nQuick checklist:")
        print("   [ ] Rhino 8 is running")
        print("   [ ] Grasshopper is open")
        print("   [ ] MCP server is active (check Grasshopper menu)")
        print("   [ ] examples/task_template.gh is loaded")

    print()
    return 0 if all_required_passed else 1


if __name__ == "__main__":
    sys.exit(main())
