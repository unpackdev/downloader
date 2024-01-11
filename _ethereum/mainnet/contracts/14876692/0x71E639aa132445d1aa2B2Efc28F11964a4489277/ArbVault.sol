// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;
import "./ERC4626.sol";
import "./Ownable.sol";
import "./Strategy.sol";
import "./IArbVault.sol";
error WrongMaturity();

contract ArbVault is ERC4626, Ownable {
    uint256 public immutable maturity;
    address public strategy;
    uint256 public unrealizedProfit;
    uint256 public unrealizedLoss;
    uint256 _totalToken;
    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        uint256 _maturity
    ) ERC4626(_asset, _name, _symbol) {
        require(_maturity > block.timestamp);
        maturity = _maturity;
    }

    function setStrategy(address _strategy) external onlyOwner {
        require(strategy == address(0));
        asset.approve(_strategy, type(uint256).max);
        strategy = _strategy;
    }

    function _checkAfterMaturity() internal {
        if (block.timestamp <= maturity) {
            revert WrongMaturity();
        }
    }

    function _checkBeforeMaturity() internal {
        if (block.timestamp > maturity) {
            revert WrongMaturity();
        }
    }

    function settleStrategy() external {
        // dev onlyEOA
        require(msg.sender == tx.origin);
        require(strategy != address(0));
        _checkAfterMaturity();
        (uint256 profit, uint256 loss) = Strategy(strategy).exit();
        unrealizedLoss += loss;
        unrealizedProfit += profit;
        strategy = address(0);
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        _checkAfterMaturity();
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override {
        _checkBeforeMaturity();
        Strategy(strategy).deposit(assets);
    }

    function totalAssets() public override view returns (uint256) {
        if (strategy == address(0)) {
            return asset.balanceOf(address(this));
        } else {
            return Strategy(strategy).estimatedAssets();
        }
    }
}
