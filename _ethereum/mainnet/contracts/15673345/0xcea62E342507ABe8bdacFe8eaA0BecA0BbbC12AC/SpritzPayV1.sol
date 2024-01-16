// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "./AccessControlEnumerableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";
import "./IUniswapV2Router02.sol";

import "./SpritzPayStorage.sol";

/**
 * @title SpritzPayV1
 * @notice Main entry point for Spritz payments
 */
contract SpritzPayV1 is
    Initializable,
    PausableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable,
    SpritzPayStorage
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    error FailedTokenTransfer(address tokenAddress, address to, uint256 amount);

    error FailedSwap(
        address sourceTokenAddress,
        uint256 sourceTokenAmount,
        address paymentTokenAddress,
        uint256 paymentTokenAmount
    );

    error FailedRefund(address tokenAddress, uint256 amount);

    /**
     * @dev Emitted when a payment has been sent
     */
    event Payment(
        address to,
        address indexed from,
        address indexed sourceToken,
        uint256 sourceTokenAmount,
        address paymentToken,
        uint256 paymentTokenAmount,
        bytes32 indexed paymentReference
    );

    /**
     * @dev Constructor for upgradable contract
     */
    function initialize(
        address _admin,
        address _paymentRecipient,
        address _swapTarget,
        address _wrappedNative,
        address[] calldata _acceptedTokens
    ) public virtual initializer {
        __SpritzPayStorage_init(_admin, _paymentRecipient, _swapTarget, _wrappedNative, _acceptedTokens);
        __Pausable_init();
        __AccessControlEnumerable_init();
        __ReentrancyGuard_init();
    }

    /**
     * @notice Pay by direct stablecoin transfer
     * @param paymentTokenAddress Address of the target payment token
     * @param paymentTokenAmount Payment amount, denominated in target payment token
     * @param paymentReference Arbitrary reference ID of the related payment
     */
    function payWithToken(
        address paymentTokenAddress,
        uint256 paymentTokenAmount,
        bytes32 paymentReference
    ) external whenNotPaused onlyAcceptedToken(paymentTokenAddress) {
        emit Payment(
            _paymentRecipient,
            msg.sender,
            paymentTokenAddress,
            paymentTokenAmount,
            paymentTokenAddress,
            paymentTokenAmount,
            paymentReference
        );

        IERC20Upgradeable(paymentTokenAddress).safeTransferFrom(msg.sender, _paymentRecipient, paymentTokenAmount);
    }

    /**
     * @notice Pay by swapping token or with native currency, using uniswapv2 as swap provider. Uses
     *          Uniswap exact output trade type
     * @param path Swap path
     * @param sourceTokenAmountMax Maximum amount of the token being sold for payment
     * @param paymentTokenAmount Exact Amount of the target payment token
     * @param paymentReference Arbitrary reference ID of the related payment
     * @param deadline Swap deadline
     */
    function payWithSwap(
        address[] calldata path,
        uint256 sourceTokenAmountMax,
        uint256 paymentTokenAmount,
        bytes32 paymentReference,
        uint256 deadline
    ) external payable whenNotPaused nonReentrant {
        address sourceTokenAddress = path[0];
        address paymentTokenAddress = path[path.length - 1];

        if(!isAcceptedToken(paymentTokenAddress)) {
            revert NonAcceptedToken(paymentTokenAddress);
        }

        IERC20Upgradeable sourceToken = IERC20Upgradeable(sourceTokenAddress);
        bool isNativeSwap = sourceTokenAddress == _wrappedNative;

        // If swap involves non-native token, transfer token in, and grant allowance to
        // the swap router
        if (!isNativeSwap) {
            //Ensure our contract gives sufficient allowance to swap target
            uint256 allowance = sourceToken.allowance(address(this), _swapTarget);
            if (allowance < sourceTokenAmountMax) {
                sourceToken.safeIncreaseAllowance(_swapTarget, 2**256 - 1 - allowance);
            }

            //Transfer from user to our contract
            sourceToken.safeTransferFrom(msg.sender, address(this), sourceTokenAmountMax);
        }

        uint256[] memory amounts;

        {
            //Execute the swap
            IUniswapV2Router02 router = IUniswapV2Router02(_swapTarget);
            if (!isNativeSwap) {
                amounts = router.swapTokensForExactTokens(
                    paymentTokenAmount,
                    sourceTokenAmountMax,
                    path,
                    _paymentRecipient,
                    deadline
                );
            } else {
                amounts = router.swapETHForExactTokens{ value: msg.value }(
                    paymentTokenAmount,
                    path,
                    _paymentRecipient,
                    deadline
                );
            }
        }

        uint256 sourceTokenSpentAmount = amounts[0];

        emit Payment(
            _paymentRecipient,
            msg.sender,
            sourceTokenAddress,
            sourceTokenSpentAmount,
            paymentTokenAddress,
            paymentTokenAmount,
            paymentReference
        );

        //Refund remaining balance left after the swap to the user
        uint256 remainingBalance = sourceTokenAmountMax - sourceTokenSpentAmount;
        if (remainingBalance > 0) {
            bool refundSuccess = isNativeSwap
                ? payable(msg.sender).send(remainingBalance)
                : sourceToken.transfer(msg.sender, remainingBalance);

            if (!refundSuccess) {
                revert FailedRefund({ tokenAddress: sourceTokenAddress, amount: remainingBalance });
            }
        }
    }

    /*
     * Admin functions
     */

    receive() external payable {}

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setPaymentRecipient(address newPaymentRecipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setPaymentRecipient(newPaymentRecipient);
    }

    function addPaymentToken(address newToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addPaymentToken(newToken);
    }

    function removePaymentToken(address newToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _removePaymentToken(newToken);
    }
}
