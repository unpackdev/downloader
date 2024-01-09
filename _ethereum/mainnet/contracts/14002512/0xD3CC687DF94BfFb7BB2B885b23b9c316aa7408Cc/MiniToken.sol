// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";

contract MiniToken is ERC20, Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  IERC721 public minitaurContract;

  uint256 public constant MAX_INITIAL_SUPPLY = 500000 * 10**9;     // 500k tokens initially created
  uint256 public constant MAX_CLAIMABLE_SUPPLY = 1500000 * 10**9;   // 1.5 million tokens claimable by burning Minitaurs
  uint256 public constant ACCUMULATION_PERIOD = 180 * 24 * 60 * 60; // 180 days
  uint256 public constant INITIAL_MINITAUR_SUPPLY = 3333;
  address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
  
  uint256 public tokenAccumulationStartTime;
  uint256 public totalClaimedAmount;
  bool private ownerMinted;

  constructor(
    address minitaurAddress
  ) ERC20("Mini Token", "$MINI") {
    minitaurContract = IERC721(minitaurAddress);
    tokenAccumulationStartTime = block.timestamp;
  }

  function decimals() public view virtual override returns (uint8) {
    return 9;
  }

  function redeemTokens(uint256[] memory tokenIds) public nonReentrant {
    require(tokenIds.length > 0, "Must provide at least 1 Minitaur TokenId");
    
    uint256 reward = getCurrentRewardPerMinitaur() * tokenIds.length;
    totalClaimedAmount += reward;
    _mint(msg.sender, reward);

    for (uint256 i = 0; i < tokenIds.length; i++) {
      minitaurContract.transferFrom(msg.sender, BURN_ADDRESS, tokenIds[i]);
    }
  }

  function getCurrentRewardPerMinitaur() public view returns (uint256) {
    uint256 elapsedTime = block.timestamp - tokenAccumulationStartTime;

    if (elapsedTime > ACCUMULATION_PERIOD) elapsedTime = ACCUMULATION_PERIOD;

    uint256 remainingMinitaurs = INITIAL_MINITAUR_SUPPLY - minitaurContract.balanceOf(BURN_ADDRESS);
    
    if (remainingMinitaurs == 0) return 0;
    
    return (MAX_CLAIMABLE_SUPPLY - totalClaimedAmount) * elapsedTime / ACCUMULATION_PERIOD / remainingMinitaurs;
  }

  function claimableAmount(address wallet) public view returns (uint256) {
    uint256 minitaurBalance = minitaurContract.balanceOf(wallet);

    return minitaurBalance * getCurrentRewardPerMinitaur();
  }

  function mintInitialPool() external onlyOwner {
    require(!ownerMinted, "Initial pool already minted");

    ownerMinted = true;
    _mint(msg.sender, MAX_INITIAL_SUPPLY);
  }
}
