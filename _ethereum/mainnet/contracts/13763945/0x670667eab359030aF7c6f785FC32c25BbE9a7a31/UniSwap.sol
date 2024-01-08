// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseSwap.sol";
import "./BytesLib.sol";
import "./SafeERC20.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./IERC20Ext.sol";
import "./IUniswapV2Router02.sol";
import "./UniswapV2Library.sol";

/// General swap for uniswap and its clones
contract UniSwap is BaseSwap {
    using SafeERC20 for IERC20Ext;
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using BytesLib for bytes;

    EnumerableSet.AddressSet private uniRouters;
    address public wEth;
    mapping(address => bytes4) public customSwapFromEth;
    mapping(address => bytes4) public customSwapToEth;

    event UpdatedUniRouters(IUniswapV2Router02[] routers, bool isSupported);

    constructor(
        address _admin,
        IUniswapV2Router02[] memory routers,
        address _weth
    ) BaseSwap(_admin) {
        for (uint256 i = 0; i < routers.length; i++) {
            uniRouters.add(address(routers[i]));
        }
        wEth = _weth;
    }

    function getAllUniRouters() external view returns (address[] memory addresses) {
        uint256 length = uniRouters.length();
        addresses = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            addresses[i] = uniRouters.at(i);
        }
    }

    function updateCustomSwapSelector(
        address _router,
        bytes4 _swapFromEth,
        bytes4 _swapToEth
    ) external onlyAdmin {
        customSwapFromEth[_router] = _swapFromEth;
        customSwapToEth[_router] = _swapToEth;
    }

    function updateUniRouters(IUniswapV2Router02[] calldata routers, bool isSupported)
        external
        onlyAdmin
    {
        for (uint256 i = 0; i < routers.length; i++) {
            if (isSupported) {
                uniRouters.add(address(routers[i]));
            } else {
                uniRouters.remove(address(routers[i]));
            }
        }
        emit UpdatedUniRouters(routers, isSupported);
    }

    /// @dev get expected return and conversion rate if using a Uni router
    function getExpectedReturn(GetExpectedReturnParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 destAmount)
    {
        address router = parseExtraArgs(params.extraArgs);
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(
            params.srcAmount,
            params.tradePath
        );
        destAmount = amounts[params.tradePath.length - 1];
    }

    /// @dev get expected return and conversion rate if using a Uni router
    function getExpectedReturnWithImpact(GetExpectedReturnParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 destAmount, uint256 priceImpact)
    {
        address router = parseExtraArgs(params.extraArgs);
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsOut(
            params.srcAmount,
            params.tradePath
        );
        destAmount = amounts[params.tradePath.length - 1];
        priceImpact = getPriceImpact(
            params.srcAmount,
            destAmount,
            IUniswapV2Router02(router).factory(),
            params.tradePath
        );
    }

    function getExpectedIn(GetExpectedInParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 srcAmount)
    {
        address router = parseExtraArgs(params.extraArgs);
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsIn(
            params.destAmount,
            params.tradePath
        );
        srcAmount = amounts[0];
    }

    function getExpectedInWithImpact(GetExpectedInParams calldata params)
        external
        view
        override
        onlyProxyContract
        returns (uint256 srcAmount, uint256 priceImpact)
    {
        address router = parseExtraArgs(params.extraArgs);
        uint256[] memory amounts = IUniswapV2Router02(router).getAmountsIn(
            params.destAmount,
            params.tradePath
        );
        srcAmount = amounts[0];
        priceImpact = getPriceImpact(
            srcAmount,
            params.destAmount,
            IUniswapV2Router02(router).factory(),
            params.tradePath
        );
    }

    function getPriceImpact(
        uint256 srcAmount,
        uint256 destAmount,
        address factory,
        address[] memory path
    ) private view returns (uint256 priceImpact) {
        uint256 quote = srcAmount;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = UniswapV2Library.getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            quote = UniswapV2Library.quote(quote.mul(997).div(1000), reserveIn, reserveOut);
        }

        if (quote <= destAmount) {
            priceImpact = 0;
        } else {
            priceImpact = quote.sub(destAmount).mul(BPS).div(quote);
        }
    }

    /// @dev swap token via a supported UniSwap router
    /// @notice for some tokens that are paying fee, for example: DGX
    /// contract will trade with received src token amount (after minus fee)
    /// for UniSwap, fee will be taken in src token
    function swap(SwapParams calldata params)
        external
        payable
        override
        onlyProxyContract
        returns (uint256 destAmount)
    {
        require(params.tradePath.length >= 2, "invalid tradePath");

        address router = parseExtraArgs(params.extraArgs);

        safeApproveAllowance(router, IERC20Ext(params.tradePath[0]));

        uint256 tradeLen = params.tradePath.length;
        IERC20Ext actualSrc = IERC20Ext(params.tradePath[0]);
        IERC20Ext actualDest = IERC20Ext(params.tradePath[tradeLen - 1]);

        // convert eth/bnb -> weth/wbnb address to trade on Uni
        address[] memory convertedTradePath = params.tradePath;
        if (convertedTradePath[0] == address(ETH_TOKEN_ADDRESS)) {
            convertedTradePath[0] = wEth;
        }
        if (convertedTradePath[tradeLen - 1] == address(ETH_TOKEN_ADDRESS)) {
            convertedTradePath[tradeLen - 1] = wEth;
        }

        uint256 destBalanceBefore = getBalance(actualDest, params.recipient);

        if (actualSrc == ETH_TOKEN_ADDRESS) {
            // swap eth/bnb -> token
            if (customSwapFromEth[address(router)] != "") {
                (bool success, ) = router.call{value: params.srcAmount}(
                    abi.encodeWithSelector(
                        customSwapFromEth[address(router)],
                        params.minDestAmount,
                        convertedTradePath,
                        params.recipient,
                        MAX_AMOUNT
                    )
                );
                require(success, "swapFromEth: failed");
            } else {
                IUniswapV2Router02(router).swapExactETHForTokensSupportingFeeOnTransferTokens{
                    value: params.srcAmount
                }(params.minDestAmount, convertedTradePath, params.recipient, MAX_AMOUNT);
            }
        } else {
            if (actualDest == ETH_TOKEN_ADDRESS) {
                // swap token -> eth/bnb
                if (customSwapToEth[address(router)] != "") {
                    (bool success, ) = router.call(
                        abi.encodeWithSelector(
                            customSwapToEth[address(router)],
                            params.srcAmount,
                            params.minDestAmount,
                            convertedTradePath,
                            params.recipient,
                            MAX_AMOUNT
                        )
                    );
                    require(success, "swapToEth: failed");
                } else {
                    IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
                        params.srcAmount,
                        params.minDestAmount,
                        convertedTradePath,
                        params.recipient,
                        MAX_AMOUNT
                    );
                }
            } else {
                // swap token -> token
                IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    params.srcAmount,
                    params.minDestAmount,
                    convertedTradePath,
                    params.recipient,
                    MAX_AMOUNT
                );
            }
        }

        destAmount = getBalance(actualDest, params.recipient).sub(destBalanceBefore);
    }

    /// @param extraArgs expecting <[20B] address router>
    function parseExtraArgs(bytes calldata extraArgs) internal view returns (address router) {
        require(extraArgs.length == 20, "invalid args");
        router = extraArgs.toAddress(0);
        require(router != address(0), "invalid address");
        require(uniRouters.contains(router), "unsupported router");
    }
}
