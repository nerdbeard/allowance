pragma solidity ^0.4.17;

contract MinimalAllowance {
  address public owner;
  address public payee;
  uint256 public rate;
  uint256 public paid;
  uint256 public commences;

  modifier afterCommencing { require(now >= commences); _; }
  modifier onlyOwner { require(msg.sender == owner); _; }

  function MinimalAllowance(address _payee,
			    uint256 _rate,
			    uint256 _commences)
    public payable
  {
    owner = msg.sender;
    payee = _payee;
    rate = _rate;
    commences = _commences;
  }

  function completes() public view returns (uint256) {
    return commences + (paid + this.balance)/rate;
  }

  function owing() public view returns (uint256) {
    var _owing = (now-commences)*rate-paid;
    if (_owing > this.balance)	/* There is no max(). */
      return this.balance;
    return _owing;
  }
 
  function payPayee() public afterCommencing {
    var _owing = owing();
    if (_owing == this.balance)
      selfdestruct(payee);
    else {
      require(_owing > 0);
      paid += _owing;
      payee.transfer(_owing);
    }
  }

  function burn() public onlyOwner {
    payPayee();			/* Pay what is currently owed. */
    selfdestruct(this);		/* Burn the residue. */
  }
}
