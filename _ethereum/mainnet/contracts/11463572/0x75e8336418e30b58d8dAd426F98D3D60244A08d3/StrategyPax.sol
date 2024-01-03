// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StableSwapPax.sol";
import "./DepositPax.sol";
import "./StrategyCurve.sol";

contract StrategyPax is StrategyCurve {
    // PAX StableSwap
    address private constant SWAP = 0x06364f10B501e868329afBc005b3492902d6C763;
    address private constant PAX = 0x8E870D67F660D95d5be530380D0eC0bd388289E1;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyCurve(_controller, _vault, _underlying) {
        // Curve
        // DAI/USDC/USDT/PAX
        lp = 0xD905e2eaeBe188fc92179b6350807D8bd91Db0D8;
        // DepositPax
        pool = 0xA50cCc70b6a011CffDdf45057E39679379187287;
        // Gauge
        gauge = 0x64E3C23bfc40722d3B649844055F1D51c1ac041d;
        // Minter
        minter = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
        // DAO
        crv = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    }

    function _getVirtualPrice() internal view override returns (uint) {
        return StableSwapPax(SWAP).get_virtual_price();
    }

    function _addLiquidity(uint _amount, uint _index) internal override {
        uint[4] memory amounts;
        amounts[_index] = _amount;
        DepositPax(pool).add_liquidity(amounts, 0);
    }

    function _removeLiquidityOneCoin(uint _lpAmount) internal override {
        IERC20(lp).safeApprove(pool, 0);
        IERC20(lp).safeApprove(pool, _lpAmount);

        DepositPax(pool).remove_liquidity_one_coin(
            _lpAmount,
            int128(underlyingIndex),
            0,
            false
        );
    }

    function _getMostPremiumToken() internal view override returns (address, uint) {
        uint[4] memory balances;
        balances[0] = StableSwapPax(SWAP).balances(0); // DAI
        balances[1] = StableSwapPax(SWAP).balances(1).mul(1e12); // USDC
        balances[2] = StableSwapPax(SWAP).balances(2).mul(1e12); // USDT
        balances[3] = StableSwapPax(SWAP).balances(3); // PAX

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
        return (PAX, 3);
    }
}
