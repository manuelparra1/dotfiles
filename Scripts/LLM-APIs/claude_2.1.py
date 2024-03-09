import anthropic

client = anthropic.Anthropic(
    # defaults to os.environ.get("ANTHROPIC_API_KEY")
    api_key="my_api_key",
)
message = client.messages.create(
    model="claude-2.1",
    max_tokens=1000,
    temperature=0,
    messages=[
        {
            "role": "user",
            "content": 'I have a file named Test_5.md and I want to extract all the information for each question inside after its "**Explanation**\n<br>" section. I want to use regex with python or bash to be able to use on any file structured this way.\n\n# Test 5\n\n## Question 1:\n\n### What is the definition of service management?\n\n- A) A set of specialized organizational capabities for enabling value to customers (Correct)\n- B) The means by which an organization is directed and controlled\n- C) A method for visualizing work, identifying potential blockages and resource conflicts, and managing work in progress\n- D) A means of enabling value co-creation by facilitating outcomes that customers want to achieve, without the customer having to manage specific costs and risks (My Response)\n\n**Explanation**\n<br>\nService management is a set of specialized organizational capabilities for enabling value to customers in the form of services.\n\n## Question 2: ...etc.',
        }
    ],
)
print(message.content)
