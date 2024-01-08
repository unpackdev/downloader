// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./APigs.sol";
import "./ERC20.sol";
import "./Ownable.sol";

contract Boom is ERC20, Ownable {
  uint256 public constant BOOM_RATE = 10;
  uint256 private startTime;
  address private aPigsAddress;

  mapping(address => uint256) public lastUpdate;

  APigs private aPigsContract;

  modifier onlyAPigsAddress() {
    require(msg.sender == address(aPigsContract), "Not aPigs address");
    _;
  }

  constructor() ERC20("Boom", "$BOOM") {
    startTime = 1639612800;
  }

  function updateTokens(address from, address to) external onlyAPigsAddress {
    if (from != address(0)) {
      _mint(from, getPendingTokens(from));
      lastUpdate[from] = block.timestamp;
    }

    if (to != address(0)) {
      _mint(to, getPendingTokens(to));
      lastUpdate[to] = block.timestamp;
    }
  }

  function getPendingTokens(address _user) public view returns (uint256) {
    uint256[] memory ownedAPigs = aPigsContract.walletOfOwner(_user);

    return
      (ownedAPigs.length *
        BOOM_RATE *
        (
          (block.timestamp -
            (lastUpdate[_user] >= startTime ? lastUpdate[_user] : startTime))
        )) / 86400;
  }

  function claim() external {
    _mint(msg.sender, getPendingTokens(msg.sender));
    lastUpdate[msg.sender] = block.timestamp;
  }

  function giveAway(address _user, uint256 _amount) public onlyOwner {
    _mint(_user, _amount);
  }

  function burn(address _user, uint256 _amount) public onlyAPigsAddress {
    _burn(_user, _amount);
  }

  function setAPigsContract(address _aPigsAddress) public onlyOwner {
    aPigsContract = APigs(_aPigsAddress);
  }
}