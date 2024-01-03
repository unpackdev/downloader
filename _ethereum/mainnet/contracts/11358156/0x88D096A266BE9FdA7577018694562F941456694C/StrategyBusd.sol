// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StableSwapBusd.sol";
import "./DepositBusd.sol";
import "./StrategyCurve.sol";

contract StrategyBusd is StrategyCurve {
    // BUSD StableSwap
    address private constant SWAP = 0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27;
    address private constant BUSD = 0x4Fabb145d64652a948d72533023f6E7A623C7C53;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyCurve(_controller, _vault, _underlying) {
        // Curve
        // yDAI/yUSDC/yUSDT/yBUSD
        lp = 0x3B3Ac5386837Dc563660FB6a0937DFAa5924333B;
        // DepositBusd
        pool = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;
        // Gauge
        gauge = 0x69Fb7c45726cfE2baDeE8317005d3F94bE838840;
        // Minter
        minter = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
        // DAO
        crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    }

    function _getVirtualPrice() internal view override returns (uint) {
        return StableSwapBusd(SWAP).get_virtual_price();
    }

    function _addLiquidity(uint _amount, uint _index) internal override {
        uint[4] memory amounts;
        amounts[_index] = _amount;
        DepositBusd(pool).add_liquidity(amounts, 0);
    }

    function _removeLiquidityOneCoin(uint _lpAmount) internal override {
        IERC20(lp).safeApprove(pool, 0);
        IERC20(lp).safeApprove(pool, _lpAmount);

        DepositBusd(pool).remove_liquidity_one_coin(
            _lpAmount,
            int128(underlyingIndex),
            0,
            false
        );
    }

    function _getMostPremiumToken() internal view override returns (address, uint) {
        uint[4] memory balances;
        balances[0] = StableSwapBusd(SWAP).balances(0); // DAI
        balances[1] = StableSwapBusd(SWAP).balances(1).mul(1e12); // USDC
        balances[2] = StableSwapBusd(SWAP).balances(2).mul(1e12); // USDT
        balances[3] = StableSwapBusd(SWAP).balances(3); // BUSD

        uint minIndex = 0;
        for (uint i = 1; i < balances.length; i++) {
            if (balances[i] <= balances[minIndex]) {
                minIndex = i;
            }
        }

        if (minIndex == 0) {
            return (DAI, 0);
        }
        if (minIndex == 1) {
            return (USDC, 1);
        }
        if (minIndex == 2) {
            return (USDT, 2);
        }
        return (BUSD, 3);
    }
}
