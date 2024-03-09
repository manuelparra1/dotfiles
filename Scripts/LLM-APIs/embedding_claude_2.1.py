import numpy as np
import voyageai

# Initialize the Voyage AI client
vo = voyageai.Client(api_key="YOUR_API_KEY")

# Read the text of the book from a file
with open("book.txt", "r", encoding="utf-8") as file:
    book_text = file.read()

# Split the book text into chunks to fit within the transaction limit
chunk_size = 128  # Adjust as needed based on the transaction limit
book_chunks = [
    book_text[i : i + chunk_size] for i in range(0, len(book_text), chunk_size)
]

# Embed each chunk of the book
corpus_embeddings = []
for chunk in book_chunks:
    result = vo.embed([chunk], model="voyage-2", input_type="document")
    corpus_embeddings.extend(result.embeddings)

# Now you have the embeddings for the entire book as a corpus

# Example of embedding a user query and finding the most relevant document in the corpus
user_query = "Can you summarize the book?"
query_embedding = vo.embed(
    [user_query], model="voyage-2", input_type="query"
).embeddings[0]

# Compute similarity between the query and each document in the corpus
similarities = [
    np.dot(query_embedding, doc_embedding) for doc_embedding in corpus_embeddings
]

# Find the index of the most similar document
most_similar_index = np.argmax(similarities)

# Retrieve the corresponding chunk of text from the book
most_similar_text = book_chunks[most_similar_index]

print("Most relevant part of the book to the query:")
print(most_similar_text)
