[
  {
    "bot_id": "bm_insurance_licenses_raw",
    "data_type": "primary_source",
    "unique_fields": ["name"],
    "executable": "scrape.rb",
    "version": "0.1"
  },
  {
    "bot_id": "bm_insurance_licenses",
    "data_type": "licence",
    "executable": "convert_to_financial_licence.rb",
    "unique_fields": ["company.name"],
    "depends": "bm_insurance_licenses_raw"
  }
]
