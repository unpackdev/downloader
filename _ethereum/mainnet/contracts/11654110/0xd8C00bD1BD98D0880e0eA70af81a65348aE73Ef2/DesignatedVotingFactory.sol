// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Withdrawable.sol";
import "./DesignatedVoting.sol";

contract DesignatedVotingFactory is Withdrawable {
  enum Roles {Withdrawer}

  address private finder;
  mapping(address => DesignatedVoting) public designatedVotingContracts;

  constructor(address finderAddress) public {
    finder = finderAddress;

    _createWithdrawRole(
      uint256(Roles.Withdrawer),
      uint256(Roles.Withdrawer),
      msg.sender
    );
  }

  function newDesignatedVoting(address ownerAddress)
    external
    returns (DesignatedVoting)
  {
    require(
      address(designatedVotingContracts[msg.sender]) == address(0),
      'Duplicate hot key not permitted'
    );

    DesignatedVoting designatedVoting =
      new DesignatedVoting(finder, ownerAddress, msg.sender);
    designatedVotingContracts[msg.sender] = designatedVoting;
    return designatedVoting;
  }

  function setDesignatedVoting(address designatedVotingAddress) external {
    require(
      address(designatedVotingContracts[msg.sender]) == address(0),
      'Duplicate hot key not permitted'
    );
    designatedVotingContracts[msg.sender] = DesignatedVoting(
      designatedVotingAddress
    );
  }
}
