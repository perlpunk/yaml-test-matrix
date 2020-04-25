ALL_VIEWS := \
	cpp-event \
	js-yaml-json \
	java-json \
	java-event \
	libyaml-event \
	nimyaml-event \
	perl5-pegex-event \
	perl5-pm-pl \
	perl5-pm-json \
	perl5-pp-event \
	perl5-syck-pl \
	perl5-syck-json \
	perl5-tiny-pl \
	perl5-tiny-json \
	perl5-xs-pl \
	perl5-xs-json \
	perl6-json \
	perl6-p6 \
	pyyaml-event \
	ruamel-event \
	ruby-json \


#------------------------------------------------------------------------------
build: data matrix
	./bin/expected
	./bin/run-framework-tests --all
	./bin/compare-framework-tests --all
	./bin/create-matrix
	./bin/highlight

$(ALL_VIEWS): data matrix
	time ./bin/run-framework-tests --framework $@
	./bin/create-matrix

matrix:
	mkdir -p $@

yaml-test-suite:
	git clone https://github.com/yaml/yaml-test-suite $@

data:
	git clone https://github.com/yaml/yaml-test-suite -b $@ $@

gh-pages:
	-git branch --track $@ origin/$@
	git worktree add --force $@ gh-pages

update-gh-pages:
	rsync -a --delete --stats matrix/html/* gh-pages/

clean:
	rm -fr data matrix
	git clean -dxf
