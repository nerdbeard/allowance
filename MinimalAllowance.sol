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
    paid = 0;			/* I presume this is unneccesary. */
    commences = _commences;
  }

  function completes() public view returns (uint256) {
    return commences + (paid + this.balance)/rate;
  }

  function owing() public view returns (uint256) {
    return max((now-commences)*rate-paid,
	       this.value);
  }
 
  function payPayee() public afterCommencing {
    var _owing = owing();
    if (_owing == this.value)
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
