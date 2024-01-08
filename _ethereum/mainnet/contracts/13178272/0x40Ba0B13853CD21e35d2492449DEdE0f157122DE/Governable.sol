// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

contract Governable {

  address public governance;

  constructor(address _governance) public {
    setGovernance(_governance);
  }

  modifier onlyGovernance() {
    // pass check while governance might not initialized (i.e. in proxy)
    require((governance==address(0)) || (msg.sender==governance), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

}
