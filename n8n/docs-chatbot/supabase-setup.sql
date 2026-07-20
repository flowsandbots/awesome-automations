-- docs-chatbot: run this once in your Supabase project (SQL editor, new query, paste, run)
-- Sets up pgvector and the documents table n8n's Supabase Vector Store node expects.
-- Dimension is 3072 to match Google's gemini-embedding-001. If you switch embedding
-- models, change the dimension here AND re-ingest everything.

create extension if not exists vector;

create table if not exists documents (
  id bigserial primary key,
  content text,
  metadata jsonb,
  embedding vector(3072)
);

create or replace function match_documents (
  query_embedding vector(3072),
  match_count int default null,
  filter jsonb default '{}'
) returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    documents.id,
    documents.content,
    documents.metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where documents.metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end;
$$;

-- to wipe and re-ingest later:
-- truncate table documents;

-- permissions: if you created your project with "automatically expose new tables"
-- disabled (the recommended default), the API roles can't touch the table yet.
-- these grants fix the "permission denied for table documents" error in n8n.
grant usage on schema public to service_role;
grant all on table documents to service_role;
grant usage, select on sequence documents_id_seq to service_role;
