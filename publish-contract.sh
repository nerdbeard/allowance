cat << EOF
var abi=$1;
var bin="0x$2";
var contractFactory=eth.contract(abi);
var contract=contractFactory.new(
    eth.accounts[1],
    1,
    $(date +%s),
    {value: 1977,
     from: eth.accounts[0],
     data: bin,
     gas: 10000000});
EOF
