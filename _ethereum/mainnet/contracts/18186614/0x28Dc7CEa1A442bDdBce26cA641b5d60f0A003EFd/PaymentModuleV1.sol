// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AccessControlEnumerable.sol";
import "./IERC1155.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

import "./IDepositHandler.sol";
import "./ILPTokenProcessorV2.sol";
import "./IPaymentModule.sol";
import "./IPricingModule.sol";
import "./INonfungiblePositionManager.sol";
import "./IPriceOracleManager.sol";
import "./ISwapRouterV3.sol";
import "./IUniswapPair.sol";

contract PaymentModuleV1 is IDepositHandler, IPaymentModule, AccessControlEnumerable, IERC721Receiver {
    using SafeERC20 for IERC20Metadata;

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    bytes32 public constant PAYMENT_ADMIN_ROLE = keccak256("PAYMENT_ADMIN_ROLE");
    address public FLOKI;
    IERC20Metadata public USDT;

    ILPTokenProcessorV2 public lpTokenProcessor;
    IPricingModule public pricingModule;
    IPriceOracleManager public priceOracle;
    address public mainRouter;
    bool public isV2Router;
    address public nativeWrappedToken;
    uint24 public v3PoolFeeForUsdNative = 3000;
    uint24 public v3PoolFeeForFlokiNative = 3000;
    address public treasury;
    bool public convertNativeFeeToUsd = true;

    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant referrerBasisPoints = 2500; // 25%
    uint256 public constant burnBasisPoints = 2500; // 25%

    uint256 public feeCollectedLastBlock;
    uint256 public flokiBurnedLastBlock;
    uint256 public referrerShareLastBlock;

    event LPTokenProcessorUpdated(address indexed oldProcessor, address indexed newProcessor);
    event PriceOracleManagerUpdated(address indexed oldOracle, address indexed newOracle);
    event PricingModuleUpdated(address indexed oldModule, address indexed newModule);
    event TreasuryAddressUpdated(address indexed oldTreasury, address indexed newTreasury);
    event FeeCollected(uint256 indexed previousBlock, address indexed vault, uint256 usdAmount);
    event ReferrerSharePaid(uint256 indexed previousBlock, address indexed vault, address referrer, uint256 usdAmount);
    event FlokiBurned(uint256 indexed previousBlock, address indexed vault, uint256 usdAmount, uint256 flokiAmount);
    event V3PoolFeeForUsdUpdated(uint24 indexed oldFee, uint24 indexed newFee);
    event V3PoolFeeForFlokiUpdated(uint24 indexed oldFee, uint24 indexed newFee);
    event RouterUpdated(address indexed oldRouter, address indexed newRouter, bool isV3Router);
    event UsdTokenUpdated(address indexed oldUsd, address indexed newUsd);
    event SlippageUpdated(uint256 indexed oldSlippage, uint256 indexed newSlippage);

    constructor(
        address flokiAddress,
        address lpTokenProcessorAddress,
        address pricingModuleAddress,
        address treasuryAddress,
        address routerAddress,
        bool v2Router,
        address priceOracleAddress,
        address usdAddress
    ) {
        require(pricingModuleAddress != address(0), "PaymentModuleV1::constructor::ZERO: Pricing module cannot be zero address.");
        require(routerAddress != address(0), "PaymentModuleV1::constructor::ZERO: Router cannot be zero address.");

        FLOKI = flokiAddress;
        pricingModule = IPricingModule(pricingModuleAddress);
        lpTokenProcessor = ILPTokenProcessorV2(lpTokenProcessorAddress);
        priceOracle = IPriceOracleManager(priceOracleAddress);
        mainRouter = routerAddress;
        isV2Router = v2Router;
        treasury = treasuryAddress;
        USDT = IERC20Metadata(usdAddress);
        nativeWrappedToken = _getNativeWrappedToken();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
    Deprecated. Kept for compatibility with existing clients.
     */
    function routerForFloki() external view returns (address) {
        return mainRouter;
    }

    function processPayment(ProcessPaymentParams memory params) external payable override onlyRole(PAYMENT_ADMIN_ROLE) {
        IPricingModule.PriceInfo memory price = pricingModule.getPrice(
            params.user,
            params.fungibleTokenDeposits,
            params.nonFungibleTokenDeposits,
            params.multiTokenDeposits,
            params.isVesting
        );

        // Process ERC20 token payments first.
        _processErc20(params, price);

        // Process NFT
        _processNfts(params, price);

        // Process Multi Token
        _processMultiToken(params);

        // Process fees.
        uint256 weiToBeRefunded = 0;
        if (convertNativeFeeToUsd || msg.value == 0) {
            weiToBeRefunded = _processFee(price.usdtAmount, params.user, params.referrer, params.vault);
        } else {
            weiToBeRefunded = _processNativeFees(price.usdtAmount, params.referrer, params.vault);
        }
        (bool success, ) = payable(params.user).call{ value: weiToBeRefunded }("");
        require(success, "Failed to refund leftover ETH");
    }

    function _getNativeWrappedToken() private view returns (address) {
        if (isV2Router) {
            return IUniswapV2Router02(mainRouter).WETH();
        } else {
            return ISwapRouterV3(mainRouter).WETH9();
        }
    }

    function _processErc20(ProcessPaymentParams memory params, IPricingModule.PriceInfo memory price) private {
        for (uint256 i = 0; i < params.fungibleTokenDeposits.length; i++) {
            // First transfer the full sum of the tokens to the payment processor.
            uint256 initialBalance = IERC20Metadata(params.fungibleTokenDeposits[i].tokenAddress).balanceOf(address(this));
            IERC20Metadata(params.fungibleTokenDeposits[i].tokenAddress).safeTransferFrom(params.user, address(this), params.fungibleTokenDeposits[i].amount);
            uint256 receivedAmount = IERC20Metadata(params.fungibleTokenDeposits[i].tokenAddress).balanceOf(address(this)) - initialBalance;
            // Then transfer tokens that are to be locked to the vault (lpV2Tokens[i] is zero for non-LP tokens).
            IERC20Metadata(params.fungibleTokenDeposits[i].tokenAddress).safeTransfer(params.vault, receivedAmount - price.v2LpAmounts[i]);
            if (params.fungibleTokenDeposits[i].tokenAddress == price.v2LpTokens[i]) {
                // It's important to know that these subtractions never
                // cause an underflow. The number in `lpV2Amounts[i]` is
                // non-zero after the transfer to the vault.
                IERC20Metadata(params.fungibleTokenDeposits[i].tokenAddress).safeApprove(address(lpTokenProcessor), price.v2LpAmounts[i]);
                // Send LP tokens to the Keepers-powered LP token processor.
                // The LP token processor will take care of liquidating, swapping for USD token and paying referrers.
                lpTokenProcessor.addTokenForSwapping(
                    ILPTokenProcessorV2.TokenSwapInfo({
                        tokenAddress: params.fungibleTokenDeposits[i].tokenAddress,
                        routerFactory: _factory(params.fungibleTokenDeposits[i].tokenAddress),
                        isV2: true,
                        referrer: params.referrer,
                        vault: params.vault,
                        amount: price.v2LpAmounts[i],
                        v3PoolFee: 0
                    })
                );
            }
        }
    }

    function _processNfts(ProcessPaymentParams memory params, IPricingModule.PriceInfo memory price) private {
        for (uint256 i = 0; i < params.nonFungibleTokenDeposits.length; i++) {
            // First, transfer the tokens to the payment processor.
            IERC721(params.nonFungibleTokenDeposits[i].tokenAddress).safeTransferFrom(params.user, address(this), params.nonFungibleTokenDeposits[i].tokenId);
            if (params.nonFungibleTokenDeposits[i].tokenAddress == price.v3LpTokens[i].tokenAddress) {
                // For V3 LP positions, we need to remove our share of the liquidity
                // amount0Min and amount1Min are price slippage checks
                // if the amount received after burning is not greater than these minimums, transaction will fail
                require(price.v3LpTokens[i].liquidityToRemove > 0, "PaymentModuleV1::processPayment::ZERO: Liquidity to remove cannot be zero.");

                uint256 initialBalance0 = IERC20Metadata(price.v3LpTokens[i].token0).balanceOf(address(this));
                uint256 initialBalance1 = IERC20Metadata(price.v3LpTokens[i].token1).balanceOf(address(this));
                INonfungiblePositionManager(price.v3LpTokens[i].tokenAddress).decreaseLiquidity(
                    INonfungiblePositionManager.DecreaseLiquidityParams({
                        tokenId: params.nonFungibleTokenDeposits[i].tokenId,
                        liquidity: price.v3LpTokens[i].liquidityToRemove,
                        amount0Min: 0,
                        amount1Min: 0,
                        deadline: block.timestamp
                    })
                );
                INonfungiblePositionManager(price.v3LpTokens[i].tokenAddress).collect(
                    INonfungiblePositionManager.CollectParams({
                        tokenId: params.nonFungibleTokenDeposits[i].tokenId,
                        recipient: address(this),
                        amount0Max: type(uint128).max,
                        amount1Max: type(uint128).max
                    })
                );
                // Send unpaired tokens to the Keepers-powered LP token processor.
                // The LP token processor will take care of liquidating, swapping for USD token and paying referrers.
                uint256 amount0Received = IERC20Metadata(price.v3LpTokens[i].token0).balanceOf(address(this)) - initialBalance0;
                uint256 amount1Received = IERC20Metadata(price.v3LpTokens[i].token1).balanceOf(address(this)) - initialBalance1;
                address factory = INonfungiblePositionManager(price.v3LpTokens[i].tokenAddress).factory();
                // Approve tokens to LP Token Processor
                IERC20Metadata(price.v3LpTokens[i].token0).safeApprove(address(lpTokenProcessor), amount0Received);
                IERC20Metadata(price.v3LpTokens[i].token1).safeApprove(address(lpTokenProcessor), amount1Received);

                lpTokenProcessor.addTokenForSwapping(
                    ILPTokenProcessorV2.TokenSwapInfo({
                        tokenAddress: price.v3LpTokens[i].token0,
                        routerFactory: factory,
                        isV2: false,
                        referrer: params.referrer,
                        vault: params.vault,
                        amount: amount0Received,
                        v3PoolFee: price.v3LpTokens[i].fee
                    })
                );
                lpTokenProcessor.addTokenForSwapping(
                    ILPTokenProcessorV2.TokenSwapInfo({
                        tokenAddress: price.v3LpTokens[i].token1,
                        routerFactory: factory,
                        isV2: false,
                        referrer: params.referrer,
                        vault: params.vault,
                        amount: amount1Received,
                        v3PoolFee: price.v3LpTokens[i].fee
                    })
                );
            }
            IERC721(params.nonFungibleTokenDeposits[i].tokenAddress).safeTransferFrom(address(this), params.vault, params.nonFungibleTokenDeposits[i].tokenId);
        }
    }

    function _processMultiToken(ProcessPaymentParams memory params) private {
        for (uint256 i = 0; i < params.multiTokenDeposits.length; i++) {
            IERC1155(params.multiTokenDeposits[i].tokenAddress).safeTransferFrom(
                params.user,
                params.vault,
                params.multiTokenDeposits[i].tokenId,
                params.multiTokenDeposits[i].amount,
                ""
            );
        }
    }

    function _factory(address lpTokenAddress) private view returns (address) {
        try IUniswapPair(lpTokenAddress).factory() returns (address factory) {
            return factory;
        } catch {
            return address(0);
        }
    }

    function _processFee(
        uint256 usdAmount,
        address user,
        address referrer,
        address vault
    ) private returns (uint256 weiToBeRefunded) {
        require(address(USDT) != address(0), "PaymentModuleV1::processPayment::ZERO: USD payments not enabled.");
        if (usdAmount > 0) {
            uint256 initialUsdBalance = USDT.balanceOf(address(this));
            if (msg.value > 0) {
                // if user is paying with native token, we swap it by USDT
                weiToBeRefunded = _swapNativeToUsd(usdAmount);
            } else {
                USDT.safeTransferFrom(user, address(this), usdAmount);
            }
            uint256 newUsdBalance = USDT.balanceOf(address(this));
            uint256 usdEarned = newUsdBalance - initialUsdBalance;
            require(usdEarned >= usdAmount, "Not enough USD received to cover fees. USD token must not have transfer fees.");

            uint256 treasuryUsdShare = usdAmount;
            if (referrer != address(0)) {
                uint256 referrerUSDTShare = (usdAmount * referrerBasisPoints) / BASIS_POINTS;
                USDT.safeTransfer(referrer, referrerUSDTShare);
                treasuryUsdShare -= referrerUSDTShare;
                emit ReferrerSharePaid(referrerShareLastBlock, vault, referrer, referrerUSDTShare);
                referrerShareLastBlock = block.number;
            }

            if (FLOKI != address(0)) {
                uint256 burnShare = (usdAmount * burnBasisPoints) / BASIS_POINTS;
                uint256 flokiBalance = IERC20Metadata(FLOKI).balanceOf(burnAddress);
                USDT.safeApprove(address(lpTokenProcessor), burnShare);
                bool success = lpTokenProcessor.swapTokens(address(USDT), burnShare, FLOKI, burnAddress, mainRouter, _getV3PoolFees());
                treasuryUsdShare -= burnShare;
                require(success, "Swap failed");
                uint256 flokiBurned = IERC20Metadata(FLOKI).balanceOf(burnAddress) - flokiBalance;
                emit FlokiBurned(flokiBurnedLastBlock, vault, burnShare, flokiBurned);
                flokiBurnedLastBlock = block.number;
            }
            USDT.safeTransfer(treasury, treasuryUsdShare);
            emit FeeCollected(feeCollectedLastBlock, vault, treasuryUsdShare);
            feeCollectedLastBlock = block.number;
        }
    }

    function _getV3PoolFees() private view returns (uint24[] memory) {
        uint24[] memory fees = new uint24[](2);
        fees[0] = v3PoolFeeForUsdNative;
        fees[1] = v3PoolFeeForFlokiNative;
        return fees;
    }

    function _processNativeFees(
        uint256 usdAmount,
        address referrer,
        address vault
    ) private returns (uint256 weiToBeRefunded) {
        priceOracle.fetchPriceInUSD(nativeWrappedToken);
        uint256 price = priceOracle.getPriceInUSD(nativeWrappedToken, pricingModule.priceDecimals());
        require(price > 0, "PaymentModuleV1::processPayment::INVALID: Price from oracle is unavailable.");
        uint256 expectedWei = (usdAmount * 1 ether) / price;
        require(msg.value >= expectedWei, "PaymentModuleV1::processPayment::INVALID: Not enough Native Tokens sent to cover fees.");
        weiToBeRefunded = msg.value - expectedWei;

        if (referrer != address(0)) {
            uint256 referrerWeiShare = (expectedWei * referrerBasisPoints) / BASIS_POINTS;
            (bool referrerSucceeded, ) = payable(referrer).call{ value: referrerWeiShare }("");
            require(referrerSucceeded, "Failed to send native share to referrer.");
            expectedWei -= referrerWeiShare;
            uint256 usdReferrerShare = (usdAmount * referrerBasisPoints) / BASIS_POINTS;
            usdAmount -= usdReferrerShare;
            emit ReferrerSharePaid(referrerShareLastBlock, vault, referrer, usdReferrerShare);
            referrerShareLastBlock = block.number;
        }
        (bool success, ) = payable(treasury).call{ value: expectedWei }("");
        require(success, "Failed to send native token to treasury.");
        emit FeeCollected(feeCollectedLastBlock, vault, usdAmount);
        feeCollectedLastBlock = block.number;

        return weiToBeRefunded;
    }

    function _swapNativeToUsd(uint256 usdAmount) private returns (uint256 weiToBeRefunded) {
        uint256 oldEthBalance = address(this).balance;
        if (isV2Router) {
            address[] memory path = new address[](2);
            path[0] = IUniswapV2Router02(mainRouter).WETH();
            path[1] = address(USDT);
            IUniswapV2Router02(mainRouter).swapETHForExactTokens{ value: msg.value }(usdAmount, path, address(this), block.timestamp);
        } else {
            ISwapRouterV3.ExactOutputSingleParams memory params = ISwapRouterV3.ExactOutputSingleParams({
                tokenIn: ISwapRouterV3(mainRouter).WETH9(),
                tokenOut: address(USDT),
                fee: v3PoolFeeForUsdNative,
                recipient: address(this),
                amountOut: usdAmount,
                amountInMaximum: msg.value,
                sqrtPriceLimitX96: 0
            });
            ISwapRouterV3(mainRouter).exactOutputSingle{ value: msg.value }(params);
        }
        // refund any extra ETH sent
        weiToBeRefunded = msg.value - (oldEthBalance - address(this).balance);
    }

    function setConvertNativeFeeToUsd(bool _convertNativeFeeToUsd) external onlyRole(DEFAULT_ADMIN_ROLE) {
        convertNativeFeeToUsd = _convertNativeFeeToUsd;
    }

    function setFloki(address _floki) external onlyRole(DEFAULT_ADMIN_ROLE) {
        FLOKI = _floki;
    }

    function setUsdToken(address newUsdToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newUsdToken != address(0), "LPTokenProcessorV2::setUsdToken::ZERO: USDT cannot be zero address.");
        address oldUsdToken = address(USDT);
        USDT = IERC20Metadata(newUsdToken);
        emit UsdTokenUpdated(oldUsdToken, newUsdToken);
    }

    function setLPTokenProcessor(address newProcessor) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldProcessor = address(lpTokenProcessor);
        lpTokenProcessor = ILPTokenProcessorV2(newProcessor);
        emit LPTokenProcessorUpdated(oldProcessor, newProcessor);
    }

    function setPriceOracleManager(address priceOracleAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldPriceOracle = address(priceOracle);
        priceOracle = IPriceOracleManager(priceOracleAddress);
        emit PriceOracleManagerUpdated(oldPriceOracle, priceOracleAddress);
    }

    function setPricingModule(address newModule) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldModule = address(pricingModule);
        pricingModule = IPricingModule(newModule);
        emit PricingModuleUpdated(oldModule, newModule);
    }

    function setRouter(address newRouter, bool v2Router) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldRouter = mainRouter;
        mainRouter = newRouter;
        isV2Router = v2Router;
        nativeWrappedToken = _getNativeWrappedToken();
        emit RouterUpdated(oldRouter, newRouter, v2Router);
    }

    function setV3PoolFeeForUsd(uint24 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint24 oldFee = v3PoolFeeForUsdNative;
        v3PoolFeeForUsdNative = newFee;
        emit V3PoolFeeForUsdUpdated(oldFee, newFee);
    }

    function setV3PoolFeeForFloki(uint24 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint24 oldFee = v3PoolFeeForFlokiNative;
        v3PoolFeeForFlokiNative = newFee;
        emit V3PoolFeeForFlokiUpdated(oldFee, newFee);
    }

    function setTreasury(address newTreasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldTreasury = treasury;
        treasury = newTreasury;

        emit TreasuryAddressUpdated(oldTreasury, newTreasury);
    }

    function adminWithdraw(address tokenAddress, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenAddress == address(0)) {
            // We specifically ignore this return value.
            (bool success, ) = payable(treasury).call{ value: amount }("");
            require(success, "Failed to withdraw ETH");
        } else {
            IERC20Metadata(tokenAddress).safeTransfer(treasury, amount);
        }
    }

    function notifyFeeCollected(address _vault, uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit FeeCollected(feeCollectedLastBlock, _vault, _amount);
        feeCollectedLastBlock = block.number;
    }

    function notifyFlokiBurned(
        address _vault,
        uint256 _usdAmount,
        uint256 _flokiAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit FlokiBurned(flokiBurnedLastBlock, _vault, _usdAmount, _flokiAmount);
        flokiBurnedLastBlock = block.number;
    }

    function notifyReferrerSharePaid(
        address _vault,
        address _referrer,
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit ReferrerSharePaid(referrerShareLastBlock, _vault, _referrer, _amount);
        referrerShareLastBlock = block.number;
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
