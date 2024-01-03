// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StableSwapGusd.sol";
import "./DepositGusd.sol";
import "./StableSwap3.sol";
import "./StrategyCurve.sol";

contract StrategyGusd is StrategyCurve {
    // 3Pool StableSwap
    address private constant BASE_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    // GUSD StableSwap
    address private constant SWAP = 0x4f062658EaAF2C1ccf8C8e36D6824CDf41167956;
    address private constant GUSD = 0x056Fd409E1d7A124BD7017459dFEa2F387b6d5Cd;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyCurve(_controller, _vault, _underlying) {
        // Curve
        // GUSD / 3CRV
        lp = 0xD2967f45c4f384DEEa880F807Be904762a3DeA07;
        // DepositGusd
        pool = 0x64448B78561690B70E17CBE8029a3e5c1bB7136e;
        // Gauge
        gauge = 0xC5cfaDA84E902aD92DD40194f0883ad49639b023;
        // Minter
        minter = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
        // DAO
        crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    }

    function _getVirtualPrice() internal view override returns (uint) {
        return StableSwapGusd(SWAP).get_virtual_price();
    }

    function _addLiquidity(uint _amount, uint _index) internal override {
        uint[4] memory amounts;
        amounts[_index] = _amount;
        DepositGusd(pool).add_liquidity(amounts, 0);
    }

    function _removeLiquidityOneCoin(uint _lpAmount) internal override {
        IERC20(lp).safeApprove(pool, 0);
        IERC20(lp).safeApprove(pool, _lpAmount);

        DepositGusd(pool).remove_liquidity_one_coin(
            _lpAmount,
            int128(underlyingIndex),
            0
        );
    }

    function _getMostPremiumToken() internal view override returns (address, uint) {
        uint[4] memory balances;
        balances[0] = StableSwapGusd(SWAP).balances(0).mul(1e16); // GUSD
        balances[1] = StableSwap3(BASE_POOL).balances(0); // DAI
        balances[2] = StableSwap3(BASE_POOL).balances(1).mul(1e12); // USDC
        balances[3] = StableSwap3(BASE_POOL).balances(2).mul(1e12); // USDT

        uint minIndex = 0;
        for (uint i = 1; i < balances.length; i++) {
            if (balances[i] <= balances[minIndex]) {
                minIndex = i;
            }
        }

        if (minIndex == 0) {
            return (GUSD, 0);
        }
        if (minIndex == 1) {
            return (DAI, 1);
        }
        if (minIndex == 2) {
            return (USDC, 2);
        }
        return (USDT, 3);
    }
}
