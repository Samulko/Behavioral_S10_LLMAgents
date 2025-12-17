# ReAct Agent Tutorial

Learn to build LLM agents that can control Grasshopper using the ReAct framework.

---

## Before the Lesson (Setup)

Complete these steps **before class** so you're ready to go.

### 1. Quick Setup (Automated)

**Close Rhino first** (if open), then run the PowerShell setup script:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

This will:
- Copy the MCP plugin to your Grasshopper Libraries folder
- Install `uv` package manager (if not present)
- Install Python dependencies

**Or follow the [Manual Installation](#manual-installation) steps below.**

### 2. Get your FREE Groq API Key

1. Go to [console.groq.com](https://console.groq.com)
2. Sign up (free, no credit card required)
3. Navigate to **API Keys** and create a new key
4. Copy your key

> **Note:** If you'd prefer not to create an account, no worries! An alternative API key will be provided during the session.

### 3. Save your API Key

Copy `.env.example` to `.env` and add your key:

```bash
cp .env.example .env
```

Then edit `.env`:
```
GROQ_API_KEY=gsk_your_actual_key_here
```

### 4. Verify your Setup

Run the test script to make sure everything works:

```bash
uv run python test_mcp_connection.py
```

This checks:
- MCP server connectivity (requires Rhino/Grasshopper running - Open the examples/task_template.gh file and make sure the MCP server component is toggled on/enabled)
- Required tools are available
- Your Groq API key is valid


---

## During the Lesson

### 1. Get the Tutorial Notebook

Pull the latest changes to get the student notebook:

```bash
git pull
```

### 2. Open Grasshopper

1. Open **Rhino 8**
2. Open **Grasshopper**
3. Open `examples/task_template.gh`
4. Verify the MCP server is running (check Grasshopper menu)

### 3. Launch Jupyter

**Option A: VS Code / Cursor / Windsurf**
1. Open `notebooks/react_agent_student.ipynb`
2. Select the `.venv` Python kernel
3. Run cells with `Shift+Enter`

**Option B: Browser**
```bash
uv run jupyter notebook notebooks/react_agent_student.ipynb
```

---

## Manual Installation

If you prefer step-by-step setup instead of the automated script:

### 1. Install the Grasshopper MCP Plugin

1. Open File Explorer and navigate to this repository's `Libraries` folder
2. Copy the entire `ABxM.Agentic.MCP` folder
3. Paste it into your Grasshopper Libraries folder:
   ```
   C:\Users\<YOUR_USERNAME>\AppData\Roaming\Grasshopper\Libraries
   ```
4. Restart Rhino/Grasshopper if it's already running

### 2. Install uv (if not already installed)

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

After installation, restart your terminal.

### 3. Install dependencies

```bash
uv sync
```

---

## Grasshopper Template

The `examples/task_template.gh` file contains a pre-configured Python 3 Script component.

### What's Included
- One Python 3 Script component named "Task"
- Output variable `a` for geometry display
- The MCP server detects this component automatically

### Troubleshooting

**"No Python script components found"**
- Make sure Grasshopper is open with the template file
- Check that the MCP server is running

**"Connection refused"**
- The MCP server runs on port **8089**: `http://127.0.0.1:8089/mcp`
- Verify the server is running in Grasshopper's MCP settings

---

## MCP Configuration for IDEs

The `.vscode/mcp.json` and `.cursor/mcp.json` files are included for IDE integration.

### Using with VS Code / Cursor

1. Open this folder in your IDE
2. The MCP config is auto-detected
3. Your IDE can now use Grasshopper tools directly

### Using with Other IDEs

Copy the configuration to your IDE's MCP config location:

| IDE | Config Location |
|-----|-----------------|
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

**Cursor / Claude Desktop** (uses `mcpServers`):
```json
{
  "mcpServers": {
    "grasshopper": {
      "url": "http://127.0.0.1:8089/mcp"
    }
  }
}
```

### Verify MCP Connection

```bash
curl -X POST "http://127.0.0.1:8089/mcp" -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/list\",\"params\":{}}"
```
