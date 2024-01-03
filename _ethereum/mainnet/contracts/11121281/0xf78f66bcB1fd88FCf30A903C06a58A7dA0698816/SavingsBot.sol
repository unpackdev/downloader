// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IContribute.sol";
import "./IMStable.sol";
import "./IVault.sol";
import "./ISavingsManager.sol";
import "./IUniswapV2Router02.sol";

contract SavingsBot {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public contribute;
  address public trib;
  address public mUSD;
  address public vault;
  address public savingsManager;
  address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  uint256 public totalTribBalance;
  uint256 public lastUpdatedInterest;
  uint256 public interval = 30 minutes;

  address[] private pair = [usdc, weth];

  constructor(address _contribute) public {
    contribute = _contribute;
    trib = IContribute(contribute).token();
    mUSD = IContribute(contribute).reserve();
    vault = IContribute(contribute).vault();
    savingsManager = _fetchMStableManager();
  }

  function claimInterest() external {
    require(_canClaim(), "SavingsBot: Can only claim after 30 minutes of last fetch.");

    ISavingsManager(_fetchMStableManager()).collectAndDistributeInterest(mUSD);
    uint256 interest = IContribute(contribute).getInterest();

    require(interest != 0, "SavingsBot: No interest to claim.");
    require(interest > SafeMath.mul(700_000, tx.gasprice).mul(_getEthPrice(pair)), "SavingsBot: Not enough interest to cover tx cost.");

    uint256 tribRequired =  IContribute(contribute).totalClaimRequired();
    IERC20(trib).safeTransferFrom(msg.sender, address(this), tribRequired);
    IContribute(contribute).claimInterest();

    IERC20(mUSD).safeTransfer(msg.sender, IERC20(mUSD).balanceOf(address(this)));
  }

  function canClaim() external view returns (bool) {
    return _canClaim();
  }

  function lastCollection() external view returns (uint256) {
    return _lastCollection();
  }

  function timeBeforeNextCollection() external view returns (uint256) {
    uint256 timeLeft;
    if((int256(_lastCollection().add(interval) - block.timestamp)) <= 0) {
        timeLeft = 0;
    } else {
        timeLeft = _lastCollection().add(interval).sub(block.timestamp);
    }
    return timeLeft;
  }

  function _lastCollection() internal view returns (uint256) {
    return ISavingsManager(savingsManager).lastCollection(mUSD);
  }

  function _getEthPrice(address[] memory _pair) internal view returns (uint256) {
    uint256[] memory prices = IUniswapV2Router02(router).getAmountsIn(1 ether, _pair);
    return prices[0].div(1000000);
  }

  function _canClaim() internal view returns (bool) {
    return block.timestamp.sub(interval) > ISavingsManager(savingsManager).lastCollection(mUSD);
  }

  function _fetchMStableSavings() internal view returns (address) {
    return IMStable(_fetchMStableManager()).savingsContracts(mUSD);
  }

  function _fetchMStableManager() internal view returns (address manager) {
    manager = IMStable(IVault(vault).nexusGovernance()).getModule(keccak256('SavingsManager'));
  }

}
