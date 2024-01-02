// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
import "./ISyncusCalculator.sol";
import "./FixedPoint.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./Ownable.sol";
import "./IPriceFeed.sol";

contract SyncusCalculator is Ownable, ISyncusCalculator {
    using FixedPoint for *;
    using SafeMath for uint;
    using SafeMath for uint112;

    address public immutable Sync;

    IPriceFeed public priceFeed =
        IPriceFeed(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    constructor(address _Sync) {
        require(_Sync != address(0), "Sync is the zero address");
        Sync = _Sync;
    }

    function getKValue(address _pair) public view returns (uint k_) {
        uint token0Decimals = IERC20(IUniswapV2Pair(_pair).token0()).decimals();
        uint token1Decimals = IERC20(IUniswapV2Pair(_pair).token1()).decimals();
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(_pair).getReserves();
        uint sumDecimals = token0Decimals.add(token1Decimals);
        uint pairDecimals = IERC20(_pair).decimals();

        if (sumDecimals > pairDecimals) {
            uint decimals = sumDecimals.sub(pairDecimals);
            k_ = reserve0.mul(reserve1).div(10 ** decimals);
        } else if (sumDecimals == pairDecimals) {
            k_ = reserve0.mul(reserve1);
        } else {
            uint decimals = pairDecimals.sub(sumDecimals);
            k_ = reserve0.mul(reserve1).mul(10 ** decimals);
        }
    }

    function getTotalValue(address _pair) public view returns (uint _value) {
        _value = getKValue(_pair).sqrrt().mul(2);
    }

    function valuation(
        address _pair,
        uint amount_
    ) external view override returns (uint _value) {
        uint totalValue = getTotalValue(_pair);
        uint totalSupply = IUniswapV2Pair(_pair).totalSupply();

        _value = totalValue
            .mul(FixedPoint.fraction(amount_, totalSupply).decode112with18())
            .div(1e18);
    }

    function markdown(address _pair) external view override returns (uint) {
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair(_pair).getReserves();

        uint reserve;
        if (IUniswapV2Pair(_pair).token0() == Sync) {
            reserve = reserve1;
        } else {
            reserve = reserve0;
        }
        return
            reserve.mul(2 * (10 ** IERC20(Sync).decimals())).div(
                getTotalValue(_pair)
            );
    }

    function valuationEther(
        uint _amount
    ) external view override returns (uint _value) {
        uint256 ethValue = priceFeed.latestAnswer();

        ethValue = ethValue.div(10 ** 8);
        _value = (_amount.div(10 ** 18).mul(ethValue)).mul(10 ** 9); 
    }
}
