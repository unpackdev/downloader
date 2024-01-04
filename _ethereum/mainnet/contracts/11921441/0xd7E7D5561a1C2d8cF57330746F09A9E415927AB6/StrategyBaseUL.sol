//SPDX-License-Identifier: Unlicense
pragma solidity 0.5.16;

import "./RewardTokenProfitNotifier.sol";
import "./IStrategy.sol";

import "./ILiquidator.sol";
import "./ILiquidatorRegistry.sol";

contract StrategyBaseUL is IStrategy, RewardTokenProfitNotifier  {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event ProfitsNotCollected(address);
  event Liquidating(address, uint256);

  address public underlying;
  address public vault;
  mapping (address => bool) public unsalvagableTokens;
  address public universalLiquidatorRegistry;


  modifier restricted() {
    require(msg.sender == vault || msg.sender == address(controller()) || msg.sender == address(governance()),
      "The sender has to be the controller or vault or governance");
    _;
  }

  constructor(
    address _storage,
    address _underlying,
    address _vault,
    address _rewardToken,
    address _universalLiquidatorRegistry
  ) RewardTokenProfitNotifier(_storage, _rewardToken) public {
    underlying = _underlying;
    vault = _vault;
    unsalvagableTokens[_rewardToken] = true;
    unsalvagableTokens[_underlying] = true;
    universalLiquidatorRegistry = _universalLiquidatorRegistry;
  }

  function universalLiquidator() public view returns(address) {
    return ILiquidatorRegistry(universalLiquidatorRegistry).universalLiquidator();
  }
}
