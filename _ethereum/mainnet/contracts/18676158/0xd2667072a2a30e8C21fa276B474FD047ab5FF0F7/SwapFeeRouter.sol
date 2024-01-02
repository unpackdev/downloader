// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./SafeERC20.sol";

import "./Ownable.sol";

// NOTE: There is no non-arbitrary upper-limit for the `feeBasisPoints`, and setting it above 10_000 just pauses the swap functions.

contract SwapFeeRouter is Ownable {

    error ETHTransferFailed(bytes errorData);
    error FeeBasisPointsNotRespected(uint256 expectedFeeBasisPoints_, uint256 actualFeeBasisPoints_);
    error ContractNotWhitelisted(address callee);
    error RenterAttempted();
    error SwapCallFailed(bytes errorData);

    event ContractAddedToWhitelist(address indexed contract_);
    event ContractRemovedFromWhitelist(address indexed contract_);
    event ETHPulled(address indexed destination_, uint256 amount_);
    event FeeSet(uint256 feeBasisPoints_);
    event TokensPulled(address indexed token_, address indexed destination_, uint256 amount_);

    uint256 internal _locked = 1;

    uint256 public feeBasisPoints;  // 1 = 0.01%, 100 = 1%, 10_000 = 100%

    mapping(address => bool) public isWhitelisted;

    constructor(address owner_, uint256 feeBasisPoints_, address[] memory whitelist_) {
        _setOwner(owner_);
        _setFees(feeBasisPoints_);
        _addToWhitelist(whitelist_);
    }

    modifier noRenter() {
        if (_locked == 2) revert RenterAttempted();

        _locked = 2;

        _;

        _locked = 1;
    }

    modifier feeBasisPointsRespected(uint256 feeBasisPoints_) {
        // Revert if the expected fee is less than the current fee.
        if (feeBasisPoints_ < feeBasisPoints) revert FeeBasisPointsNotRespected(feeBasisPoints_, feeBasisPoints);

        _;
    }

    function swapWithFeesOnInput(
        address inAsset_,
        uint256 swapAmount_,
        uint256 feeBasisPoints_,
        address swapContract_,
        address tokenPuller_,
        bytes calldata swapCallData_
    ) public payable noRenter feeBasisPointsRespected(feeBasisPoints_) {
        // Pull funds plus fees from caller.
        // NOTE: Assuming `swapCallData_` is correct, fees will remain in this contract.
        // NOTE: Worst case, assuming `swapCallData_` is incorrect/malicious, this contract loses nothing, but gains nothing.
        SafeERC20.safeTransferFrom(IERC20(inAsset_), msg.sender, address(this), getAmountWithFees(swapAmount_, feeBasisPoints_));

        // Perform the swap (set allowance, swap, unset allowance).
        // NOTE: This assume that the `swapCallData_` instructs the swapContract to send outAsset to correct destination.
        _performSwap(inAsset_, swapAmount_, swapContract_, tokenPuller_, swapCallData_);
    }

    function swapWithFeesOnOutput(
        address inAsset_,
        uint256 swapAmount_,
        address outAsset_,
        uint256 feeBasisPoints_,
        address swapContract_,
        address tokenPuller_,
        bytes calldata swapCallData_
    ) external noRenter feeBasisPointsRespected(feeBasisPoints_) {
        // Track this contract's starting outAsset balance to determine its increase later.
        uint256 startingOutAssetBalance = IERC20(outAsset_).balanceOf(address(this));

        // Pull funds from caller.
        SafeERC20.safeTransferFrom(IERC20(inAsset_), msg.sender, address(this), swapAmount_);

        // Perform the swap (set allowance, swap, unset allowance).
        // NOTE: This assume that the `swapCallData_` instructs the swapContract to send outAsset to this contract.
        _performSwap(inAsset_, swapAmount_, swapContract_, tokenPuller_, swapCallData_);

        // Send the amount of outAsset the swap produced, minus fees, to the destination.
        SafeERC20.safeTransfer(
            IERC20(outAsset_),
            msg.sender,
            getAmountWithoutFees(
                IERC20(outAsset_).balanceOf(address(this)) - startingOutAssetBalance,
                feeBasisPoints_
            )
        );
    }

    function swapFromEthWithFeesOnInput(
        uint256 feeBasisPoints_,
        address swapContract_,
        bytes calldata swapCallData_
    ) external payable noRenter feeBasisPointsRespected(feeBasisPoints_) {
        // Perform the swap (attaching ETH minus fees to call).
        // NOTE: This assume that the `swapCallData_` instructs the swapContract to send outAsset to correct destination.
        _performSwap(getAmountWithoutFees(msg.value, feeBasisPoints_), swapContract_, swapCallData_);
    }

    function swapFromEthWithFeesOnOutput(
        address outAsset_,
        uint256 feeBasisPoints_,
        address swapContract_,
        bytes calldata swapCallData_
    ) external payable noRenter feeBasisPointsRespected(feeBasisPoints_) {
        // Track this contract's starting outAsset balance to determine its increase later.
        uint256 startingOutAssetBalance = IERC20(outAsset_).balanceOf(address(this));

        // Perform the swap (attaching ETH to call).
        // NOTE: This assume that the `swapCallData_` instructs the swapContract to send outAsset to this contract.
        _performSwap(msg.value, swapContract_, swapCallData_);

        // Send the amount of outAsset the swap produced, minus fees, to the destination.
        SafeERC20.safeTransfer(
            IERC20(outAsset_),
            msg.sender,
            getAmountWithoutFees(
                IERC20(outAsset_).balanceOf(address(this)) - startingOutAssetBalance,
                feeBasisPoints_
            )
        );
    }

    function swapToEthWithFeesOnInput(
        address inAsset_,
        uint256 swapAmount_,
        uint256 feeBasisPoints_,
        address swapContract_,
        address tokenPuller_,
        bytes calldata swapCallData_
    ) external feeBasisPointsRespected(feeBasisPoints_) {
        // NOTE: Ths is functionally the same as `swapWithFeesOnInput` since the output is irrelevant.
        // NOTE: No `noRenter` needed since `swapWithFeesOnInput` will check that.
        swapWithFeesOnInput(inAsset_, swapAmount_, feeBasisPoints_, swapContract_, tokenPuller_, swapCallData_);
    }

    function swapToEthWithFeesOnOutput(
        address inAsset_,
        uint256 swapAmount_,
        uint256 feeBasisPoints_,
        address swapContract_,
        address tokenPuller_,
        bytes calldata swapCallData_
    ) external noRenter feeBasisPointsRespected(feeBasisPoints_) {
        // Track this contract's starting ETH balance to determine its increase later.
        uint256 startingETHBalance = address(this).balance;

        // Pull funds from caller.
        SafeERC20.safeTransferFrom(IERC20(inAsset_), msg.sender, address(this), swapAmount_);

        // Perform the swap (set allowance, swap, unset allowance).
        // NOTE: This assume that the `swapCallData_` instructs the swapContract to send ETH to this contract.
        _performSwap(inAsset_, swapAmount_, swapContract_, tokenPuller_, swapCallData_);

        // Send the amount of ETH the swap produced, minus fees, to the destination, and revert if it fails.
        _transferETH(
            msg.sender,
            getAmountWithoutFees(
                address(this).balance - startingETHBalance,
                feeBasisPoints_
            )
        );
    }

    function addToWhitelist(address[] calldata whitelist_) external onlyOwner {
        _addToWhitelist(whitelist_);
    }

    function removeFromWhitelist(address[] calldata whitelist_) external onlyOwner {
        _removeFromWhitelist(whitelist_);
    }

    function setFee(uint256 feeBasisPoints_) external onlyOwner {
        _setFees(feeBasisPoints_);
    }

    function pullToken(address token_, address destination_) public onlyOwner {
        if (destination_ == address(0)) revert ZeroAddress();

        uint256 amount = IERC20(token_).balanceOf(address(this));

        emit TokensPulled(token_, destination_, amount);

        SafeERC20.safeTransfer(IERC20(token_), destination_, amount);
    }

    function pullTokens(address[] calldata tokens_, address destination_) external onlyOwner {
        for (uint256 i; i < tokens_.length; ++i) {
            pullToken(tokens_[i], destination_);
        }
    }

    function pullETH(address destination_) external onlyOwner {
        if (destination_ == address(0)) revert ZeroAddress();

        uint256 amount = address(this).balance;

        emit ETHPulled(destination_, amount);

        _transferETH(destination_, amount);
    }

    function getAmountWithFees(uint256 amountWithoutFees_, uint256 feeBasisPoints_) public pure returns (uint256 amountWithFees_) {
        amountWithFees_ = (amountWithoutFees_ * (10_000 + feeBasisPoints_)) / 10_000;
    }

    function getAmountWithoutFees(uint256 amountWithFees_, uint256 feeBasisPoints_) public pure returns (uint256 amountWithoutFees_) {
        amountWithoutFees_ = (10_000 * amountWithFees_) / (10_000 + feeBasisPoints_);
    }

    function _addToWhitelist(address[] memory whitelist_) internal {
        for (uint256 i; i < whitelist_.length; ++i) {
            address account = whitelist_[i];
            isWhitelisted[whitelist_[i]] = true;
            emit ContractAddedToWhitelist(account);
        }
    }

    function _performSwap(address inAsset_, uint256 swapAmount_, address swapContract_, address tokenPuller_, bytes calldata swapCallData_) internal {
        // Prevent calling contracts that are not whitelisted.
        if (!isWhitelisted[swapContract_]) revert ContractNotWhitelisted(swapContract_);

        // Approve the contract that will pull inAsset.
        SafeERC20.forceApprove(IERC20(inAsset_), tokenPuller_, swapAmount_);

        // Call the swap contract as defined by `swapCallData_`, and revert if it fails.
        ( bool success, bytes memory errorData ) = swapContract_.call{ value: msg.value }(swapCallData_);
        if (!success) revert SwapCallFailed(errorData);

        // Un-approve the contract that pulled inAsset.
        // NOTE: This is important to prevent exploits that rely on allowances to arbitrary swapContracts to be non-zero after swap calls.
        SafeERC20.forceApprove(IERC20(inAsset_), tokenPuller_, 0);
    }

    function _performSwap(uint256 swapAmount_, address swapContract_, bytes calldata swapCallData_) internal {
        // Prevent calling contracts that are not whitelisted.
        if (!isWhitelisted[swapContract_]) revert ContractNotWhitelisted(swapContract_);

        // Call the swap contract as defined by `swapCallData_`, and revert if it fails.
        ( bool success, bytes memory errorData ) = swapContract_.call{ value: swapAmount_ }(swapCallData_);
        if (!success) revert SwapCallFailed(errorData);
    }

    function _removeFromWhitelist(address[] memory whitelist_) internal {
        for (uint256 i; i < whitelist_.length; ++i) {
            address account = whitelist_[i];
            isWhitelisted[whitelist_[i]] = false;
            emit ContractRemovedFromWhitelist(account);
        }
    }

    function _setFees(uint256 feeBasisPoints_) internal {
        emit FeeSet(feeBasisPoints = feeBasisPoints_);
    }

    function _transferETH(address destination_, uint256 amount_) internal {
        // NOTE: callers of this function are validating `destination_` to not be zero.
        ( bool success, bytes memory errorData ) = destination_.call{ value: amount_ }("");
        if (!success) revert ETHTransferFailed(errorData);
    }

    receive() external payable {}

}
