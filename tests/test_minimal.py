from pytest import fixture, raises
from time import time
from ethereum.tester import TransactionFailed

@fixture()
def now(web3):
    return web3.eth.getBlock("latest").timestamp

def deployContract(chain, value=120, payee=None, rate=1, commences=None):
    if payee is None:
        payee = chain.web3.eth.accounts[1]
    if commences is None:
        commences = now(chain.web3)+60
    return chain.provider.deploy_contract(
        'MinimalAllowance',
        {"value":value},
        (payee, rate, commences))

@fixture()
def contract(chain):
    return deployContract(chain)[0]

def next_block(chain):
    return chain.wait.for_block(
        chain.web3.eth.getBlock("latest").number+1)

def test_burn(chain, contract):
    assert chain.web3.eth.getBalance(contract.address) > 0
    chain.wait.for_receipt(contract.transact().burn())
    assert chain.web3.eth.getBalance(contract.address) == 0

def test_burn_owed(chain, now):
    value=123
    contract = deployContract(chain, value=value, commences=now-1000)[0]
    payee = contract.call().payee()
    balance = chain.web3.eth.getBalance(payee)
    chain.wait.for_receipt(contract.transact().burn())
    assert chain.web3.eth.getBalance(payee) == balance + value

def test_burn_unauthorized(chain, contract):
    balance = chain.web3.eth.getBalance(contract.address)
    with raises(TransactionFailed):
        chain.wait.for_receipt(
            contract.transact({"from":chain.web3.eth.accounts[1]}).burn())
    assert chain.web3.eth.getBalance(contract.address) == balance

def test_payPayee_early(chain, now):
    contract = deployContract(chain, commences=now+1000)[0]
    balance = chain.web3.eth.getBalance(contract.address)
    assert contract.call().commences() > now
    chain.wait.for_receipt(contract.transact().payPayee())
    assert chain.web3.eth.getBalance(contract.address) == balance

def test_payPayee_complete(chain, now):
    contract = deployContract(chain, commences=now-1000)[0]
    completes = contract.call().commences() + \
                (chain.web3.eth.getBalance(contract.address)
                 / contract.call().rate())
    while globals()['now'](chain.web3) < completes:
        next_block(chain)
    assert chain.web3.eth.getBalance(contract.address) > 0
    chain.wait.for_receipt(contract.transact().payPayee())
    assert chain.web3.eth.getBalance(contract.address) == 0
