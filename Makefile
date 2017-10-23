GETH	= geth
DEVGETH	= $(GETH) \
		--networkid 1977 \
		--datadir ./testdb \
		--unlock 0 --password testdb/passwd \
		--netrestrict 127.0.0.1/32 \
		--nodiscover

test: clean testdb/geth

testdb/geth: MinimalAllowance.contract.js testdb/genesis.json
	$(DEVGETH) --verbosity 2 init testdb/genesis.json
	$(MAKE) start
	$(DEVGETH) --exec 'miner.start()' attach testdb/geth.ipc
	$(DEVGETH) --exec 'miner.stop()' attach testdb/geth.ipc
	sleep 0.5		# prevents an unauthorized somehow??
	$(DEVGETH) --verbosity 1 \
		--jspath '$(PWD)' \
		--exec 'loadScript("$<")' \
		attach ipc:testdb/geth.ipc
	$(MAKE) stop

%.abi: %.sol
	solc --overwrite -o . --abi $<
%.bin: %.sol
	solc --overwrite -o . --bin $<
%.contract.js: %.abi %.bin
	@sh publish-contract.sh '$(shell cat $*.abi)' '$(shell cat $*.bin)' > $@

clean:
	-[ -f testdb/geth.pid ] && $(MAKE) stop
	rm -rf testdb/geth testdb/geth.* *.abi *.bin *.contract.js

start: testdb/geth.pid

testdb/geth.pid: testdb/geth
	nohup $(DEVGETH) --verbosity 3 >testdb/geth.out 2>&1\
		& echo $$!>testdb/geth.pid
	until [ -S testdb/geth.ipc ] ; do sleep 0.1 ; done

stop:
	-mv testdb/geth.pid testdb/geth.pid.old
	-kill `cat testdb/geth.pid.old`
	-rm testdb/geth.ipc

attach: testdb/geth.ipc
	$(DEVGETH) attach ipc:testdb/geth.ipc
