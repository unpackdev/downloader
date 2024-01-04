// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;

import "./Governance.sol";

contract Governable {
  Governance public governance;

  constructor(address _governance) public {
    require(_governance != address(0), "New governance shouldn't be empty");
    governance = Governance(_governance);
  }

  modifier onlyGovernance() {
    require(governance.isOwner(msg.sender), "Not governance");
    _;
  }
  
  modifier onlyGemlyMinter() {
    require(governance.isGemlyMinter(msg.sender), "Not gemly minter");
    _;
  }

  modifier onlyGameMinter() {
    require(governance.isGameMinter(msg.sender), "Not game minter");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "New governance shouldn't be empty");
    governance = Governance(_governance);
  }
}
