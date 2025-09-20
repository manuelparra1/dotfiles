return {
	"CamdenClark/flyboy",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	config = function()
		-- Define your sources
		local sources = {
			current_and_above_no_header = function()
				local line_num = vim.fn.line(".")
				local lines = {}
				if line_num > 1 then
					table.insert(lines, vim.fn.getline(line_num - 1))
				end
				table.insert(lines, vim.fn.getline(line_num))
				return table.concat(lines, " ")
			end,

			entire_buffer = function()
				local buf = vim.api.nvim_get_current_buf()
				local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				return table.concat(lines, "\n")
			end,

			-- New source function to get the visual selection
			visual_selection = function()
				-- Get the positions of the visual selection
				local start_pos = vim.fn.getpos("'<")
				local end_pos = vim.fn.getpos("'>")

				if start_pos[2] == 0 or end_pos[2] == 0 then
					vim.notify("No visual selection found.", vim.log.levels.ERROR)
					return nil
				end

				local start_line = start_pos[2] - 1
				local start_col = start_pos[3] - 1
				local end_line = end_pos[2] - 1
				local end_col = end_pos[3] - 1

				local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
				if #lines == 0 then
					return nil
				end

				-- Adjust the first and last lines based on the selection columns
				if #lines == 1 then
					lines[1] = string.sub(lines[1], start_col + 1, end_col + 1)
				else
					lines[1] = string.sub(lines[1], start_col + 1)
					lines[#lines] = string.sub(lines[#lines], 1, end_col + 1)
				end

				-- Identify the line starting with '>'
				local prompt_line_index = nil
				for idx, line in ipairs(lines) do
					if line:match("^%s*>") then
						prompt_line_index = idx
						break
					end
				end

				if not prompt_line_index then
					vim.notify("No line starting with '>' found in selection.", vim.log.levels.ERROR)
					return nil
				end

				-- Extract the prompt and context
				local prompt_line = lines[prompt_line_index]:gsub("^%s*>%s*", "")
				table.remove(lines, prompt_line_index)
				local context = table.concat(lines, "\n")

				return {
					context = context,
					prompt_line_index = start_line + prompt_line_index, -- Adjust for buffer line numbers
					prompt = prompt_line,
				}
			end,
		}

		-- Define your templates (if needed)
		local templates = {
			direct_completion = {
				template_fn = function(sources)
					-- Return a message table compatible with OpenAI API
					return {
						{
							role = "user",
							content = sources.current_and_above_no_header(),
						},
					}
				end,
			},
		}

		-- Plugin configurations
		require("flyboy").setup({
			sources = sources,
			templates = templates,
			url = "https://api.x.ai/v1/chat/completions", -- Grok API endpoint
			headers = {
				Authorization = "Bearer " .. (vim.env.GROK_API_KEY or ""),
				Content_Type = "application/json",
			},
			model = "grok-beta",
			temperature = 0.7,
		})
		-- require("flyboy").setup({
		-- 	sources = sources,
		-- 	templates = templates,
		-- 	url = "https://api.groq.com/openai/v1/chat/completions", -- Groq API endpoint
		-- 	headers = {
		-- 		Authorization = "Bearer " .. (vim.env.GROQ_API_KEY or ""),
		-- 		Content_Type = "application/json",
		-- 	},
		-- 	model = "llama-3.2-90b-text-preview",
		-- 	temperature = 0.7,
		-- })

		-- Import the necessary modules
		local openai = require("flyboy.openai")
		local config = require("flyboy.config")

		-- Define the send_custom_message function and assign it to the global namespace
		_G.send_custom_message = function()
			-- Get the content from your custom source
			local content = config.options.sources.current_and_above_no_header()
			local messages = {
				{
					role = "user",
					content = content,
				},
			}

			-- Get the current buffer and prepare to insert the assistant's response
			local buffer = vim.api.nvim_get_current_buf()
			local currentLine = vim.fn.line(".") -- Get the current cursor line

			-- Insert placeholder for assistant's response
			vim.api.nvim_buf_set_lines(buffer, currentLine, currentLine, false, { "", "# Assistant", "..." })

			currentLine = currentLine + 2 -- Move to the line with "..."

			local currentLineContents = ""

			local on_delta = vim.schedule_wrap(function(response)
				if
					response
					and response.choices
					and response.choices[1]
					and response.choices[1].delta
					and response.choices[1].delta.content
				then
					local delta = response.choices[1].delta.content
					if delta ~= nil then
						if delta == "\n" then
							-- Write currentLineContents to the buffer
							vim.api.nvim_buf_set_lines(
								buffer,
								currentLine - 1,
								currentLine,
								false,
								{ currentLineContents }
							)
							-- Move to next line
							currentLine = currentLine + 1
							-- Reset currentLineContents
							currentLineContents = ""
						elseif delta:find("\n") then
							-- Split delta by newlines
							local lines = vim.split(delta, "\n", true)
							for idx, line in ipairs(lines) do
								currentLineContents = currentLineContents .. line
								vim.api.nvim_buf_set_lines(
									buffer,
									currentLine - 1,
									currentLine,
									false,
									{ currentLineContents }
								)
								if idx < #lines then
									-- If not the last line, move to next line
									currentLine = currentLine + 1
									currentLineContents = ""
								end
							end
						else
							-- No newlines in delta
							currentLineContents = currentLineContents .. delta
							vim.api.nvim_buf_set_lines(
								buffer,
								currentLine - 1,
								currentLine,
								false,
								{ currentLineContents }
							)
						end
					end
				end
			end)

			local on_complete = function()
				-- Add a new line for further user input
				vim.api.nvim_buf_set_lines(buffer, currentLine, currentLine, false, { "", "# User", "" })
				if config.options.on_complete ~= nil then
					config.options.on_complete()
				end
			end

			-- Send the message using the OpenAI API
			openai.get_chatgpt_completion(config.options, messages, on_delta, on_complete)
		end

		_G.send_entire_buffer_message = function()
			-- Get the content from the entire buffer source
			local content = require("flyboy.config").options.sources.entire_buffer()
			local messages = {
				{
					role = "user",
					content = content,
				},
			}

			-- The rest of the function is similar to send_custom_message
			local openai = require("flyboy.openai")
			local config = require("flyboy.config")

			local buffer = vim.api.nvim_get_current_buf()
			local currentLine = vim.fn.line("$") -- Get the last line of the buffer

			-- Insert placeholder for assistant's response at the end
			vim.api.nvim_buf_set_lines(buffer, currentLine, currentLine, false, { "", "# Assistant", "..." })

			currentLine = currentLine + 2 -- Move to the line with "..."

			local currentLineContents = ""

			-- Use the same on_delta and on_complete functions as before, adjusting currentLine as needed

			local on_delta = vim.schedule_wrap(function(response)
				if
					response
					and response.choices
					and response.choices[1]
					and response.choices[1].delta
					and response.choices[1].delta.content
				then
					local delta = response.choices[1].delta.content
					if delta ~= nil then
						if delta == "\n" then
							vim.api.nvim_buf_set_lines(
								buffer,
								currentLine - 1,
								currentLine,
								false,
								{ currentLineContents }
							)
							currentLine = currentLine + 1
							currentLineContents = ""
						elseif delta:find("\n") then
							local lines = vim.split(delta, "\n", true)
							for idx, line in ipairs(lines) do
								currentLineContents = currentLineContents .. line
								vim.api.nvim_buf_set_lines(
									buffer,
									currentLine - 1,
									currentLine,
									false,
									{ currentLineContents }
								)
								if idx < #lines then
									currentLine = currentLine + 1
									currentLineContents = ""
								end
							end
						else
							currentLineContents = currentLineContents .. delta
							vim.api.nvim_buf_set_lines(
								buffer,
								currentLine - 1,
								currentLine,
								false,
								{ currentLineContents }
							)
						end
					end
				end
			end)

			local on_complete = function()
				vim.api.nvim_buf_set_lines(buffer, currentLine, currentLine, false, { "", "# User", "" })
				if config.options.on_complete ~= nil then
					config.options.on_complete()
				end
			end

			openai.get_chatgpt_completion(config.options, messages, on_delta, on_complete)
		end

		_G.send_visual_selection_message = function()
			-- Get the content from the visual selection source
			local selection = require("flyboy.config").options.sources.visual_selection()
			if not selection then
				return -- No valid selection or prompt, so we do nothing
			end

			local messages = {
				{
					role = "user",
					content = selection.context .. "\n" .. selection.prompt,
				},
			}

			local openai = require("flyboy.openai")
			local config = require("flyboy.config")

			local buffer = vim.api.nvim_get_current_buf()
			local prompt_line_in_buffer = selection.prompt_line_index - 1 -- Adjust index to 0-based

			-- Insert placeholder for assistant's response
			vim.api.nvim_buf_set_lines(buffer, prompt_line_in_buffer, prompt_line_in_buffer + 1, false, { "..." })

			local currentLine = prompt_line_in_buffer
			local currentLineContents = ""

			local on_delta = vim.schedule_wrap(function(response)
				if
					response
					and response.choices
					and response.choices[1]
					and response.choices[1].delta
					and response.choices[1].delta.content
				then
					local delta = response.choices[1].delta.content
					if delta ~= nil then
						if delta == "\n" then
							vim.api.nvim_buf_set_lines(
								buffer,
								currentLine,
								currentLine + 1,
								false,
								{ currentLineContents }
							)
							currentLine = currentLine + 1
							currentLineContents = ""
						elseif delta:find("\n") then
							local lines = vim.split(delta, "\n", true)
							for idx, line in ipairs(lines) do
								currentLineContents = currentLineContents .. line
								vim.api.nvim_buf_set_lines(
									buffer,
									currentLine,
									currentLine + 1,
									false,
									{ currentLineContents }
								)
								if idx < #lines then
									currentLine = currentLine + 1
									currentLineContents = ""
								end
							end
						else
							currentLineContents = currentLineContents .. delta
							vim.api.nvim_buf_set_lines(
								buffer,
								currentLine,
								currentLine + 1,
								false,
								{ currentLineContents }
							)
						end
					end
				end
			end)

			local on_complete = function()
				if config.options.on_complete ~= nil then
					config.options.on_complete()
				end
			end

			openai.get_chatgpt_completion(config.options, messages, on_delta, on_complete)
		end

		-- Keybindings

		-- use current line and one above as prompt
		vim.api.nvim_set_keymap("i", "<C-i>", "<Esc>:lua send_custom_message()<CR>a", { noremap = true, silent = true })
		-- use whole file as prompt
		vim.api.nvim_set_keymap(
			"n",
			"<Leader>cf",
			":lua send_entire_buffer_message()<CR>",
			{ noremap = true, silent = true }
		)
		-- use visual selection as prompt
		vim.api.nvim_set_keymap(
			"v",
			"<Leader>cv",
			"<Cmd>lua send_visual_selection_message()<CR>",
			{ noremap = true, silent = true }
		)
	end,
}
