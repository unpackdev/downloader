// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StableSwap3.sol";
import "./StrategyCurve.sol";

contract Strategy3Crv is StrategyCurve {
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyCurve(_controller, _vault, _underlying) {
        // Curve
        // 3Crv
        lp = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
        // 3 Pool
        pool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
        // Gauge
        gauge = 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;
        // Minter
        minter = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
        // DAO
        crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    }

    function _getVirtualPrice() internal view override returns (uint) {
        return StableSwap3(pool).get_virtual_price();
    }

    function _addLiquidity(uint _amount, uint _index) internal override {
        uint[3] memory amounts;
        amounts[_index] = _amount;
        StableSwap3(pool).add_liquidity(amounts, 0);
    }

    function _removeLiquidityOneCoin(uint _lpAmount) internal override {
        StableSwap3(pool).remove_liquidity_one_coin(
            _lpAmount,
            int128(underlyingIndex),
            0
        );
    }

    function _getMostPremiumToken() internal view override returns (address, uint) {
        uint[] memory balances = new uint[](3);
        balances[0] = StableSwap3(pool).balances(0); // DAI
        balances[1] = StableSwap3(pool).balances(1).mul(1e12); // USDC
        balances[2] = StableSwap3(pool).balances(2).mul(1e12); // USDT

        // DAI
        if (balances[0] <= balances[1] && balances[0] <= balances[2]) {
            return (DAI, 0);
        }

        // USDC
        if (balances[1] <= balances[0] && balances[1] <= balances[2]) {
            return (USDC, 1);
        }

        return (USDT, 2);
    }
}
