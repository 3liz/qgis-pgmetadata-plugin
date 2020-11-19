BEGIN;

-- theme theme_pkey
ALTER TABLE ONLY pgmetadata.theme
    ADD CONSTRAINT theme_pkey PRIMARY KEY (id);

COMMIT;
