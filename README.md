# ReAct Agent Tutorial

## Quick Setup (Automated)

**Close Rhino first** (if open), then run the PowerShell setup script:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

This will:
- Copy the MCP plugin to your Grasshopper Libraries folder
- Install `uv` package manager (if not present)
- Install Python dependencies

**Still requires manual steps:**
- Get a Groq API key (free, see below)
- Open Rhino/Grasshopper with the template file

---

## Manual Installation

### 1. Install the Grasshopper MCP Plugin

Copy the `Libraries` folder contents to your Grasshopper Libraries folder:

1. Open File Explorer and navigate to this repository's `Libraries` folder
2. Copy the entire `ABxM.Agentic.MCP` folder
3. Paste it into your Grasshopper Libraries folder:
   ```
   C:\Users\<YOUR_USERNAME>\AppData\Roaming\Grasshopper\Libraries
   ```
   **Replace `<YOUR_USERNAME>` with your Windows username** (e.g., `C:\Users\John\AppData\...`)

4. Restart Rhino/Grasshopper if it's already running

### 2. Get your FREE Groq API key

1. Go to [console.groq.com](https://console.groq.com)
2. Sign up (free, no credit card required)
3. Navigate to **API Keys** and create a new key
4. Copy your key - you'll need it in the notebook

#### Verify your API key works

**Windows CMD / Mac / Linux (curl is built-in on Windows 10+):**
```bash
curl -X POST "https://api.groq.com/openai/v1/chat/completions" -H "Authorization: Bearer YOUR_API_KEY_HERE" -H "Content-Type: application/json" -d "{\"model\": \"llama-3.3-70b-versatile\", \"messages\": [{\"role\": \"user\", \"content\": \"Say hello\"}], \"max_tokens\": 10}"
```

**Success looks like:**
```json
{"id":"chatcmpl-...","object":"chat.completion","choices":[{"message":{"role":"assistant","content":"Hello. How can I assist you today?"}}],...}
```
Look for `"content":"Hello..."` in the response - that means your key works!

### 3. Install uv (if not already installed)

**Windows (PowerShell):**
```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

After installation, restart your terminal.

### 4. Install dependencies

```bash
uv sync
```

### 5. Launch Jupyter

**Option A: VS Code / Cursor / Windsurf**
1. Install the **Jupyter** extension from the marketplace
2. Open `notebooks/react_agent_student.ipynb` in the editor
3. Select the correct Python kernel (top-right corner):
   - Click **Select Kernel**
   - Choose **Python Environments...**
   - Select the `.venv` interpreter (should show `.venv (Python 3.x.x)`)
   - If `.venv` doesn't appear, run `uv sync` first, then reload the window (`Ctrl+Shift+P` → "Reload Window")
4. Run cells with `Shift+Enter`

**Option B: Browser (classic Jupyter)**
```bash
uv run jupyter notebook notebooks/react_agent_student.ipynb
```

### 6. Set your API key

In the notebook, replace `"your-api-key-here"` with your Groq API key.

### 7. Verify your setup (optional)

Run the test script to check everything is working:

```bash
uv run python test_mcp_connection.py
```

This will verify:
- MCP server is running and accessible
- Required tools are available
- Python script component is on the Grasshopper canvas
- Groq API key is valid (if set)

## task_template.gh

This Grasshopper file contains a pre-configured Python 3 Script component for the tutorial.

### Setup Instructions

1. Open Rhino 8
2. Open Grasshopper
3. Open `examples/task_template.gh`
4. Ensure the MCP server is running (check Grasshopper menu)
5. Run the Jupyter notebook

### What's Included

- One Python 3 Script component named "Task"
- The component has one output (a) for geometry
- The MCP server should detect this component automatically

### Troubleshooting

**"No Python script components found"**
- Make sure Grasshopper is open with this file
- Check that the MCP server is running

**"Connection refused"**
- The MCP server runs on port **8089** by default: `http://127.0.0.1:8089/mcp`
- Verify the server is running in Grasshopper's MCP settings

---

## MCP Configuration for IDEs

The `.vscode/mcp.json` file allows VS Code (and other MCP-compatible tools) to connect directly to the Grasshopper MCP server.

### Using with VS Code / GitHub Copilot

1. Open this folder in VS Code
2. The `.vscode/mcp.json` is auto-detected
3. VS Code Copilot can now use Grasshopper tools directly

### Using with Other IDEs

Copy the configuration to your IDE's MCP config location:

| IDE | Config Location |
|-----|-----------------|
| **VS Code** | `.vscode/mcp.json` (workspace) or User MCP settings |
| **Cursor** | `~/.cursor/mcp.json` |
| **Antigravity** | `...` menu → MCP → Manage MCP Servers → View raw config |
| **Claude Desktop** | `~/Library/Application Support/Claude/claude_desktop_config.json` (Mac) |
| **LM Studio** | Settings → Plugins → Edit `mcp.json` |

### Configuration Format

**VS Code** (`.vscode/mcp.json`):
```json
{
  "servers": {
    "grasshopper": {
      "type": "sse",
      "url": "http://127.0.0.1:8089/mcp"
    }
  }
}
```

**Cursor** (`~/.cursor/mcp.json`):
```json
{
  "mcpServers": {
    "grasshopper": {
      "url": "http://127.0.0.1:8089/mcp"
    }
  }
}
```

**Claude Desktop** (`claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "grasshopper": {
      "url": "http://127.0.0.1:8089/mcp"
    }
  }
}
```

**Antigravity** (via MCP -> Manage MCP Servers -> View raw config):
```json
{
  "mcpServers": {
    "grasshopper": {
      "url": "http://127.0.0.1:8089/mcp"
    }
  }
}
```

**Key differences:**
- VS Code uses `"servers"` + explicit `"type": "sse"`
- Cursor/Claude/Antigravity use `"mcpServers"` + just `"url"` (type is auto-detected)

### Verify MCP Connection

Test the server is responding:
```bash
curl -X POST "http://127.0.0.1:8089/mcp" -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}"
```
