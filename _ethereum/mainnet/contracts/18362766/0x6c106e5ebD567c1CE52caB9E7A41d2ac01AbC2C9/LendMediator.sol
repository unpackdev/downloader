// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LendMediatorStorage.sol";
import "./LendMediatorStorage.sol";
import "./LendMediatorInterface.sol";
import "./LendMediatorInterface.sol";
import "./LendMediatorInterface.sol";
import "./SafeErc20.sol";
import "./ECDSA.sol";
import "./IERC20.sol";
import "./IERC1271.sol";
import "./IERC721Receiver.sol";
import "./IERC165.sol";
import "./INFTFI.sol";
import "./IRepaymentController.sol";
import "./IERC721Transfer.sol";
import "./IBlend.sol";
import "./IBlend.sol";
import "./IBlend.sol";
import "./IBlurPool.sol";

/**
 * @title MetaLend's LendMediator Contract
 * @author MetaLend
 * @notice Manages lending to validated p2p borrowers
 * @dev use this implementation for proxy mediators
 */
contract LendMediator is
    LendMediatorErrorInterface,
    LendMediatorEventInterface,
    LendMediatorFunctionInterface,
    IERC1271,
    IERC721Receiver,
    IERC165,
    LendMediatorProxyStorage,
    LendMediatorStorage
{
    /// @notice revert function if caller is not an owner
    modifier onlyOwner() {
        if (msg.sender != owner) revert ErrCallerNotOwner(msg.sender);
        _;
    }

    /// @notice revert function if caller is not an offer signer (or owner)
    modifier onlyOfferSignerOrOwner() {
        if (msg.sender != lendManager.offerSigner() && msg.sender != owner) revert ErrCallerNotOfferSignerOrOwner(msg.sender);
        _;
    }

    /// @notice refund gas for transaction if sender is offer signer, this allows transactions on behalf of mediator owner
    modifier refundGas() {
        address offerSigner = lendManager.offerSigner();
        if (msg.sender == offerSigner) {
            if (address(this).balance == 0) revert ErrRefundFailed();
            uint256 gasAtStart = gasleft();
            _;
            uint256 gasSpent = gasAtStart - gasleft() + 54832;
            (bool success, ) = offerSigner.call{value: gasSpent * tx.gasprice}("");
            if (!success) revert ErrRefundFailed();
        } else {
            _;
        }
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function depositErc20(address tokenAddress, uint256 amount) external override onlyOwner {
        if (amount == 0) revert ErrInvalidNumber(amount);
        uint256 balanceCurrent = IERC20(tokenAddress).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(tokenAddress), msg.sender, address(this), amount);
        uint256 balanceAfter = IERC20(tokenAddress).balanceOf(address(this));
        uint256 transferredAmount = balanceAfter - balanceCurrent;
        depositedFunds[tokenAddress] += transferredAmount;
        emit FundsDeposited(tokenAddress, transferredAmount);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function liquidateOverdueLoanNftfi(address nftfiAddress, uint32 loanId) external override onlyOwner {
        INFTfi(nftfiAddress).liquidateOverdueLoan(loanId);
        emit OverdueLoanLiquidated(nftfiAddress, uint256(loanId));
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function liquidateOverdueLoanArcade(address repaymentControllerAddress, uint256 loanId) external override onlyOwner {
        IRepaymentController(repaymentControllerAddress).claim(loanId);
        emit OverdueLoanLiquidated(repaymentControllerAddress, loanId);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function liquidateOverdueLoanBlend(
        address blendAddress,
        LienPointer calldata lienPointer
    ) external override refundGas onlyOfferSignerOrOwner {
        LienPointer[] memory lienPointers = new LienPointer[](1);
        lienPointers[0] = lienPointer;
        IBlend(blendAddress).seize(lienPointers);
        emit OverdueLoanLiquidated(blendAddress, lienPointer.lienId);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function takeOverLoanBlend(
        address blendAddress,
        Lien calldata lien,
        uint256 lienId,
        uint256 rate
    ) external override refundGas onlyOfferSignerOrOwner {
        IBlend(blendAddress).refinanceAuction(lien, lienId, rate);
        emit LoanOwnershipClaimed(blendAddress, lienId);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function depositBlurPool(address blurPool) external payable override onlyOwner {
        if (msg.value == 0) revert ErrInvalidNumber(msg.value);
        uint256 balanceCurrent = IBlurPool(blurPool).balanceOf(address(this));
        IBlurPool(blurPool).deposit{value: msg.value}();
        uint256 balanceAfter = IBlurPool(blurPool).balanceOf(address(this));
        uint256 transferredAmount = balanceAfter - balanceCurrent;
        depositedFunds[blurPool] += transferredAmount;
        emit FundsDeposited(blurPool, transferredAmount);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function withdrawBlurPool(address blurPool, uint256 amount) external override onlyOwner {
        if (amount == 0) revert ErrInvalidNumber(amount);

        uint256 amountToWithdraw = amount;
        uint256 royaltiesAmount = _getRoyaltiesAmountWithdrawal(blurPool, amount);

        if (royaltiesAmount > 0) {
            amountToWithdraw -= royaltiesAmount;
        }

        _updateDepositedFundsWithdrawal(blurPool, amountToWithdraw);

        IBlurPool(blurPool).withdraw(amount);

        if (royaltiesAmount > 0) {
            address payable royaltiesReceiver = lendManager.royaltiesReceiver();
            (bool successTransfer1, ) = royaltiesReceiver.call{value: royaltiesAmount}("");
            if (!successTransfer1) revert ErrTransferFailed(royaltiesReceiver, royaltiesAmount);
            emit RoyaltiesWithdrawn(blurPool, royaltiesAmount);
        }

        (bool successTransfer2, ) = owner.call{value: amountToWithdraw}("");
        if (!successTransfer2) revert ErrTransferFailed(owner, amountToWithdraw);
        emit FundsWithdrawn(blurPool, amountToWithdraw);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function startAuctionBlend(
        address blendAddress,
        Lien calldata lien,
        uint256 lienId
    ) external override refundGas onlyOfferSignerOrOwner {
        IBlend(blendAddress).startAuction(lien, lienId);
        emit LoanOwnershipAuctionStarted(blendAddress, lienId);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function redeemErc721(uint256[] calldata tokenIds, address tokenAddress) external override onlyOwner {
        if (tokenIds.length == 0) revert ErrInvalidArrInput();
        IERC721Transfer tokenContract = IERC721Transfer(tokenAddress);
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenContract.safeTransferFrom(address(this), owner, tokenIds[i]);
        }
        emit NftsWithdrawn(tokenAddress, tokenIds);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     * @dev royalties are only taken from the interest earned which is when amount > depositedFunds for the token address
     */
    function withdrawErc20(address tokenAddress, uint256 amount) external override onlyOwner {
        if (amount == 0) revert ErrInvalidNumber(amount);

        uint256 amountToWithdraw = amount;
        uint256 royaltiesAmount = _getRoyaltiesAmountWithdrawal(tokenAddress, amount);

        if (royaltiesAmount > 0) {
            amountToWithdraw -= royaltiesAmount;
        }

        _updateDepositedFundsWithdrawal(tokenAddress, amountToWithdraw);

        if (royaltiesAmount > 0) {
            SafeERC20.safeTransfer(IERC20(tokenAddress), lendManager.royaltiesReceiver(), royaltiesAmount);
            emit RoyaltiesWithdrawn(tokenAddress, royaltiesAmount);
        }

        SafeERC20.safeTransfer(IERC20(tokenAddress), owner, amountToWithdraw);
        emit FundsWithdrawn(tokenAddress, amountToWithdraw);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function approveErc20(address tokenAddress, address approvingContract) external override onlyOwner {
        uint256 allowance = IERC20(tokenAddress).allowance(address(this), approvingContract);
        SafeERC20.safeIncreaseAllowance(IERC20(tokenAddress), approvingContract, type(uint256).max - allowance);
        emit AllowanceModified(tokenAddress, approvingContract, type(uint256).max);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function resetAllowance(address tokenAddress, address approvingContract) external override onlyOwner {
        uint256 allowance = IERC20(tokenAddress).allowance(address(this), approvingContract);
        SafeERC20.safeDecreaseAllowance(IERC20(tokenAddress), approvingContract, allowance);
        emit AllowanceModified(tokenAddress, approvingContract, 0);
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    function withdrawEther(uint256 amount) external override onlyOwner {
        (bool success, ) = owner.call{value: amount}("");
        if (!success) revert ErrTransferFailed(owner, amount);
    }

    /**
     * @notice isValidSignature function implementation
     * @dev returns `0x1626ba7e` if signature belongs to `offerSigner` from LendManager
     * @param hash hash to compare
     * @param signature signature to verify
     */
    function isValidSignature(bytes32 hash, bytes calldata signature) external view override returns (bytes4) {
        address offerSigner = lendManager.offerSigner();
        if (offerSigner == address(0)) return 0xffffffff;
        if (ECDSA.recover(hash, signature) == offerSigner) {
            return 0x1626ba7e;
        } else {
            return 0xffffffff;
        }
    }

    /**
     * @inheritdoc IERC721Receiver
     */
    function onERC721Received(address, address, uint256, bytes memory) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
        return _interfaceId == type(IERC721Receiver).interfaceId || _interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice Gets royalties amount on interest if applicable
     * @dev This function only returns a value and does not process any royalties transfer
     * @param tokenAddress address of the underlying token
     * @param amount the total amount being withdraw, modified by `depositedFunds`
     */
    function _getRoyaltiesAmountWithdrawal(address tokenAddress, uint256 amount) private view returns (uint256 royaltiesAmount) {
        if (
            lendManager.royaltiesPercentage() != 0 && amount > depositedFunds[tokenAddress] && lendManager.royaltiesReceiver() != address(0)
        ) {
            uint256 interestBalanceToWithdraw = amount - depositedFunds[tokenAddress];
            royaltiesAmount = lendManager.getValueByRoyaltiesPercentage(interestBalanceToWithdraw);
        }
    }

    /**
     * @notice Updates `depositedFunds` based on `amountToWithdraw`
     * @dev if `amountToWithdraw` is greater than `depositedFunds[tokenAddress]` `depositedFunds[tokenAddress]` must be set to 0
     * @param tokenAddress address of the underlying token
     * @param amountToWithdraw the withdrawing amount
     */
    function _updateDepositedFundsWithdrawal(address tokenAddress, uint256 amountToWithdraw) private {
        if (amountToWithdraw > depositedFunds[tokenAddress]) {
            depositedFunds[tokenAddress] = 0;
        } else {
            depositedFunds[tokenAddress] -= amountToWithdraw;
        }
    }

    /**
     * @inheritdoc LendMediatorFunctionInterface
     */
    receive() external payable override {}
}
