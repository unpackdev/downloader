// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface ITekyan {
  function balanceOfFirstTribe(address owner) external view returns (uint256);
}

contract Watu is ERC20, ERC20Burnable, Ownable {
  using SafeMath for uint256;

  uint256 public constant BASE_RATE = 10 ether;
  uint256 public constant INITIAL_ISSUANCE = 250 ether;
  // Saturday, January 31, 2032 12:00:00 PM
  uint256 public constant END = 1959163200;

  mapping(address => uint256) public rewards;
  mapping(address => uint256) public lastUpdate;

  address public TEKYAN_ADDRESS;

  event RewardPaid(address indexed user, uint256 reward);

  constructor() ERC20("Watu", "WATU") {}

  function updateReward(
    address from,
    address to,
    uint256 tokenId
  ) external {
    require(msg.sender == TEKYAN_ADDRESS, "INVALID_CALLER");

    uint256 time = min(block.timestamp, END);
    uint256 timeFrom = lastUpdate[from];
    uint256 timeTo = lastUpdate[to];

    if (tokenId < 1000) {
      // On transfers
      if (from != address(0)) {
        if (timeFrom > 0)
          rewards[from] += ITekyan(TEKYAN_ADDRESS)
            .balanceOfFirstTribe(from)
            .mul(BASE_RATE.mul((time.sub(timeFrom))))
            .div(86400);
        if (timeFrom != END) lastUpdate[from] = time;
      }

      // On transfers
      if (to != address(0)) {
        if (timeTo > 0)
          rewards[to] += ITekyan(TEKYAN_ADDRESS)
            .balanceOfFirstTribe(to)
            .mul(BASE_RATE.mul((time.sub(timeTo))))
            .div(86400);
        if (timeTo != END) lastUpdate[to] = time;
      }

      // On mint
      if (from == address(0) && to != address(0)) {
        rewards[to] += INITIAL_ISSUANCE;
      }
    }
  }

  function getReward(address to) external {
    require(msg.sender == TEKYAN_ADDRESS, "INVALID_CALLER");

    uint256 reward = rewards[to];
    if (reward > 0) {
      rewards[to] = 0;
      _mint(to, reward);
      emit RewardPaid(to, reward);
    }
  }

  function getClaimableReward(address to) external view returns (uint256) {
    uint256 time = min(block.timestamp, END);
    uint256 pending = ITekyan(TEKYAN_ADDRESS)
      .balanceOfFirstTribe(to)
      .mul(BASE_RATE.mul((time.sub(lastUpdate[to]))))
      .div(86400);

    return rewards[to].add(pending);
  }

  function setTekyanAddress(address tokenAddress) external onlyOwner {
    TEKYAN_ADDRESS = tokenAddress;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}
