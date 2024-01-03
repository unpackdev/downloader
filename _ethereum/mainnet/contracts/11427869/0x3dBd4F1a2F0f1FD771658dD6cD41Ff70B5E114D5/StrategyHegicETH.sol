// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Math.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./BaseStrategy.sol";

import "./IHegicStaking.sol";
import "./Uni.sol";

contract StrategyHegicETH is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public hegic;
    address public hegicStaking;
    uint256 public constant LOT_PRICE = 888e21;
    address public unirouter;
    string public constant override name = "StrategyHegicETH";

    constructor(
        address _vault,
        address _hegic,
        address _hegicStaking,
        address _unirouter
    ) public BaseStrategy(_vault) {
        hegic = _hegic;
        hegicStaking = _hegicStaking;
        unirouter = _unirouter;
        IERC20(hegic).safeApprove(hegicStaking, uint256(-1));
    }

    function protectedTokens() internal override view returns (address[] memory) {
        address[] memory protected = new address[](3);
        protected[0] = address(want);
        protected[1] = hegic;
        protected[2] = hegicStaking;
        return protected;
    }

    function estimatedTotalAssets() public override view returns (uint256) {
        return balanceOfWant().add(balanceOfStake()).add(hegicFutureProfit());
    }

    function prepareReturn(uint256 _debtOutstanding) internal override returns (uint256 _profit, uint256 _loss, uint256 _debtPayment) {
        // We might need to return want to the vault
        if (_debtOutstanding > 0) {
            uint256 _amountFreed = liquidatePosition(_debtOutstanding);
            _debtPayment = Math.min(_amountFreed, _debtOutstanding);
        }

        uint256 balanceOfWantBefore = balanceOfWant();

        // Claim profit only when available
        uint256 ethProfit = ethFutureProfit();
        if (ethProfit > 0) {
            IHegicStaking(hegicStaking).claimProfit();
            _swap(address(this).balance);
        }

        // Final profit is want generated in the swap if ethProfit > 0
        _profit = balanceOfWant().sub(balanceOfWantBefore);
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        //emergency exit is dealt with in prepareReturn
        if (emergencyExit) {
            return;
        }

        // Invest the rest of the want
        uint256 _wantAvailable = balanceOfWant().sub(_debtOutstanding);
        uint256 _lotsToBuy = _wantAvailable.div(LOT_PRICE);

        if (_lotsToBuy > 0) {
            IHegicStaking(hegicStaking).buy(_lotsToBuy);
        }
    }

    function exitPosition(uint256 _debtOutstanding)
        internal
        override
        returns (
          uint256 _profit,
          uint256 _loss,
          uint256 _debtPayment
        )
    {
        uint256 stakes = IERC20(hegicStaking).balanceOf(address(this));
        IHegicStaking(hegicStaking).sell(stakes);
        return prepareReturn(_debtOutstanding);
    }

    function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _amountFreed) {
        if (balanceOfWant() < _amountNeeded) {
            // We need to sell stakes to get back more want
            _withdrawSome(_amountNeeded.sub(balanceOfWant()));
        }

        _amountFreed = balanceOfWant();
    }

    function _withdrawSome(uint256 _amount) internal returns (uint256) {
        uint256 stakesToSell = 0;
        if (_amount.mod(LOT_PRICE) == 0) {
            stakesToSell = _amount.div(LOT_PRICE);
        } else {
            // If there is a remainder, we need to sell one more lot to cover
            stakesToSell = _amount.div(LOT_PRICE).add(1);
        }

        // sell might fail if we hit the 24hs lock
        IHegicStaking(hegicStaking).sell(stakesToSell);
        return stakesToSell.mul(LOT_PRICE);
    }

    function prepareMigration(address _newStrategy) internal override {
        want.transfer(_newStrategy, balanceOfWant());
        IERC20(hegicStaking).transfer(_newStrategy, IERC20(hegicStaking).balanceOf(address(this)));
    }

    function _swap(uint256 _amountIn) internal returns (uint256[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // weth
        path[1] = address(want);

        return Uni(unirouter).swapExactETHForTokens{value: _amountIn}(_amountIn, path, address(this), now.add(1 days));
    }

    function hegicFutureProfit() public view returns (uint256) {
        uint256 ethProfit = ethFutureProfit();
        if (ethProfit == 0) {
            return 0;
        }

        address[] memory path = new address[](2);
        path[0] = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // weth
        path[1] = address(want);
        uint256[] memory amounts = Uni(unirouter).getAmountsOut(ethProfit, path);

        return amounts[amounts.length - 1];
    }

    function ethFutureProfit() public view returns (uint256) {
        return IHegicStaking(hegicStaking).profitOf(address(this));
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfStake() public view returns (uint256) {
        return IERC20(hegicStaking).balanceOf(address(this)).mul(LOT_PRICE);
    }

    // We need a receive function since Hegic pays in ETH
    receive() external payable {}
}
