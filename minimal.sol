pragma solidity ^0.4.17;

contract MinimalAllowance {
  address public owner;
  address public benefactor;
  uint256 public rate;
  uint256 public paid;
  uint256 public commences;

  modifier afterCommencing { require(now >= commences); _; }
  modifier onlyOwner { require(msg.sender == owner); _; }

  function MinimalAllowance(address _benefactor,
			    uint256 _rate,
			    uint256 _commences)
    public
  {
    owner = msg.sender;
    benefactor = _benefactor;
    rate = _rate;
    paid = 0;			/* I presume this is unneccesary. */
    commences = _commences;
  }

  function completes() public view returns (uint256) {
    return commences + (paid + this.balance)/rate;
  }

  function payBenefactor() public afterCommencing {
    var owing = (now-commences)*rate-paid;
    require(owing > 0);
    paid += owing;
    benefactor.transfer(owing);
  }

  function burn() public onlyOwner {
    payBenefactor();		/* Pay what is currently owed. */
    selfdestruct(this);		/* Burn the residue. */
  }
}
