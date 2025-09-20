return {
	"melbaldove/llm.nvim",
	dependencies = { "nvim-neotest/nvim-nio", "nvim-lua/plenary.nvim" },
	config = function()
		local llm = require("llm")
		local Job = require("plenary.job")
		local vim = vim

		-- =============================================================================
		-- LLM Service Configuration
		-- =============================================================================
		local service_lookup = {
			cerebras = {
				url = "https://api.cerebras.ai/v1/chat/completions",
				model = "gpt-oss-120b",
				api_key_name = "CEREBRAS_API_KEY",
			},
			groq = {
				url = "https://api.groq.com/openai/v1/chat/completions",
				model = "qwen/qwen3-32b",
				api_key_name = "GROQ_API_KEY",
			},
			oss = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "openai/gpt-oss-120b",
				api_key_name = "OPENROUTER_API_KEY",
			},
			gpt_5 = {
				url = "https://api.openai.com/v1/chat/completions",
				-- model = "gpt-5-mini",
				model = "gpt-5-nano",
				api_key_name = "OPENAI_API_KEY",
			},
			openai = {
				url = "https://api.openai.com/v1/chat/completions",
				model = "gpt-4.1",
				api_key_name = "OPENAI_API_KEY",
			},
			sonoma_dusk = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "openrouter/sonoma-dusk-alpha",
				api_key_name = "OPENROUTER_API_KEY",
			},
			kimi_k2 = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "moonshotai/kimi-k2-0905",
				api_key_name = "OPENROUTER_API_KEY",
			},
			openrouter = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "openrouter/sonoma-sky-alpha",
				api_key_name = "OPENROUTER_API_KEY",
			},
			tiny_qwen3 = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "qwen/qwen3-4b:free",
				api_key_name = "OPENROUTER_API_KEY",
			},
			qwen3 = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "qwen/qwen3-30b-a3b-thinking-2507",
				api_key_name = "OPENROUTER_API_KEY",
			},
			z_ai = {
				url = "https://api.z.ai/api/paas/v4/chat/completions",
				model = "glm-4.5-flash",
				api_key_name = "Z_API_KEY",
			},
			r1 = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "deepseek/deepseek-r1-0528-qwen3-8b",
				api_key_name = "OPENROUTER_API_KEY",
			},
			r1_t2 = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "tngtech/deepseek-r1t2-chimera:free",
				api_key_name = "OPENROUTER_API_KEY",
			},
			tiny_llama = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "meta-llama/llama-3.2-1b-instruct",
				-- model = "meta-llama/llama-3.2-3b-instruct",
				api_key_name = "OPENROUTER_API_KEY",
			},
			perplexity = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "perplexity/sonar-pro",
				api_key_name = "OPENROUTER_API_KEY",
			},
			grok = {
				url = "https://api.x.ai/v1/chat/completions",
				model = "grok-4-latest",
				api_key_name = "GROK_API_KEY",
			},
			lambda = {
				url = "https://api.lambdalabs.com/v1/chat/completions",
				model = "llama-4-maverick-17b-128e-instruct-fp8",
				api_key_name = "LAMBDA_API_KEY",
				headers = {
					["Content-Type"] = "application/json",
					["Accept"] = "text/event-stream",
				},
			},
			deepcoder = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "agentica-org/deepcoder-14b-preview:free",
				api_key_name = "OPENROUTER_API_KEY",
			},
			flash = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "google/gemini-2.5-flash",
				api_key_name = "OPENROUTER_API_KEY",
			},
			gemini = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "google/gemini-2.5-pro",
				api_key_name = "OPENROUTER_API_KEY",
			},
			gemma = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "google/gemma-3-12b-it",
				api_key_name = "OPENROUTER_API_KEY",
			},
			mistral = {
				url = "https://api.mistral.ai/v1/chat/completions",
				model = "mistral-small-latest",
				api_key_name = "MISTRAL_API_KEY",
			},
			ministral = {
				url = "https://api.mistral.ai/v1/chat/completions",
				model = "ministral-3b-latest",
				api_key_name = "MISTRAL_API_KEY",
			},
			devstral = {
				url = "https://api.mistral.ai/v1/chat/completions",
				model = "devstral-small-latest",
				api_key_name = "MISTRAL_API_KEY",
			},
			codestral = {
				url = "https://codestral.mistral.ai/v1/chat/completions",
				model = "codestral-latest",
				api_key_name = "CODESTRAL_API_KEY",
			},
			nemostral = {
				url = "https://api.mistral.ai/v1/chat/completions",
				model = "open-mistral-nemo",
				api_key_name = "MISTRAL_API_KEY",
			},
			nemotron_ultra = {
				url = "https://openrouter.ai/api/v1/chat/completions",
				model = "nvidia/llama-3.1-nemotron-ultra-253b-v1:free",
				api_key_name = "OPENROUTER_API_KEY",
			},
			nemotron = {
				url = "https://api.lambdalabs.com/v1/chat/completions",
				model = "llama3.1-nemotron-70b-instruct",
				api_key_name = "LAMBDA_API_KEY",
				headers = {
					["Content-Type"] = "application/json",
					["Accept"] = "text/event-stream",
				},
			},
			deepseek = {
				url = "https://api.deepseek.com/v1/chat/completions",
				model = "deepseek-chat",
				api_key_name = "DEEPSEEK_API_KEY",
			},
			ollama_code = {
				url = "http://10.0.0.103:11434/v1/chat/completions",
				model = "qwen2.5-coder:14b",
				api_key_name = "OLLAMA_API_KEY",
			},
			ollama_notes = {
				url = "http://127.0.0.1:11434/v1/chat/completions",
				model = "qwen3:0.6b",
				api_key_name = "OLLAMA_API_KEY",
			},
		}

		-- =============================================================================
		-- Prompt Variables
		-- =============================================================================
		local system_prompt = [[
You are an AI programming assistant integrated into a code editor. Your purpose is to help the user with programming tasks as they write code.
Key capabilities:
- Thoroughly analyze the user's code and provide insightful suggestions for improvements related to best practices, performance, readability, and maintainability. Explain your reasoning.
- Answer coding questions in detail, using examples from the user's own code when relevant. Break down complex topics step-by-step.
- Spot potential bugs and logical errors. Alert the user and suggest fixes.
- Upon request, add helpful comments explaining complex or unclear code.
- Suggest relevant documentation, StackOverflow answers, and other resources related to the user's code and questions.
- Engage in back-and-forth conversations to understand the user's intent and provide the most helpful information.
- Keep responses concise and use markdown formatting where appropriate.
- When asked to create code, only generate the code without any explanations.
- Think step by step.
]]

		local system_prompt_replace = [[
Follow the instructions in the code comments annotated with `--`. Generate code only. Think step by step.
If you must speak, do so in comments annotated with `--`. Generate valid code only.
]]

		local youtube_transcript_cleaner_prompt = [[
Can you convert this Youtube video transcript into a readable form. Do this by splitting
into proper sentences and paragraphs using punctuation, capitalization, and new lines.
Do not rewrite this just add structure, so that it is easy to follow and flows well by
adding the punctuation, new lines, and paragraph splits.
]]

		local youtube_clean_transcript_summary_generator_prompt = [[
What was this video about? Can you distill the information in the video, maintaining the
original context and tone, while preserving all relevant details and including all
relevant information? Please keep all anecdotes, opinions, main ideas, points, and named
entities, and provide a brief summary of the video's main argument or narrative? Remove
mentions of sponsors, adds, and things like that. Please use structure that makes it easy
to digest with readability, and sections for explanations in simple language. Use best
practice markdown syntax. Can you add a "TLDR" section that summarizes this video in a
narrative form? Can you add additional details that you know from your training but
aren't mentioned and are important?
]]

		local note_system_prompt = [[
You are an AI assistant helping with note editing and formatting.
Use the selected text as context.
Follow the last instruction (last line with `>`) which is comments
annotated with `>`.
Perform the requested task precisely and concisely.
Generate valid content only.
- Focus on providing exactly what the user asks for, nothing more.
- Do not include explanations, introductions, or additional content
unless explicitly requested.
- Do not include prefixes like `//` or comments in your response.
- Keep responses brief and directly address the user's instruction.
]]

		local perplexity_system_prompt = [[
You are an AI assistant helping with note editing and formatting.
Use the selected text as context.
Follow the last instruction (last line with `>`) which is comments
annotated with `>`.

Perform the requested task precisely and concisely.
Generate valid content only.

- Focus on providing exactly what the user asks for, nothing more.
- Do not include explanations, introductions, or additional content
unless explicitly requested.
- Do not include prefixes like `//` or comments in your response.
- Keep responses brief and directly address the user's instruction.

Act as a knowledgeable AI assistant that integrates web search results using Perplexity.
Respond to user queries as if you were a knowledgeable expert in the field, always
providing sources for your claims. Conduct real-time web searches to gather relevant
information and then aggregate the results into concise, structured, and informative
answers that address the main points of the question. Engage in active listening,
utilize chain-of-thought prompting, and provide inline citations and context for further
exploration. Utilize fine-tuning and multiple examples to refine the results. Additionally,
include a section of the relevant web sources cited at the end of each response,
providing users with a list of credible sources for further reading. Finally,
provide a section of related questions that users might have, along with brief answers
to these questions, to facilitate deeper understanding and exploration of the topic.
]]

		local code_system_prompt = [[

You are a code generation AI. Output only raw, executable code.
Rules:
1. NEVER use markdown formatting or backticks
2. NEVER wrap code in ``````
3. Output ONLY the exact code requested
4. Use the specified comment syntax for any necessary comments
5. Match the style of surrounding code
6. No explanations or text outside of code comments
7. No markdown, no formatting, just raw code
]]

		local title_spiel_prompt = [[
You are provided with markdown content. Instead of regenerating
the entire document, check if any of the following are missing
and output only those missing elements as separate markdown lines:
1. **Title:** If there is no main title (a line starting with
`#`), generate a concise title (under 5 words) that captures
the main idea.
2. **Subtitle:** If there is no subtitle (a blockquote line
starting with `>`) immediately after the title, generate a
brief subtitle (under 8 words).
3. **Spiel:** If there is no introductory spiel following the
subtitle, generate a one-sentence spiel. The spiel must be conversational
yet technical, with a professional tone suitable for an interview.
It should describe the main topic ({{TOPIC}}) along with its key
features and purpose—as if answering questions like
"what do you know about {{TOPIC}}", "what is {{TOPIC}}", or
"what have you worked with in relation to {{TOPIC}}".
Output only the missing elements without reproducing the rest of the content.
**Important** output the raw markdown. Do not encase in code blocks.
]]

		local course_generator_prompt = [[
Can you generate a written version of this video course in the style of a
textbook using this video transcript. Please keep explanations, analogies,
metaphors, quizzes, etc, but tailor them to be readable in the textbook
style and written form with one difference which is a more natural, informal
style. For example organizing texts to be easily digestible and referenced
but include narrative style paragraphs as well.
]]

		local clean_markdown_prompt = [[
1. **Remove Bold Sections:**
Convert any bold title that are in lists that could be converted
to standard practice markdown syntax sub-headings
(e.g., `##`, `###`, etc)
2. **Concise Title:**
If there is no main (`#`) title create one that is to the point
(so as close to under 5 words as possible) and captures main idea
of the notes. Any missing context will be covered by the main
subtitle.
3. **The Main Subtitle:**
if missing a main subtitle inside a blockquote (`>`) below the
main title (inside a main heading `#`) create a short descriptive
subtitle ( under 8 words) and place in markdown syntax blockquote
`>` below the main title and above the "spiel".
4. **Spiel:**
after the main subtitle (which is inside a blockquote `>`) create a
new paragraph which will be the spiel using this structure:
- gather main topic from the notes
{1 sentence (if possible) conversational, yet technical, for an
interview, professional tone spiel of {{TOPIC}} and it's key features
and purpose for them. (as if asked "what do you know about {{TOPIC}}",
"What you worked with {{TOPIC}} or "what is {{TOPIC}}" then it would be
possible to respond with this spiel as an answer to a probing question
into my experience and job history}
5. **Original Content:**
use original content provided but do not reword or summarize. If
necessary restructure the content to improve readability with
sub-headings and necessary organization typical of markdown syntax
best practice.
6. **Improve Markdown Structure:**
- Ensure that the main title is a top-level header using `#`
- Use subheading levels (e.g., `##`, `###`) appropriately to
structure the main body content.
- If necessary convert large lists and bullet points with long senteces
into subsections with their own subheading to improve readability
- If there are multiple nested lists use standard practice markdown
to organize into appriate sub-headings for readability
7. **Preserve Content Integrity:**
Do not summarize, but do keep all text, descriptions, and lists,
and format them using best-practice markdown (e.g., use block
quotes for descriptive text when the language suggests it is
giving a tip, quoting, or noting,etc).
The main goal is to improve readability, create easy fast, and digestability,
but not reword or remove content.
]]
		local clean_scraped_markdown_prompt = [[
You are provided with a markdown document generated from an HTML scraper.
Transform the document as follows:
1. **Remove Useless Navigation:**
- Delete any navigation content (e.g. table of contents, numbered lists, or
links like "[Home](/)", "[PAN-OS](/content/techdocs/...)") that does not
belong to the main content.
2. **Process Image References:**
Remove all full image paths. For every image reference, extract only the base
image file name and replace its path with a local destination (`./images/`).
*Example:*
`![Filter icon](/content/dam/techdocs/en_US/images/icons/css/filter.svg)`
should become:
`![](./images/filter.svg)`
*Example 2:*
`[![](./images/track_lab1.png "Track_Lab")](https://linkstate.wordpress.com/wp-content/uploads/2011/07/track_lab1.png)`
should become:
`![track_lab1.png](./images/track_lab1.png)`
3. **Improve Markdown Structure:**
- Ensure that the main title is a top-level header using `#`
- Use nested header levels (e.g., `##`, `###`) appropriately to structure the
content.
4. **Preserve Content Integrity:**
- Do not summarize, but do keep all text, descriptions, and lists, and format
them using best-practice markdown (e.g., use block quotes for descriptive
text when the language suggests it is giving a tip, quoting, or noting,etc).
5. **Extra Clean-Up:**
- Remove author information, article date, about the author footer info.
5a. **remove hardcoded new lines:**
- if paragraphs are cut off with new lines to wrap text please join into one line instead.
**Important:** Do not remove or modify the final line that starts with `> Source:`.
Ensure that this source attribution remains exactly as is at the bottom of the
transformed markdown.
]]

		-- =============================================================================
		-- Custom Plugin Code Injection Setup
		-- =============================================================================
		local function get_comment_syntax()
			local ft = vim.bo.filetype
			local comment_markers = {
				lua = "--",
				python = "#",
				cisco = "!",
				javascript = "//",
				typescript = "//",
				java = "//",
				cpp = "//",
				c = "//",
				rust = "//",
				go = "//",
			}
			return comment_markers[ft] or "#"
		end

		llm.setup({
			system_prompt = system_prompt,
			system_prompt_replace = system_prompt_replace,
			services = service_lookup,
		})

		local function write_string_at_cursor(str)
			local win = vim.api.nvim_get_current_win()
			local buf = vim.api.nvim_win_get_buf(win)
			local pos = vim.api.nvim_win_get_cursor(win)
			local start_row, start_col = pos[1], pos[2]
			local lines = vim.split(str, "\n")
			vim.api.nvim_buf_set_text(buf, start_row - 1, start_col, start_row - 1, start_col, lines)

			-- Manually calculate the new cursor position after insertion
			local num_lines = #lines
			local end_row, end_col
			if num_lines == 1 then
				-- No newlines, just moved column on the same line
				end_row = start_row
				end_col = start_col + #lines[1]
			else
				-- Newlines were added, cursor moves to a new line
				end_row = start_row + num_lines - 1
				-- The new column is the length of the last new line of inserted text
				end_col = #lines[num_lines]
			end
			vim.api.nvim_win_set_cursor(win, { end_row, end_col })
		end

		local function process_data_lines(line, service, process_data)
			local json = line:match("^data: (.+)$")
			if json then
				if json == "[DONE]" then
					return true
				end
				local data = vim.json.decode(json)
				vim.schedule(function()
					vim.cmd("undojoin")
					process_data(data)
				end)
			end
			return false
		end

		local function process_sse_response(buffer, service, state)
			for line in string.gmatch(buffer, "[^\r\n]+") do
				process_data_lines(line, service, function(data)
					-- inside process_sse_response(buffer, service, state)
					local content
					if data.choices and data.choices[1] and data.choices[1].delta then
						content = data.choices[1].delta.content
					end

					if content and content ~= vim.NIL then
						if state and not state.first_chunk_received then
							state.first_chunk_received = true
							local content_lines = vim.split(content, "\n", { plain = true })
							-- Replace "Thinking..." with the first line
							vim.api.nvim_buf_set_lines(0, state.line - 1, state.line, false, { content_lines[1] })
							-- Insert any additional lines
							if #content_lines > 1 then
								for i = 2, #content_lines do
									vim.api.nvim_buf_set_lines(
										0,
										state.line + i - 2,
										state.line + i - 2,
										false,
										{ content_lines[i] }
									)
								end
								state.line = state.line + #content_lines - 1
								state.current_content = content_lines[#content_lines]
							else
								state.current_content = content_lines[1]
							end
							vim.api.nvim_win_set_cursor(0, { state.line, #state.current_content })
						else
							-- Append to the current tail, then split
							local combined = (state.current_content or "") .. content
							local content_lines = vim.split(combined, "\n", { plain = true })
							vim.api.nvim_buf_set_lines(0, state.line - 1, state.line, false, { content_lines[1] })
							if #content_lines > 1 then
								for i = 2, #content_lines do
									vim.api.nvim_buf_set_lines(
										0,
										state.line + i - 2,
										state.line + i - 2,
										false,
										{ content_lines[i] }
									)
								end
								state.line = state.line + #content_lines - 1
								state.current_content = content_lines[#content_lines]
							else
								state.current_content = content_lines[1]
							end
							vim.api.nvim_win_set_cursor(0, { state.line, #state.current_content })
						end
					end
				end)
			end
		end

		local function simulate_streaming_write(content, line_num)
			vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { "" })
			vim.api.nvim_win_set_cursor(0, { line_num, 0 })
			local words = vim.split(content, " ")
			local current_text = ""
			local delay = 30
			for i, word in ipairs(words) do
				vim.defer_fn(function()
					current_text = (i == 1) and word or (current_text .. " " .. word)
					vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { current_text })
					vim.api.nvim_win_set_cursor(0, { line_num, #current_text })
				end, delay * (i - 1))
			end
		end

		function llm.prompt_selection_only(opts)
			local replace = opts.replace
			local service = opts.service
			-- === RELIABLE VISUAL SELECTION CAPTURE ===
			local visual_lines = {}
			local mode = vim.api.nvim_get_mode().mode
			local selection_end_row

			if mode == "v" or mode == "V" or mode == "\22" then
				local start_pos = vim.fn.getpos("v")
				local end_pos = vim.fn.getpos(".")
				if start_pos[2] == 0 or end_pos[2] == 0 then
					print("No selection found")
					return
				end
				-- Ensure correct order (start should be before end)
				if start_pos[2] > end_pos[2] or (start_pos[2] == end_pos[2] and start_pos[3] > end_pos[3]) then
					start_pos, end_pos = end_pos, start_pos -- swap
				end
				-- Store the actual end row of selection for proper positioning
				selection_end_row = end_pos[2]

				if mode == "V" then
					-- Visual line mode - get full lines
					for lnum = start_pos[2], end_pos[2] do
						table.insert(visual_lines, vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1])
					end
				else
					-- Visual character mode - handle partial lines
					if start_pos[2] == end_pos[2] then
						-- Single line selection
						local line = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, start_pos[2], false)[1]
						table.insert(visual_lines, string.sub(line, start_pos[3], end_pos[3]))
					else
						-- Multi-line selection
						for lnum = start_pos[2], end_pos[2] do
							local line = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1]
							if lnum == start_pos[2] then
								table.insert(visual_lines, string.sub(line, start_pos[3]))
							elseif lnum == end_pos[2] then
								table.insert(visual_lines, string.sub(line, 1, end_pos[3]))
							else
								table.insert(visual_lines, line)
							end
						end
					end
				end
			else
				local start_pos = vim.fn.getpos("'<")
				local end_pos = vim.fn.getpos("'>")
				if start_pos[2] == 0 or end_pos[2] == 0 then
					print("No selection found")
					return
				end
				selection_end_row = end_pos[2]
				local success, result = pcall(
					vim.api.nvim_buf_get_text,
					0,
					start_pos[2] - 1,
					start_pos[3] - 1,
					end_pos[2] - 1,
					end_pos[3],
					{}
				)
				if success then
					visual_lines = result
				end
			end

			if not visual_lines or #visual_lines == 0 then
				print("No selection found")
				return
			end

			local prompt_text = table.concat(visual_lines, "\n")
			local comment_syntax = opts.comment_syntax or ">"
			local instructions = opts.system_prompt or note_system_prompt
			local thinking_mode = opts.thinking_mode or "off"

			local found_service = service_lookup[service]
			if not found_service then
				print("Invalid service: " .. service)
				return
			end

			local sse_state = {
				first_chunk_received = false,
				current_content = "",
				current_col = 0,
			}

			if replace then
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("cThinking...", true, true, true), "v", false)
				sse_state.line = vim.api.nvim_win_get_cursor(0)[1]
			else
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", false, true, true), "nx", false)
				vim.defer_fn(function()
					vim.api.nvim_buf_set_lines(0, selection_end_row, selection_end_row, false, { "", "Thinking..." })
					sse_state.line = selection_end_row + 2
					vim.api.nvim_win_set_cursor(0, { sse_state.line, 0 })
				end, 50)
			end

			local url = found_service.url
			local api_key_name = found_service.api_key_name
			local model = found_service.model
			local api_key = api_key_name and os.getenv(api_key_name)
			local data = {}

			-- Special handling for GPT-5 (streaming)
			if service == "gpt_5" then
				data = {
					model = model,
					stream = true,
					response_format = { type = "text" },
					verbosity = opts.verbosity or "medium",
					reasoning_effort = opts.reasoning_effort or "medium",
					messages = {
						{ role = "developer", content = { { type = "text", text = instructions } } },
						{ role = "user", content = { { type = "text", text = prompt_text } } },
					},
				}
			else
				-- Standard format for other services
				data = {
					model = model,
					stream = true,
					max_tokens = opts.max_tokens or 8000,
					temperature = opts.temperature or 0.3,
					messages = {
						{ role = "system", content = instructions },
						{ role = "user", content = prompt_text },
					},
				}

				if service == "nemotron_ultra" then
					local system_content = string.format("detailed thinking %s", thinking_mode)
					local final_user_prompt = instructions .. "\n\n---\n\n" .. prompt_text
					data.messages = {
						{ role = "system", content = system_content },
						{ role = "user", content = final_user_prompt },
					}
					if thinking_mode == "on" then
						data.temperature = opts.temperature or 0.6
						data.top_p = opts.top_p or 0.95
					else
						data.temperature = 0.0
						data.top_p = nil
					end
				end

				if instructions == code_system_prompt then
					prompt_text = string.format("Using %s for comments, respond to: %s", comment_syntax, prompt_text)
					data.messages[2].content = prompt_text
				end
			end

			local args = {
				"-N",
				"-X",
				"POST",
				"-H",
				"Content-Type: application/json",
				"-d",
				vim.json.encode(data),
			}

			if api_key then
				if found_service.headers then
					for k, v in pairs(found_service.headers) do
						table.insert(args, "-H")
						table.insert(args, k .. ": " .. v)
					end
				end
				table.insert(args, "-H")
				table.insert(args, "Authorization: Bearer " .. api_key)
			end

			table.insert(args, url)

			local current_active_job = Job:new({
				command = "curl",
				args = args,
				on_stdout = function(_, out)
					-- For GPT-5 streaming and all other streaming services, parse SSE frames
					if out and out ~= "" then
						process_sse_response(out, service, sse_state)
					end
				end,
				on_exit = function()
					vim.schedule(function()
						-- No final write for GPT-5 in streaming mode; chunks were written via SSE.
						-- Handle other services' streaming errors
						if not sse_state.first_chunk_received and service ~= "gpt_5" then
							local line_content =
								vim.api.nvim_buf_get_lines(0, sse_state.line - 1, sse_state.line, false)[1]
							if line_content and line_content:match("^Thinking%.%.%.") then
								vim.api.nvim_buf_set_lines(
									0,
									sse_state.line - 1,
									sse_state.line,
									false,
									{ "Error receiving response." }
								)
							end
						end
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", false, true, true), "nx", false)
					end)
				end,
			})

			current_active_job:start()
		end

		function llm.prompt_selection_only_append(opts)
			opts.replace = false
			llm.prompt_selection_only(opts)
		end
		-- =============================================================================
		-- Keybindings
		-- =============================================================================
		vim.keymap.set("v", "<leader>nt", function()
			llm.prompt_selection_only_append({
				service = "gpt_5",
				system_prompt = note_system_prompt,
				temperature = 0.75,
				verbosity = "medium",
				reasoning_effort = "medium",
			})
		end, { desc = "Append GPT-5 Mini response after selection (notes)" })
		--
		-- Append Gemini Flash response after selection
		--
		vim.keymap.set("v", "<leader>nf", function()
			llm.prompt_selection_only_append({
				service = "flash",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Gemini 2.5 Flash Lite response after selection (notes)" })
		--
		-- Append Qwen response after selection
		--
		vim.keymap.set("v", "<leader>nw", function()
			llm.prompt_selection_only_append({
				service = "qwen3",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Qwen3-4B response after selection (notes)" })
		--
		-- Append Grok response after selection
		--
		vim.keymap.set("v", "<leader>nk", function()
			llm.prompt_selection_only_append({
				service = "grok",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Grok 4 response after selection (notes)" })
		--
		-- Append Gemini Response after selection
		vim.keymap.set("v", "<leader>ng", function()
			llm.prompt_selection_only_append({
				service = "gemini",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Gemini 2.5 Pro response after selection" })
		--
		-- Append Gemma3 response after selection
		--
		vim.keymap.set("v", "<leader>ne", function()
			llm.prompt_selection_only_append({
				service = "gemma",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Gemma3n e2B response after selection (notes)" })
		--
		-- Append Deepseek note response
		--
		vim.keymap.set("v", "<leader>nd", function()
			llm.prompt_selection_only_append({
				service = "r1",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Deepseek R1 (Qwen3 8B) response after selection" })
		--
		-- Append OpenRouter response after selection
		--
		vim.keymap.set("v", "<leader>no", function()
			llm.prompt_selection_only_append({
				service = "openrouter",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append OpenRouter (OSS 20B) response after selection (notes)" })
		--
		-- Append Sonoma Dusk
		--
		vim.keymap.set("v", "<leader>tsd", function()
			llm.prompt_selection_only_append({
				service = "sonoma_dusk",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Sonoma Dusk response after selection (notes)" })
		--
		-- Append Tiny LLM response after selection
		vim.keymap.set("v", "<leader>tqw", function()
			llm.prompt_selection_only_append({
				service = "tiny_qwen3",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Tiny LLM (Qwen3-4B) response after selection (notes)" })
		--
		-- Append Kimi K2 response after selection
		vim.keymap.set("v", "<leader>tkk", function()
			llm.prompt_selection_only_append({
				service = "kimi_k2",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Kimi K2 response after selection (notes)" })
		--
		-- Append AI response after selection
		vim.keymap.set("v", "<leader>tmi", function()
			llm.prompt_selection_only_append({
				service = "ministral",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Ministral 3B response after visual selection" })
		--
		-- Append AI response after selection
		vim.keymap.set("v", "<leader>tnm", function()
			llm.prompt_selection_only_append({
				service = "nemostral",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Mistral Nemo response after visual selection" })
		--
		-- Append AI response after selection
		vim.keymap.set("v", "<leader>tlm", function()
			llm.prompt_selection_only_append({
				service = "tiny_llama",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Llama 3.2 3B response after visual selection" })
		--
		-- Append AI response after selection
		vim.keymap.set("v", "<leader>tdv", function()
			llm.prompt_selection_only_append({
				service = "devstral",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Devstral Small 24B response after visual selection" })
		--
		-- Append AI response after selection
		vim.keymap.set("v", "<leader>tcd", function()
			llm.prompt_selection_only_append({
				service = "codestral",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Codestral 22B response after visual selection" })
		--
		-- Append AI response after selection
		vim.keymap.set("v", "<leader>trt", function()
			llm.prompt_selection_only_append({
				service = "r1_t2",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append R1T2 Chimera response after visual selection" })
		--
		--
		-- Append Mistral response after selection
		vim.keymap.set("v", "<leader>nm", function()
			llm.prompt_selection_only_append({
				service = "mistral",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Mistral Small response after selection (notes)" })
		--
		-- Append Lambda response after selection
		--
		vim.keymap.set("v", "<leader>nl", function()
			llm.prompt_selection_only_append({
				service = "lambda",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Lambda (Llama 4 Scout) response after selection (notes)" })
		--
		-- Append Nemotron response after selection
		--
		vim.keymap.set("v", "<leader>nu", function()
			llm.prompt_selection_only_append({
				service = "nemotron_ultra",
				thinking_mode = "off",
				system_prompt = note_system_prompt,
				temperature = 0,
				-- top_p = 0.95,
				-- temperature = 0.6,
				-- top_p = 0.95,
			})
		end, { desc = "Append Nemotron Ultra response after selection (notes)" })
		--
		-- Append Cerebras response after selection
		--
		vim.keymap.set("v", "<leader>nc", function()
			llm.prompt_selection_only_append({
				service = "cerebras",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Cerebras (OSS 120B) response after selection" })
		--
		-- Append Groq response after selection
		--
		vim.keymap.set("v", "<leader>nq", function()
			llm.prompt_selection_only_append({
				service = "groq",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Groq (Qwen3-32B) response after selection (notes)" })
		--
		vim.keymap.set("v", "<leader>nz", function()
			llm.prompt_selection_only_append({
				service = "z_ai",
				system_prompt = note_system_prompt,
				temperature = 0.75,
			})
		end, { desc = "Append Z AI (GLM 4 Flash) response after selection (notes)" })
		--
		-- Replace selection with LLM response
		--
		vim.keymap.set("v", "<leader>nr", function()
			llm.prompt_selection_only({
				replace = true,
				service = "mistral",
				system_prompt = note_system_prompt,
				temperature = 0.5,
			})
		end, { desc = "Replace selection with LLM response (notes)" })
		--
		-- Append LLM code response after selection
		-- ----------------------------------------
		--
		-- Append selection with LLM code response
		vim.keymap.set("v", "<leader>ct", function()
			llm.prompt_selection_only_append({
				service = "codestral",
				system_prompt = code_system_prompt,
				temperature = 0.1, -- Lower temperature for more deterministic code
				comment_syntax = get_comment_syntax(),
			})
		end, { desc = "Append LLM code response after selection" })
		--
		-- Replace selection with LLM code response
		--
		vim.keymap.set("v", "<leader>cr", function()
			llm.prompt_selection_only({
				replace = true,
				service = "codestral",
				system_prompt = code_system_prompt,
				temperature = 0.1, -- Lower temperature for more deterministic code
				comment_syntax = get_comment_syntax(),
			})
		end, { desc = "Replace selection with LLM code response" })
		-- ========================================================================
		-- S P E C I A L
		-- ========================================================================
		--
		-- Generate a title, subtitle, and spiel
		vim.keymap.set("v", "<leader>mt", function()
			llm.prompt_selection_only_append({
				service = "flash",
				system_prompt = title_spiel_prompt,
				temperature = 0.6,
			})
		end, { desc = "Provide a title, subtitle, and spiel" })
		--
		--
		--
		-- Generate a clean version of youtube video transcript
		vim.keymap.set("v", "<leader>myc", function()
			llm.prompt_selection_only_append({
				service = "grok",
				system_prompt = youtube_transcript_cleaner_prompt,
				temperature = 0.6,
			})
		end, { desc = "Generate a clean version of youtube video transcript" })
		--
		-- Make a summary from Clean YouTube transcript
		vim.keymap.set("v", "<leader>mys", function()
			llm.prompt_selection_only_append({
				service = "r1",
				system_prompt = youtube_clean_transcript_summary_generator_prompt,
				temperature = 0.6,
			})
		end, { desc = "Make a summary from Clean YouTube transcript" })
		--
		-- CLEAN
		-- =====
		--
		-- SCRAPED
		-- ------------------------------------------------------------------------
		--Clean Scraped LLM Markdown with Best Practice Syntax
		vim.keymap.set("v", "<leader>msf", function()
			llm.prompt_selection_only({
				replace = true,
				service = "flash",
				system_prompt = clean_scraped_markdown_prompt,
				temperature = 0.6,
			})
		end, { desc = "Clean Scraped Markdown Content w/ Gemini Flash" })
		--
		--Clean Scraped LLM Markdown with Best Practice Syntax
		vim.keymap.set("v", "<leader>msg", function()
			llm.prompt_selection_only({
				replace = true,
				service = "grok",
				system_prompt = clean_scraped_markdown_prompt,
				temperature = 0.6,
			})
		end, { desc = "Clean Scraped Markdown Content w/ Grok 4" })
		--
		--Clean Scraped LLM Markdown with Best Practice Syntax
		vim.keymap.set("v", "<leader>mso", function()
			llm.prompt_selection_only({
				replace = true,
				service = "openai",
				system_prompt = clean_scraped_markdown_prompt,
				temperature = 0.6,
			})
		end, { desc = "Clean Scraped Markdown Content w/ GPT 5 Mini" })
		--
		-- OUTPUT
		-- ------------------------------------------------------------------------
		--Clean LLM Markdown with Best Practice Syntax
		vim.keymap.set("v", "<leader>mck", function()
			llm.prompt_selection_only({
				replace = true,
				service = "grok",
				system_prompt = clean_markdown_prompt,
				temperature = 0.6,
			})
		end, { desc = "Clean LLM Output Markdown for Readability w/ Grok 4" })
		--
		--Clean LLM Markdown with Best Practice Syntax
		vim.keymap.set("v", "<leader>mco", function()
			llm.prompt_selection_only({
				replace = true,
				service = "openai",
				system_prompt = clean_markdown_prompt,
				temperature = 0.6,
			})
		end, { desc = "Clean LLM Output Markdown for Readability w/ GPT 5 Mini" })
		--
		-- Clean LLM Markdown with Best Practice Syntax
		vim.keymap.set("v", "<leader>mcg", function()
			llm.prompt_selection_only({
				replace = true,
				service = "grok",
				system_prompt = clean_markdown_prompt,
				temperature = 0.6,
			})
		end, { desc = "Clean LLM Output Markdown for Readability w/ Grok 4" })
		--
		-- Clean LLM Markdown with Best Practice Syntax
		vim.keymap.set("v", "<leader>mcf", function()
			llm.prompt_selection_only({
				replace = true,
				service = "flash",
				system_prompt = clean_markdown_prompt,
				temperature = 0.6,
			})
		end, { desc = "Clean LLM Output Markdown for Readability w/ Gemini Flash" })
		--
		-- Convert Video Transcript to Textbook Course (Readable Content)
		vim.keymap.set("v", "<leader>mcc", function()
			llm.prompt_selection_only({
				replace = true,
				service = "flash",
				system_prompt = course_generator_prompt,
				temperature = 0.6,
			})
		end, { desc = "Convert Video Transcript to Textbook Course (Readable Content)" })
		--
		-- Split paragraph into bullet points
		--
		vim.keymap.set("v", "<leader>mbr", function()
			llm.prompt_selection_only({
				replace = true,
				service = "devstral",
				system_prompt = [[
                Can you split the following text into a markdown bullet list
                ]],
				temperature = 0.5,
			})
		end, { desc = "Split paragraph into bullet points" })
		--
		-- Provide a subtitle for Paragraph
		--
		vim.keymap.set("v", "<leader>mgt", function()
			llm.prompt_selection_only_append({
				service = "ministral",
				system_prompt = [[
                    Please provide a easy and quick to read
                    subtitle (as if glancing through a large amount of
                    paragraphs) that captures the main idea and 
                    is eye catching for the following paragraph
                    ]],
				temperature = 0.1,
			})
		end, { desc = "Provide a subtitle for Paragraph" })
		--
	end,
}
