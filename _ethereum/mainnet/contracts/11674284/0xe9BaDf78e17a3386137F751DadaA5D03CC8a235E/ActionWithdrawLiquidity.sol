// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./GelatoActionsStandard.sol";
import "./IGelatoSysAdmin.sol";
import "./OracleAggregator.sol";
import "./IConditionalTokens.sol";
import "./IGasPriceOracle.sol";
import "./IUniswapV2.sol";

/// @title ActionWithdrawLiquidity
/// @author @hilmarx
/// @notice Gelato Action that
///  1) withdraws conditional tokens from FPMM
///  2) merges position on conditional tokens contract
///  3) transfers merged tokens back to user
contract ActionWithdrawLiquidity is GelatoActionsStandard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event LogWithdrawSuccess(
        uint256 indexed withdrawAmount,
        uint256 indexed fee
    );

    IGelatoSysAdmin public immutable gelatoCore;
    // solhint-disable var-name-mixedcase
    address public immutable ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // solhint-disable var-name-mixedcase
    IERC20 public immutable WETH;
    // solhint-disable const-name-snakecase
    uint256 public constant OVERHEAD = 200000;
    IUniswapV2Router02 public immutable uniRouter;
    OracleAggregator public immutable oracleAggregator;

    constructor(
        IGelatoSysAdmin _gelatoCore,
        IERC20 _weth,
        IUniswapV2Router02 _uniRouter,
        OracleAggregator _oracleAggregator
    ) public {
        gelatoCore = _gelatoCore;
        WETH = _weth;
        uniRouter = _uniRouter;
        oracleAggregator = _oracleAggregator;
    }

    // ======= ACTION IMPLEMENTATION DETAILS =========
    // solhint-disable function-max-lines
    // solhint-disable code-complexity
    function action(
        IConditionalTokens _conditionalTokens,
        IFixedProductMarketMaker _fixedProductMarketMaker,
        uint256[] memory _positionIds,
        bytes32 _conditionId,
        bytes32 _parentCollectionId,
        address _collateralToken,
        address _receiver
    ) public virtual {
        uint256 startGas = gasleft();

        require(
            _positionIds.length > 0,
            "ActionWithdrawLiquidity: Position Ids must be at least of length 1"
        );

        // 1. Fetch the balance of liquidity pool tokens
        uint256 lpTokensToWithdraw =
            IERC20(address(_fixedProductMarketMaker)).balanceOf(address(this));

        require(
            lpTokensToWithdraw > 0,
            "ActionWithdrawLiquidity: No LP tokens to withdraw"
        );

        // 2. Fetch Current collateral token balance to know how much the proxy already has
        // and avoid more state reads by calling feesWithdrawablyBy
        uint256 collateralTokenBalancePre =
            IERC20(_collateralToken).balanceOf(address(this));

        // 3. Remove funding from fixedProductMarketMaker
        _fixedProductMarketMaker.removeFunding(lpTokensToWithdraw);

        // 4. Check balances of conditional tokens
        address[] memory proxyAddresses = new address[](_positionIds.length);

        for (uint256 i; i < _positionIds.length; i++) {
            proxyAddresses[i] = address(this);
        }

        // stack-to-deep-avoidance
        {
            uint256[] memory outcomeTokenBalances =
                IERC1155(address(_conditionalTokens)).balanceOfBatch(
                    proxyAddresses,
                    _positionIds
                );

            // 5. Find the lowest balance of all outcome tokens
            uint256 amountToMerge = outcomeTokenBalances[0];
            for (uint256 i = 1; i < outcomeTokenBalances.length; i++) {
                uint256 outcomeTokenBalance = outcomeTokenBalances[i];
                if (outcomeTokenBalance < amountToMerge)
                    amountToMerge = outcomeTokenBalance;
            }

            require(
                amountToMerge > 0,
                "ActionWithdrawLiquidity: No outcome tokens to merge"
            );

            uint256[] memory partition = new uint256[](_positionIds.length);
            for (uint256 i; i < partition.length; i++) {
                partition[i] = 1 << i;
            }

            // 6. Merge outcome tokens
            _conditionalTokens.mergePositions(
                IERC20(_collateralToken),
                _parentCollectionId,
                _conditionId,
                partition,
                amountToMerge
            );
        }

        // 7. Calculate exactly how many collateral tokens were recevied
        uint256 collateralTokensReceived =
            IERC20(_collateralToken).balanceOf(address(this)).sub(
                collateralTokenBalancePre
            );

        // 8. Calculate how much this action consumed
        // User will pay tx.gasprice capped by chainlink oracle x 1.368
        uint256 gasPrice = fetchCurrentGasPrice().mul(1368).div(1000);
        gasPrice = tx.gasprice > gasPrice ? gasPrice : tx.gasprice;
        uint256 ethToBeRefunded =
            startGas.sub(gasleft()).add(OVERHEAD).mul(gasPrice);

        // 9. Calculate how much of the collateral token needs be refunded to the provider
        uint256 collateralTokenFee;
        if (address(WETH) == _collateralToken)
            collateralTokenFee = ethToBeRefunded;
        else {
            try
                oracleAggregator.getExpectedReturnAmount(
                    ethToBeRefunded,
                    ETH,
                    _collateralToken
                )
            returns (uint256 returnAmount, uint256) {
                if (returnAmount != 0) collateralTokenFee = returnAmount;
                else {
                    collateralTokenFee = getUniswapRate(
                        address(WETH),
                        ethToBeRefunded,
                        _collateralToken
                    );
                }
            } catch {
                revert("ActionWithdrawLiquidity: OracleAggregator Error");
            }
        }

        require(
            collateralTokenFee <= collateralTokensReceived,
            "ActionWithdrawLiquidity: Insufficient Collateral to pay for withdraw transaction"
        );

        // 10. Transfer received collateral minus Fee back to user
        IERC20(_collateralToken).safeTransfer(
            _receiver,
            collateralTokensReceived - collateralTokenFee,
            "Transfer Collateral to receiver failed"
        );

        // 11. Transfer Fee back to executor
        IERC20(_collateralToken).safeTransfer(
            tx.origin,
            collateralTokenFee,
            "Transfer Collateral to receiver failed"
        );

        emit LogWithdrawSuccess(
            collateralTokensReceived - collateralTokenFee,
            collateralTokenFee
        );
    }

    function fetchCurrentGasPrice() public view returns (uint256) {
        return
            uint256(
                IGasPriceOracle(gelatoCore.gelatoGasPriceOracle())
                    .latestAnswer()
            );
    }

    function getUniswapRate(
        address _sellToken,
        uint256 _amountIn,
        address _buyToken
    ) public view returns (uint256 expectedRate) {
        address[] memory tokenPath = _getPaths(_sellToken, _buyToken);

        try uniRouter.getAmountsOut(_amountIn, tokenPath) returns (
            uint256[] memory expectedRates
        ) {
            expectedRate = expectedRates[1];
        } catch {
            revert("ActionWithdrawLiquidity: UniswapV2GetExpectedRateError");
        }
    }

    function _getPaths(address _sellToken, address _buyToken)
        internal
        pure
        returns (address[] memory paths)
    {
        paths = new address[](2);
        paths[0] = _sellToken;
        paths[1] = _buyToken;
    }
}
