pragma solidity ^0.4.17;

contract MinimalAllowance {
  // Make members private if possible to make the runtime binary
  // smaller
  address private owner;
  address public payee;
  uint256 public rate;
  uint256 private paid;
  uint256 public commences;

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

  function owing() private view returns (uint256) {
    if (commences >= now)
      return 0;
    var _owing = (now-commences)*rate-paid;
    if (_owing > this.balance)  /* There is no max(). */
      return this.balance;
    return _owing;
  }
 
  function payPayee() public {
    var _owing = owing();
    if (_owing == this.balance)
      return selfdestruct(payee);
    if (_owing > 0) {
      paid += _owing;
      payee.transfer(_owing);
    }
  }

  function burn() public onlyOwner {
    payPayee();         /* Pay what is currently owed. */
    selfdestruct(this); /* Burn the residue. */
  }
}
