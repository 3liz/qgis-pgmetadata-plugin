start_tests:
	@echo 'Start docker-compose'
	@cd .docker && ./start.sh with-qgis

run_tests:
	@echo 'Running tests, containers must be running'
	@cd .docker && ./exec.sh

stop_tests:
	@echo 'Stopping/killing containers'
	@cd .docker && ./stop.sh

tests: start_tests run_tests stop_tests flake8

test_migration:
	@echo 'Testing migrations'
	@cd .docker && ./start.sh
	@cd .docker && ./install_migrate_generate.sh
	@cd .docker && ./stop.sh

schemaspy:
	@echo 'Generating schemaspy documentation'
	@cd .docker && ./start.sh
	rm -rf docs/database
	mkdir docs/database
	@cd .docker && ./install_db.sh
	@cd .docker && ./schemaspy.sh
	@cd .docker && ./stop.sh

generate_sql:
	@echo 'Generate SQL into install files'
	cd pg_metadata/install/sql && ./export_database_structure_to_SQL.sh pgmetadata pgmetadata
	git diff -p -R --no-ext-diff --no-color | grep -E "^(diff|(old|new) mode)" --color=never | git apply

reformat_sql:
	@echo 'Reformat SQL'
	@cd .docker && ./start.sh
	@cd .docker && ./install_db.sh
	@cd .docker && ./reformat_sql_install.sh
	@cd .docker && ./stop.sh

flake8:
	@echo 'Running flake8'
	@docker run --rm -w /plugin -v $(shell pwd):/plugin etrimaille/flake8:3.8.2

processing-doc:
	cd .docker && ./processing_doc.sh
