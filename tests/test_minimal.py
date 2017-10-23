from pytest import fixture
from time import time

@fixture()
def now(web3):
    return web3.eth.getBlock("latest").timestamp

@fixture()
def contract(provider, web3, now):
    return provider.deploy_contract(
        'MinimalAllowance',
        {"value":web3.toWei(1, "ether")},
        (web3.eth.coinbase,          # payee
         web3.toWei(1/6.0, "ether"), # rate
         now+1)                      # commences
    )[0]

def test_burn(chain, web3, contract):
    assert web3.eth.getBalance(contract.address) > 0
    chain.wait.for_receipt(contract.transact().burn())
    assert web3.eth.getBalance(contract.address) == 0
