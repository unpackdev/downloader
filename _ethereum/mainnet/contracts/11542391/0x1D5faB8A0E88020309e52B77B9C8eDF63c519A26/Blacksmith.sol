// SPDX-License-Identifier: None
pragma solidity ^0.7.4;

interface ICOVER {
  function setBlacksmith(address _newBlacksmith) external returns (bool);
}

contract Blacksmith {
  ICOVER public cover;
  address public governance;
  
  constructor (address _coverAddress, address _governance) {
    cover = ICOVER(_coverAddress);
    governance = _governance;
  }


  modifier onlyGovernance() {
    require(msg.sender == governance, "Blacksmith: caller not governance");
    _;
  }

  /// @notice transfer minting rights to new blacksmith
  function transferMintingRights(address _newAddress) external onlyGovernance {
    cover.setBlacksmith(_newAddress);
  }
}