.PHONY: requirements

ROOT = $(shell echo "$$PWD")
COVERAGE = $(ROOT)/build/coverage
NODE_BIN=./node_modules/.bin

DJANGO_SETTINGS_MODULE := "analytics_dashboard.settings.local"

.PHONY: requirements clean

requirements: requirements.js
	pip install -q -r requirements/base.txt --exists-action w

requirements.js:
	npm install
	$(NODE_BIN)/bower install

test.requirements: requirements
	pip install -q -r requirements/test.txt --exists-action w

develop: test.requirements
	pip install -q -r requirements/local.txt --exists-action w

test.acceptance: develop
	git clone https://github.com/edx/edx-analytics-data-api.git
	pip install -q -r edx-analytics-data-api/requirements/base.txt

migrate:
	python manage.py migrate

clean:
	find . -name '*.pyc' -delete
	coverage erase

test_python: clean
	python manage.py compress --settings=analytics_dashboard.settings.test
	python manage.py test analytics_dashboard common --settings=analytics_dashboard.settings.test --with-coverage \
	--cover-package=analytics_dashboard --cover-package=common --cover-branches --cover-html --cover-html-dir=$(COVERAGE)/html/ \
	--with-ignore-docstrings --cover-xml --cover-xml-file=$(COVERAGE)/coverage.xml

accept:
	./runTests.sh acceptance_tests

a11y:
	SELENIUM_BROWSER=phantomjs ./runTests.sh a11y_tests

course_validation:
	python -m acceptance_tests.course_validation.generate_report

quality:
	pep8 acceptance_tests analytics_dashboard common
	PYTHONPATH=".:./analytics_dashboard:$PYTHONPATH" pylint --rcfile=pylintrc acceptance_tests analytics_dashboard common

validate_python: test.requirements test_python quality

validate_js: requirements.js
	$(NODE_BIN)/gulp test
	$(NODE_BIN)/gulp lint
	$(NODE_BIN)/gulp jscs

validate: validate_python validate_js

demo:
	python manage.py switch display_verified_enrollment on --create
	python manage.py switch show_engagement_forum_activity off --create
	python manage.py switch enable_course_api off --create
	python manage.py switch display_names_for_course_index off --create
	python manage.py switch display_course_name_in_nav off --create

compile_translations:
	cd analytics_dashboard && i18n_tool generate -v

extract_translations:
	cd analytics_dashboard && i18n_tool extract -v

dummy_translations:
	cd analytics_dashboard && i18n_tool dummy -v

generate_fake_translations: extract_translations dummy_translations compile_translations

pull_translations:
	cd analytics_dashboard && tx pull -a

update_translations: pull_translations generate_fake_translations

static:
	$(NODE_BIN)/r.js -o build.js
	python manage.py collectstatic --noinput
	python manage.py compress
