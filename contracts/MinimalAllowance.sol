pragma solidity ^0.4.17;

contract MinimalAllowance {
  // Make members private if possible to make the runtime binary
  // smaller
  address private owner;
  address public payee;
  uint256 public rate;
  uint256 private value; /* The total ether value to be transferred */
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
    var _owing = (now - commences)*rate - value + this.balance;
    if (_owing > this.balance)  /* There is no max(). */
      return this.balance;
    return _owing;
  }
 
  function payPayee() public {
    var _owing = owing();
    if (_owing == this.balance)
      return selfdestruct(payee);
    /* I *think* this method is immune to recursive attacks but needs
       testing. */
    if (_owing > 0)
      payee.transfer(_owing);
  }

  function burn() public onlyOwner {
    payPayee();         /* Pay what is currently owed. */
    selfdestruct(this); /* Burn the residue. */
  }
}
