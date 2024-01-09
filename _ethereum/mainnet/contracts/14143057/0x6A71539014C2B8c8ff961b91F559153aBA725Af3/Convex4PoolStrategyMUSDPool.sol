// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./Convex4PoolStrategy.sol";

//solhint-disable no-empty-blocks
contract Convex4PoolStrategyMUSDPool is Convex4PoolStrategy {
    // MUSD-3CRV Metapool
    // Composed of [ MUSD , [ DAI, USDC, USDT ]]

    // MUSD LP Token
    address internal constant CRV_LP = 0x1AEf73d49Dedc4b1778d0706583995958Dc862e6;
    // MUSD Pool
    address internal constant CRV_POOL = 0x8474DdbE98F5aA3179B3B3F5942D724aFcdec9f6;
    // MUSD Deposit Contract
    address internal constant CRV_DEPOSIT = 0x803A2B40c5a9BB2B86DD630B274Fa2A9202874C2;
    // MUSD Gauge
    address internal constant GAUGE = 0x5f626c30EC1215f4EdCc9982265E8b1F411D1352;
    // Convex Pool ID for MUSD-3CRV
    uint256 internal constant CONVEX_POOL_ID = 14;

    address private constant THREEPOOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    constructor(
        address _pool,
        address _swapManager,
        uint256 _collateralIdx,
        string memory _name
    )
        Convex4PoolStrategy(
            _pool,
            _swapManager,
            CRV_DEPOSIT,
            CRV_POOL,
            CRV_LP,
            GAUGE,
            _collateralIdx,
            CONVEX_POOL_ID,
            _name
        )
    {
        oracleRouterIdx = 1;
    }

    function _init(
        address _crvPool,
        uint256 /* _n */
    ) internal virtual override {
        coins.push(IStableSwap(_crvPool).coins(0));
        coinDecimals.push(IERC20Metadata(coins[0]).decimals());
        for (uint256 i = 0; i < 3; i++) {
            coins.push(IStableSwap(THREEPOOL).coins(i));
            coinDecimals.push(IERC20Metadata(coins[i]).decimals());
        }
    }

    function _depositToCurve(uint256 _amt) internal virtual override returns (bool) {
        if (_amt != 0) {
            uint256[2] memory _depositAmounts;
            _depositAmounts[collIdx] = _amt;
            uint256[4] memory _depositAmountsZap;
            _depositAmountsZap[collIdx] = _amt;

            uint256 _expectedOut =
                _calcAmtOutAfterSlippage(
                    IStableSwap2x(address(crvPool)).calc_token_amount(_depositAmounts, true),
                    crvSlippage
                );

            uint256 _minLpAmount =
                ((_amt * _getSafeUsdRate()) / crvPool.get_virtual_price()) * 10**(18 - coinDecimals[collIdx]);
            if (_expectedOut > _minLpAmount) _minLpAmount = _expectedOut;
            // solhint-disable-next-line no-empty-blocks
            try IDeposit4x(crvDeposit).add_liquidity(_depositAmountsZap, _minLpAmount) {} catch Error(
                string memory _reason
            ) {
                emit DepositFailed(_reason);
                return false;
            }
        }
        return true;
    }
}
