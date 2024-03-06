--©2024, Ovais Quraishi
CREATE DATABASE zollama; 

--Create Tables
CREATE TABLE IF NOT EXISTS author (
        author_id VARCHAR PRIMARY KEY,
        author_name VARCHAR,
        author_created_utc INT
    );

CREATE TABLE IF NOT EXISTS post (
    post_id VARCHAR PRIMARY KEY,
    subreddit VARCHAR,
    post_author VARCHAR,
    post_title TEXT,
    post_body TEXT,
    post_created_utc INT,
    is_post_oc BOOLEAN,
    is_post_video BOOLEAN,
    post_upvote_count INTEGER,
    post_downvote_count INTEGER,
    subreddit_members INTEGER
);

CREATE TABLE IF NOT EXISTS comment (
    comment_id VARCHAR PRIMARY KEY,
    comment_author VARCHAR,
    is_comment_submitter BOOLEAN,
    is_comment_edited TEXT,
    comment_created_utc INT,
    comment_body text,
    post_id VARCHAR,
    subreddit TEXT
);

CREATE TABLE IF NOT EXISTS errors (
    item_id VARCHAR,
    item_type VARCHAR,
    error TEXT
);

CREATE TABLE IF NOT EXISTS subscription (
        datetimesubscribed VARCHAR,
        subreddit VARCHAR
);

CREATE TABLE IF NOT EXISTS analysis_documents (
    id INTEGER PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
	timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    shasum_512 TEXT UNIQUE NOT NULL,
    analysis_document JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_notes (
    id integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
	timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
	patient_note_sha_512 TEXT UNIQUE NOT NULL,
    patient_id TEXT NOT NULL,
    patient_note JSONB NOT NULL
);

CREATE TABLE IF NOT EXISTS patient_documents (
    id integer PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY,
	timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
	patient_analysis_sha_512 TEXT UNIQUE NOT NULL,
    patient_id TEXT NOT NULL,
    patient_note_id TEXT NOT NULL,
    analysis_document JSONB NOT NULL
);


--Create Indexes
--Patient Notes
CREATE INDEX IF NOT EXISTS patient_note_sha_512_index ON patient_notes (patient_note_sha_512);
CREATE INDEX IF NOT EXISTS patient_id_index ON patient_notes (patient_id);
CREATE INDEX IF NOT EXISTS timestamp_index ON patient_notes (timestamp);
CREATE INDEX IF NOT EXISTS patient_note_gin_index ON patient_notes USING gin(patient_note jsonb_path_ops);
--Patient Documents
CREATE INDEX IF NOT EXISTS patient_analysis_sha_512_index ON patient_documents (patient_analysis_sha_512);
CREATE INDEX IF NOT EXISTS patient_id_index ON patient_documents (patient_id);
CREATE INDEX IF NOT EXISTS patient_note_id_index ON patient_documents (patient_note_id);
CREATE INDEX IF NOT EXISTS timestamp_index ON patient_documents (timestamp);
CREATE INDEX IF NOT EXISTS analysis_document_gin_index ON patient_documents USING gin(analysis_document jsonb_path_ops);
--Analysis Documents
CREATE INDEX IF NOT EXISTS timestamp_index ON analysis_documents (timestamp);
CREATE INDEX IF NOT EXISTS shasum_512_index ON analysis_documents (shasum_512);
CREATE INDEX IF NOT EXISTS analysis_document_gin_index ON analysis_documents USING gin(analysis_document jsonb_path_ops);
--Author
CREATE UNIQUE INDEX IF NOT EXISTS author_pkey ON public.author USING btree (author_id);
--Comment
CREATE UNIQUE INDEX IF NOT EXISTS comment_pkey ON public.comment USING btree (comment_id);
CREATE INDEX IF NOT EXISTS comment_post_id_idx ON public.comment USING btree (post_id, subreddit);
--Errors
CREATE INDEX IF NOT EXISTS errors_item_id_idx ON public.errors USING btree (item_id);
--Posts
CREATE UNIQUE INDEX IF NOT EXISTS post_pkey ON public.post USING btree (post_id);
CREATE INDEX IF NOT EXISTS post_post_author_idx ON public.post USING btree (post_author);
CREATE INDEX IF NOT EXISTS post_subreddit_idx ON public.post USING btree (subreddit);
--Subscription
CREATE INDEX IF NOT EXISTS subscription_subreddit_idx ON public."subscription" (subreddit);
