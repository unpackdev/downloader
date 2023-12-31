// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./INativeRouter.sol";
import "./INativePool.sol";
import "./INativePoolFactory.sol";
import "./SafeCast.sol";
import "./CallbackValidation.sol";
import "./Order.sol";
import "./PeripheryPayments.sol";
import "./TransferHelper.sol";
import "./Multicall.sol";
import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./EIP712Upgradeable.sol";
import "./NativeRouterStorage.sol";
import "./ExternalSwapRouterUpgradeable.sol";

contract NativeRouter is
    INativeRouter,
    PeripheryPayments,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    EIP712Upgradeable,
    Multicall,
    NativeRouterStorage,
    PausableUpgradeable,
    ExternalSwapRouterUpgradeable
{
    using Orders for bytes;
    using SafeCast for uint256;
    uint256 public constant TEN_THOUSAND_DENOMINATOR = 10000;
    // keccak256("NativeSwapCalldata(bytes32 orders,address recipient,address signer,address feeRecipient,uint256 feeRate)")
    bytes32 private constant EXACT_INPUT_SIGNATURE_HASH =
        0x50633b43aed804655952b7d637f3a9e9e37e437639698443e3c5b2136f0885b7;

    struct SwapCallbackData {
        bytes orders;
        address payer;
    }

    event SwapCalculations(uint256 amountIn, address recipient);

    function initialize(address factory, address weth9, address _widgetFeeSigner) public initializer {
        initializeState(factory, weth9);
        __EIP712_init("native router", "1");
        __ReentrancyGuard_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        setWidgetFeeSigner(_widgetFeeSigner);
        __Pausable_init();
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function getImplementation() public view returns (address) {
        return _getImplementation();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setWeth9Unwrapper(address payable _weth9Unwrapper) public override onlyOwner {
        if (_weth9Unwrapper == address(0)) {
            revert ZeroAddressInput();
        }
        weth9Unwrapper = _weth9Unwrapper;
    }

    function setPauser(address _pauser) external onlyOwner {
        pauser = _pauser;
    }

    modifier onlyOwnerOrPauser() {
        if (msg.sender != owner() && msg.sender != pauser) {
            revert onlyOwnerOrPauserCanCall();
        }
        _;
    }

    function pause() external onlyOwnerOrPauser {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setWidgetFeeSigner(address _widgetFeeSigner) public onlyOwner {
        if (_widgetFeeSigner == address(0)) {
            revert ZeroAddressInput();
        }
        widgetFeeSigner = _widgetFeeSigner;
        emit SetWidgetFeeSigner(widgetFeeSigner);
    }

    function swapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override whenNotPaused {
        if (amount0Delta <= 0 && amount1Delta <= 0) {
            revert InvalidDeltaValue(amount0Delta, amount1Delta);
        }
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));

        (Orders.Order memory order, ) = data.orders.decodeFirstOrder();
        if (msg.sender != order.buyer) {
            revert CallbackNotFromOrderBuyer(msg.sender);
        }

        CallbackValidation.verifyCallback(factory, order.buyer);

        uint256 amountToPay = amount0Delta < 0 ? uint256(amount1Delta) : uint256(amount0Delta);
        pay(order.sellerToken, data.payer, msg.sender, amountToPay);
    }

    function setContractCallerWhitelistToggle(bool value) external onlyOwner {
        contractCallerWhitelistEnabled = value;
    }

    function setContractCallerWhitelist(address caller, bool value) external onlyOwner {
        contractCallerWhitelist[caller] = value;
    }

    modifier onlyEOAorWhitelistContract() {
        if (msg.sender != tx.origin && contractCallerWhitelistEnabled && !contractCallerWhitelist[msg.sender]) {
            revert CallerNotEOAAndNotWhitelisted();
        }
        _;
    }

    function exactInputSingle(
        ExactInputParams memory params
    ) external payable override nonReentrant whenNotPaused onlyEOAorWhitelistContract returns (uint256 amountOut) {
        if (params.orders.hasMultiplePools()) {
            revert MultipleOrdersForInputSingle();
        }
        if (params.fallbackSwapDataArray.length > 1) {
            revert MultipleFallbackDataForInputSingle();
        }
        if (!verifyWidgetFeeSignature(params, params.widgetFeeSignature)) {
            revert InvalidWidgetFeeSignature();
        }

        bool hasAlreadyPaid;
        (Orders.Order memory order, ) = params.orders.decodeFirstOrder();
        if (params.amountIn == 0) {
            hasAlreadyPaid = true;
            params.amountIn = IERC20(order.sellerToken).balanceOf(address(this));
        }
        if (params.amountIn <= 0) {
            revert InvalidAmountInValue();
        }
        if (order.caller != msg.sender) {
            revert CallerNotMsgSender(order.caller, msg.sender);
        }

        params.amountIn = processWidgetFee(params, order.sellerToken);

        emit SwapCalculations(params.amountIn, params.recipient);

        amountOut = exactInputInternal(
            params.amountIn,
            params.recipient,
            SwapCallbackData({orders: params.orders, payer: hasAlreadyPaid ? address(this) : msg.sender}),
            params.fallbackSwapDataArray.length > 0 ? params.fallbackSwapDataArray[0] : bytes("")
        );
        if (amountOut < params.amountOutMinimum) {
            revert NotEnoughAmountOut(amountOut, params.amountOutMinimum);
        }

        if (address(this).balance > 0) TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    /// @inheritdoc INativeRouter
    function exactInput(
        ExactInputParams memory params
    ) external payable override nonReentrant whenNotPaused onlyEOAorWhitelistContract returns (uint256 amountOut) {
        if (!verifyWidgetFeeSignature(params, params.widgetFeeSignature)) {
            revert InvalidWidgetFeeSignature();
        }
        bool hasAlreadyPaid;
        (Orders.Order memory order, ) = params.orders.decodeFirstOrder();
        if (params.amountIn == 0) {
            hasAlreadyPaid = true;
            params.amountIn = IERC20(order.sellerToken).balanceOf(address(this));
        }
        if (params.amountIn <= 0) {
            revert InvalidAmountInValue();
        }
        if (order.caller != msg.sender) {
            revert CallerNotMsgSender(order.caller, msg.sender);
        }

        address payer = hasAlreadyPaid ? address(this) : msg.sender;

        params.amountIn = processWidgetFee(params, order.sellerToken);

        emit SwapCalculations(params.amountIn, params.recipient);

        uint256 fallbackSwapDataIdx = 0;
        while (true) {
            bool hasMultiplePools = params.orders.hasMultiplePools();
            bytes memory fallbackSwapData;
            if (order.buyer == ONE_INCH_ROUTER_ADDRESS || order.buyer == UNISWAP_V3_ROUTER_ADDRESS) {
                if (params.fallbackSwapDataArray.length <= fallbackSwapDataIdx) {
                    revert Missing1inchCalldata();
                }
                fallbackSwapData = params.fallbackSwapDataArray[fallbackSwapDataIdx];
                unchecked {
                    fallbackSwapDataIdx++;
                }
            }
            // the outputs of prior swaps become the inputs to subsequent ones
            params.amountIn = exactInputInternal(
                params.amountIn,
                hasMultiplePools ? address(this) : params.recipient,
                SwapCallbackData({
                    orders: params.orders.getFirstOrder(), // only the first pool in the path is necessary
                    payer: payer
                }),
                fallbackSwapData
            );

            // decide whether to continue or terminate
            if (hasMultiplePools) {
                payer = address(this);
                params.orders = params.orders.skipOrder();
                (order, ) = params.orders.decodeFirstOrder();
            } else {
                amountOut = params.amountIn;
                break;
            }
        }

        if (amountOut < params.amountOutMinimum) {
            revert NotEnoughAmountOut(amountOut, params.amountOutMinimum);
        }

        if (address(this).balance > 0) TransferHelper.safeTransferETH(msg.sender, address(this).balance);
    }

    function processWidgetFee(ExactInputParams memory params, address sellerToken) internal returns (uint256) {
        if (params.widgetFee.feeRate > 0) {
            if (params.widgetFee.feeRate > TEN_THOUSAND_DENOMINATOR) {
                revert InvalidWidgetFeeRate();
            }
            uint256 widgetFeeAmount = (params.amountIn * params.widgetFee.feeRate) / TEN_THOUSAND_DENOMINATOR;
            if (msg.value > 0 && sellerToken == WETH9) {
                TransferHelper.safeTransferETH(params.widgetFee.feeRecipient, widgetFeeAmount);
                emit WidgetFeeTransfer(
                    params.widgetFee.feeRecipient,
                    params.widgetFee.feeRate,
                    widgetFeeAmount,
                    address(0)
                );
            } else {
                TransferHelper.safeTransferFrom(
                    sellerToken,
                    msg.sender,
                    params.widgetFee.feeRecipient,
                    widgetFeeAmount
                );
                emit WidgetFeeTransfer(
                    params.widgetFee.feeRecipient,
                    params.widgetFee.feeRate,
                    widgetFeeAmount,
                    sellerToken
                );
            }

            params.amountIn -= widgetFeeAmount;
        }

        return params.amountIn;
    }

    // private methods
    /// @dev Performs a single exact input swap
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        SwapCallbackData memory data,
        bytes memory fallbackSwapData
    ) private returns (uint256 amountOut) {
        (Orders.Order memory order, bytes memory signature) = data.orders.decodeFirstOrder();

        int256 amount0Delta;
        int256 amount1Delta;
        if (INativePoolFactory(factory).verifyPool(order.buyer)) {
            (amount0Delta, amount1Delta) = INativePool(order.buyer).swap(
                abi.encode(order),
                signature,
                amountIn,
                recipient,
                abi.encode(data)
            );
        } else if (order.buyer == PANCAKESWAP_ROUTER_ADDRESS) {
            (amount0Delta, amount1Delta) = swapPancake(order, amountIn, recipient, data.payer);
        } else if (order.buyer == UNISWAP_V3_ROUTER_ADDRESS) {
            uint24 feeTier = uint24(bytes3(fallbackSwapData));
            if (feeTier != 100 && feeTier != 500 && feeTier != 3000 && feeTier != 10000) {
                revert InvalidUniswapV3FeeTierInput(feeTier);
            }
            (amount0Delta, amount1Delta) = swapUniswapV3(order, amountIn, recipient, data.payer, feeTier);
        } else if (order.buyer == ONE_INCH_ROUTER_ADDRESS) {
            if (fallbackSwapData.length <= 0) {
                revert Missing1inchCalldata();
            }
            (amount0Delta, amount1Delta) = swap1inch(order, amountIn, recipient, data.payer, fallbackSwapData);
        } else {
            revert InvalidOrderBuyer();
        }
        return uint256(-(amount0Delta > 0 ? amount1Delta : amount0Delta));
    }

    function getExactInputMessageHash(ExactInputParams memory inputParams) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encode(
                EXACT_INPUT_SIGNATURE_HASH,
                keccak256(inputParams.orders),
                inputParams.recipient,
                inputParams.widgetFee.signer,
                inputParams.widgetFee.feeRecipient,
                inputParams.widgetFee.feeRate
            )
        );
        return hash;
    }

    function verifyWidgetFeeSignature(
        ExactInputParams memory params,
        bytes memory signature
    ) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(getExactInputMessageHash(params));

        address recoveredSigner = ECDSAUpgradeable.recover(digest, signature);
        return widgetFeeSigner == recoveredSigner;
    }

    function sweepToken(address token, uint256 amountMinimum, address recipient) public payable onlyOwner {
        uint256 balanceToken = IERC20Upgradeable(token).balanceOf(address(this));
        if (amountMinimum > balanceToken) {
            revert InsufficientTokenToSweep();
        }

        if (balanceToken > 0) {
            TransferHelper.safeTransfer(token, recipient, balanceToken);
        }
    }

    function refundETHRecipient(address recipient) public payable onlyOwner {
        if (address(this).balance > 0)
            TransferHelper.safeTransferETH(recipient, address(this).balance);
    }

    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable nonReentrant {
        uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));
        require(balanceWETH9 >= amountMinimum, "Insufficient WETH9");

        if (balanceWETH9 > 0) {
            TransferHelper.safeTransfer(WETH9, weth9Unwrapper, balanceWETH9);
            Weth9Unwrapper(weth9Unwrapper).unwrapWeth9(balanceWETH9, recipient);
        }
    }

    function unwrapWETH9(uint256 amountMinimum) external payable nonReentrant {
        unwrapWETH9(amountMinimum, msg.sender);
    }
}
