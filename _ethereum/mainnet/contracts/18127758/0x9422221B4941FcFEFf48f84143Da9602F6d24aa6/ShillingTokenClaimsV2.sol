// SPDX-License-Identifier: CC0
// Copyright (c) 2022 unReal Accelerator, LLC (https://unrealaccelerator.io)
pragma solidity ^0.8.19;

/**
 * @title ShillingTokenClaimsV2
 * @dev A contract for managing claims of Shilling tokens from staking contracts.
 * @author jason@unrealaccelerator.io
 */

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./AllowedEvaluator.sol";
import "./IStakingForClaims.sol";

contract ShillingTokenClaimsV2 is ReentrancyGuard, Ownable, AllowedEvaluator {
    IERC20 public tokenContract; // ERC20 token contract for Shilling tokens
    IStakingForClaims public stakingCOKContract; // Staking contract for COK tokens
    IStakingForClaims public stakingHCOKContract; // Staking contract for HCOK tokens

    uint256 public ethPerThreeShillings = 0.22 ether; // Default eth amount for 3 shilling

    // mapping to track claimed amounts per address
    mapping(address => bool) public addressClaimed;

    ///////// Security

    address public administrator; // Address with administrative privileges
    bool public claimAllowed; // Used to control claim events
    bool public purchaseAllowed; // Used to control shilling purchase events

    ///////// Errors

    error NotAuthorized(); // Error thrown when caller is not authorized
    error NoBalanceToWithdraw(); // Error thrown when attempting to withdraw with no balance
    error ClaimNotAllowed(); // Error thrown with attempting to claim but claiming is not allowed
    error ClaimNotValid(); // Error thrown with attempting to claim but claiming is not allowed
    error InvalidNumberOfTokens();
    error PurchaseNotAllowed();
    error AddressAlreadyClaimed();
    error InsufficientTokens();
    error IncorrectAmountOfETH();

    /////////  Events

    event ClaimAllowed(bool indexed state);
    event PurchaseAllowed(bool indexed state);
    event Claimed(address indexed user, uint256 amount);
    event ClaimsPurchased(
        address indexed user,
        uint256 amount,
        uint256 totalEth
    );

    ///////// Modifiers

    /**
     * @dev Modifier to check for authorized roles (Owner or Administrator)
     */
    modifier onlyAuthorized() {
        validateAuthorized();
        _;
    }

    function validateAuthorized() private view {
        if (_msgSender() != owner() && _msgSender() != administrator)
            revert NotAuthorized();
    }

    /**
     * @dev Constructor to initialize the contract with required addresses.
     * @param tokenContract_ Address of the Shilling token contract.
     * @param stakingCOKContract_ Address of the staking contract for COK tokens.
     * @param stakingHCOKContract_ Address of the staking contract for HCOK tokens.
     * @param administrator_ Address with administrative privileges.
     */
    constructor(
        address tokenContract_,
        address stakingCOKContract_,
        address stakingHCOKContract_,
        address administrator_
    ) {
        tokenContract = IERC20(tokenContract_);
        stakingCOKContract = IStakingForClaims(stakingCOKContract_);
        stakingHCOKContract = IStakingForClaims(stakingHCOKContract_);
        administrator = administrator_;
    }

    /**
     * @dev Fallback function to receive Ether.
     * This function is payable and allows the contract to receive ETH.
     */
    receive() external payable {}

    /**
     * @dev Get the current supply of Shilling tokens held by the contract.
     * @return The balance of Shilling tokens held by the contract.
     */
    function shillingSupply() external view returns (uint256) {
        return uint256(tokenContract.balanceOf(address(this)));
    }

    /**
     * @dev Calculates the total number of allowed claims.
     * @param account The address of the account to check allowed claims for.
     * @return The number of allowed claims.
     */
    function allowedClaims(address account) public view returns (uint256) {
        return (allowedClaimsWithCOK(account) + allowedClaimsWithHCOK(account));
    }

    /**
     * @dev Calculates the number of allowed claims based on the staked COK balance.
     * @param account The address of the account to check allowed claims for.
     * @return The number of allowed claims. Each staked COK token grants 1 claim, rounded down to the nearest multiple of 3.
     */
    function allowedClaimsWithCOK(
        address account
    ) public view returns (uint256) {
        uint256 balance = stakingCOKContract.balanceOf(account);
        // 1 claim per staked COK; but only in multiples of 3
        uint256 claims = (balance / 3) * 3;
        return claims;
    }

    /**
     * @dev Get the number of allowed claims for an account using the stakingHCOKContract.
     * @param account The address of the account to check allowed claims for.
     * @return The number of allowed claims based on the staked HCOK balance.
     */
    function allowedClaimsWithHCOK(
        address account
    ) public view returns (uint256) {
        return (stakingHCOKContract.balanceOf(account) * 9);
    }

    function claim(
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external nonReentrant {
        if (
            !AllowedEvaluator._validateMerkleProof(
                index,
                _msgSender(),
                amount,
                merkleProof
            )
        ) revert ClaimNotValid();

        // Ensure the address has not already claimed
        if (addressClaimed[_msgSender()]) revert AddressAlreadyClaimed();

        // Ensure claiming is allowed
        if (!claimAllowed) revert ClaimNotAllowed();

        // Calculate the balance of the contract's token holdings
        uint256 balance = uint256(tokenContract.balanceOf(address(this)));

        // Calculate the reward to be transferred to the account in wei
        uint256 rewardWei = amount * 10 ** 18;

        // Ensure the contract has sufficient tokens to cover the reward
        if (rewardWei > balance) revert InsufficientTokens();

        // Transfer the reward tokens to the account
        tokenContract.transfer(_msgSender(), rewardWei);

        // Set that the address has made their claims
        addressClaimed[_msgSender()] = true;

        // Emit a Claimed event to indicate a successful claim
        emit Claimed(_msgSender(), amount);
    }

    /**
     * @dev Allows an account to purchase rewards using ETH.
     * The function checks if claiming is allowed, calculates the number of claims that can be purchased,
     * verifies that the number of claims is a multiple of 3, calculates the total ETH required,
     * transfers the ETH to the contract, and emits a `ClaimsPurchased` event.
     * This function is non-reentrant.
     * @notice Only addresses can purchase claims in multiples of 3.
     * @notice Emits a `ClaimsPurchased` event upon successful purchase.
     * @param numberOfShillings The number of claims to purchase (must be a multiple of 3).
     */
    function claimWithEth(
        uint256 numberOfShillings
    ) external payable nonReentrant {
        // Ensure claiming is allowed
        if (!purchaseAllowed) revert PurchaseNotAllowed();

        // Verify that the number of claims is a multiple of 3
        if (numberOfShillings % 3 != 0 || numberOfShillings == 0)
            revert InvalidNumberOfTokens();

        // Calculate the total ETH required for the claims
        uint256 totalEthRequired = (numberOfShillings / 3) *
            ethPerThreeShillings;

        // Ensure the sent ETH matches the required amount
        if (msg.value != totalEthRequired) revert IncorrectAmountOfETH();

        // Calculate the balance of the contract's token holdings
        uint256 balance = uint256(tokenContract.balanceOf(address(this)));

        uint256 numberOfShillingsWei = numberOfShillings * 10 ** 18;

        // Ensure the contract has sufficient tokens to cover the reward
        if (int256(numberOfShillingsWei) - int256(balance) > 0)
            revert InsufficientTokens();

        // Transfer the Shillings to the account
        tokenContract.transfer(_msgSender(), uint256(numberOfShillingsWei));

        // Emit a ClaimsPurchased event to indicate a successful purchase
        emit ClaimsPurchased(
            _msgSender(),
            numberOfShillingsWei,
            totalEthRequired
        );
    }

    /**
     * @dev Sets the merkle root for claiming verification
     * Only authorized addresses can call this function.
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyAuthorized {
        AllowedEvaluator._setAllowedMerkleRoot(_merkleRoot);
    }

    /**
     * @dev Gets the merkle root for claiming verification
     * Only authorized addresses can call this function.
     */
    function merkleRoot() external view returns (bytes32) {
        return AllowedEvaluator._allowedMerkleRoot;
    }

    /**
     * @dev Activate/disable claiming
     * Only authorized addresses can call this function.
     */
    function setClaimAllowed(bool claimAllowed_) external onlyAuthorized {
        claimAllowed = claimAllowed_;
        emit ClaimAllowed(claimAllowed);
    }

    /**
     * @dev Activate/disable purchasing
     * Only authorized addresses can call this function.
     */
    function setPurchaseAllowed(bool purchaseAllowed_) external onlyAuthorized {
        purchaseAllowed = purchaseAllowed_;
        emit PurchaseAllowed(purchaseAllowed);
    }

    /**
     * @dev Set/update the token contract address
     * Only authorized addresses can call this function.
     */
    function setTokenContract(address tokenContract_) external onlyAuthorized {
        tokenContract = IERC20(tokenContract_);
    }

    /**
     * @dev Set/update the COK contract address
     * Only authorized addresses can call this function.
     */
    function setStakingCOKContract(
        address stakingCOKContract_
    ) external onlyAuthorized {
        stakingCOKContract = IStakingForClaims(stakingCOKContract_);
    }

    /**
     * @dev Set/update the HCOK contract address
     * Only authorized addresses can call this function.
     */
    function setStakingHCOKContract(
        address stakingHCOKContract_
    ) external onlyAuthorized {
        stakingHCOKContract = IStakingForClaims(stakingHCOKContract_);
    }

    /**
     * @dev Set/update the eth required to claim 3 shillings
     * Amount must be in wei
     * Only authorized addresses can call this function.
     */
    function setEthPerThreeShillings(
        uint256 ethPerThreeShillings_
    ) external onlyAuthorized {
        ethPerThreeShillings = ethPerThreeShillings_;
    }

    /**
     * @dev Admin function to withdraw unclaimed Shilling tokens after the claiming period.
     * Only authorized addresses can call this function.
     */
    function withdrawRemainingToken() external onlyAuthorized {
        uint256 amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), amount);
        delete amount;
    }

    /**
     * @dev Admin function to withdraw ETH from the contract.
     * Only authorized addresses can call this function.
     */
    function withdraw() external onlyAuthorized {
        uint256 balance = address(this).balance;
        if (balance <= 0) revert NoBalanceToWithdraw();

        address payable ownerAddress = payable(owner());
        ownerAddress.transfer(balance);
    }
}
