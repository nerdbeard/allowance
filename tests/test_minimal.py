from pytest import fixture, raises
from time import time
from ethereum.tester import TransactionFailed

@fixture()
def now(web3):
    return web3.eth.getBlock("latest").timestamp

@fixture()
def contract(chain, now):
    return chain.provider.deploy_contract(
        'MinimalAllowance',
        {"value":3},
        (chain.web3.eth.accounts[1], # payee
         1,                          # rate
         now+15)                     # commences
    )[0]

def next_block(chain):
    return chain.wait.for_block(
        chain.web3.eth.getBlock("latest").number+1)

def test_burn(chain, contract):
    print chain.web3.eth.getBlock("latest").timestamp
    print contract.call().commences()
    assert chain.web3.eth.getBalance(contract.address) > 0
    chain.wait.for_receipt(contract.transact().burn())
    assert chain.web3.eth.getBalance(contract.address) == 0

def test_burn_unauthorized(chain, contract):
    balance = chain.web3.eth.getBalance(contract.address)
    with raises(TransactionFailed):
        chain.wait.for_receipt(
            contract.transact({"from":chain.web3.eth.accounts[1]}).burn())
    assert chain.web3.eth.getBalance(contract.address) == balance

def test_payPayee_early(chain, contract, now):
    print chain.web3.eth.getBlock("latest").timestamp
    print contract.call().commences()
    balance = chain.web3.eth.getBalance(contract.address)
    assert contract.call().commences() > now
    with raises(TransactionFailed):
        chain.wait.for_receipt(contract.transact().payPayee())
    assert chain.web3.eth.getBalance(contract.address) == balance

def test_payPayee_complete(chain, contract):
    completes = contract.call().commences() + \
                (chain.web3.eth.getBalance(contract.address)
                 / contract.call().rate())
    while now(chain.web3) < completes:
        next_block(chain)
    assert chain.web3.eth.getBalance(contract.address) > 0
    chain.wait.for_receipt(contract.transact().payPayee())
    assert chain.web3.eth.getBalance(contract.address) == 0
