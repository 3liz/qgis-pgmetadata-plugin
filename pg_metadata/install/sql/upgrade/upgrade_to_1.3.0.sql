BEGIN;

-- Provide translations with fallback for localised admin project

create view pgmetadata.v_glossary_normalised_locale_fallback as
select id, field, item_order, code, items.*
from pgmetadata.glossary g
cross join lateral (
  values
    ('en', g.label_en, g.description_en),
    ('fr', coalesce(g.label_fr, g.label_en), coalesce(g.description_fr, description_en)),
    ('de', coalesce(g.label_de, g.label_en), coalesce(g.description_de, description_en))
) as items(locale, label, description)
order by field, item_order;

comment on view pgmetadata.v_glossary_normalised_locale_fallback is 'View transforming glossary into normalised form (unpivoting locales) with English used as fallback for missing translations';

COMMIT;
