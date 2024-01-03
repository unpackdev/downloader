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

contract StrategyHegicWBTC is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public hegic;
    address public hegicStaking;
    uint256 public constant LOT_PRICE = 888e21;
    address public WBTC;
    address public unirouter;
    string public constant override name = "StrategyHegicWBTC";

    constructor(
        address _vault,
        address _hegic,
        address _hegicStaking,
        address _unirouter,
        address _WBTC
    ) public BaseStrategy(_vault) {
        hegic = _hegic;
        hegicStaking = _hegicStaking;
        unirouter = _unirouter;
        WBTC = _WBTC;

        IERC20(hegic).safeApprove(hegicStaking, uint256(-1));
        IERC20(WBTC).safeApprove(unirouter, uint256(-1));
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

    function prepareReturn(uint256 _debtOutstanding) internal override returns (uint256 _profit) {
        // We might need to return want to the vault
        if (_debtOutstanding > 0) {
            liquidatePosition(_debtOutstanding);
        }

        // Update reserve with the available want so it's not considered profit
        setReserve(balanceOfWant().sub(_debtOutstanding));

        // Claim profit only when available
        uint256 wbtcProfit = wbtcFutureProfit();
        if (wbtcProfit > 0) {
            IHegicStaking(hegicStaking).claimProfit();

            // swap wbtc available in the contract for hegic
            uint256 _wbtcBalance = IERC20(WBTC).balanceOf(address(this));
            _swap(_wbtcBalance);
        }

        // Final profit is want generated in the swap if ethProfit > 0
        _profit = balanceOfWant().sub(getReserve());
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        //emergency exit is dealt with in prepareReturn
        if (emergencyExit) {
            return;
        }

        // Reset the reserve value before
        setReserve(0);

        // Invest the rest of the want
        uint256 _wantAvailable = balanceOfWant().sub(_debtOutstanding);
        uint256 _lotsToBuy = _wantAvailable.div(LOT_PRICE);

        if (_lotsToBuy > 0) {
            IHegicStaking(hegicStaking).buy(_lotsToBuy);
        }
    }

    function exitPosition() internal override {
        uint256 stakes = IERC20(hegicStaking).balanceOf(address(this));
        IHegicStaking(hegicStaking).sell(stakes);
    }

    function liquidatePosition(uint256 _amountNeeded) internal override returns (uint256 _amountFreed) {
        if (balanceOfWant() < _amountNeeded) {
            // We need to sell stakes to get back more want
            _withdrawSome(_amountNeeded.sub(balanceOfWant()));
        }

        // Since we might free more than needed, let's send back the min
        _amountFreed = Math.min(balanceOfWant(), _amountNeeded);
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

    // Changed to WBTC. WBTC->HEGIC does not exist, so WBTC->ETH->HEGIC must do.
    function _swap(uint256 _amountIn) internal returns (uint256[] memory amounts) {
        address[] memory path = new address[](3);
        path[0] = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // wbtc
        path[1] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // dai
        path[2] = address(want);

        Uni(unirouter).swapExactTokensForTokens(_amountIn, uint256(0), path, address(this), now.add(1 days));
    }

    function hegicFutureProfit() public view returns (uint256) {
        uint256 wbtcProfit = wbtcFutureProfit();
        if (wbtcProfit == 0) {
            return 0;
        }

        address[] memory path = new address[](3);
        path[0] = address(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); // wbtc
        path[1] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // dai
        path[2] = address(want);
        uint256[] memory amounts = Uni(unirouter).getAmountsOut(wbtcProfit, path);

        //todo: no idea what this bit of code does.
        return amounts[amounts.length - 1];
    }

    function wbtcFutureProfit() public view returns (uint256) {
        return IHegicStaking(hegicStaking).profitOf(address(this));
    }

    function balanceOfWant() public view returns (uint256) {
        return IERC20(want).balanceOf(address(this));
    }

    function balanceOfStake() public view returns (uint256) {
        return IERC20(hegicStaking).balanceOf(address(this)).mul(LOT_PRICE);
    }
}
