// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IERC20.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

/// @title Flamelings NFTs
/// @author Nadina Oates
/// @notice Contract implementing ERC721A standard using the EARN token for minting
contract Flamelings is ERC721A, Ownable {
    /**
     * Errors
     */
    error Flamelings_InsufficientBalance();
    error Flamelings_InsufficientMintQuantity();
    error Flamelings_ExceedsMaxSupply();
    error Flamelings_ExceedsMaxPerWallet();
    error Flamelings_ExceedsBatchLimit();
    error Flamelings_FeeAddressIsZeroAddress();
    error Flamelings_TokenTransferFailed();
    error Flamelings_MaxPerWalletExceedsMaxSupply();
    error Flamelings_MaxPerWalletSmallerThanBatchLimit();
    error Flamelings_BatchLimitExceedsMaxPerWallet();
    error Flamelings_BatchLimitTooHigh();

    /**
     * Storage Variables
     */
    uint256 private constant MAX_SUPPLY = 1000;
    IERC20 private immutable i_paymentToken;

    address private s_feeAddress;
    uint256 private s_fee = 100_000 * 10 ** 18;
    uint256 private s_batchLimit = 10;
    uint256 private s_maxPerWallet = 10;
    string private s_baseTokenURI;

    /**
     * Events
     */
    event SetFee(address indexed sender, uint256 fee);
    event SetMaxPerWallet(address indexed sender, uint256 maxPerWallet);
    event SetBatchLimit(address indexed sender, uint256 batchLimit);

    /// @notice Constructor
    /// @param initialOwner ownerhip is transfered to this address after creation
    /// @param initialFeeAddress address to receive minting fees
    /// @param baseURI base uri for NFT metadata
    /// @dev inherits from ERC721A
    constructor(address initialOwner, address initialFeeAddress, address tokenAddress, string memory baseURI)
        ERC721A("Flamelings", "FLAMELING")
        Ownable(msg.sender)
    {
        if (initialFeeAddress == address(0)) revert Flamelings_FeeAddressIsZeroAddress();
        s_feeAddress = initialFeeAddress;
        i_paymentToken = IERC20(tokenAddress);
        _setBaseURI(baseURI);
        _transferOwnership(initialOwner);
    }

    /// @notice Mints NFT for token fee
    /// @param quantity number of NFTs to mint
    function mint(uint256 quantity) external {
        if (quantity == 0) revert Flamelings_InsufficientMintQuantity();
        if (balanceOf(msg.sender) + quantity > s_maxPerWallet) revert Flamelings_ExceedsMaxPerWallet();
        if (quantity > s_batchLimit) revert Flamelings_ExceedsBatchLimit();
        if (i_paymentToken.balanceOf(msg.sender) < s_fee * quantity) revert Flamelings_InsufficientBalance();
        if (_totalMinted() + quantity > MAX_SUPPLY) revert Flamelings_ExceedsMaxSupply();

        _mint(msg.sender, quantity);
        bool success = i_paymentToken.transferFrom(msg.sender, s_feeAddress, s_fee * quantity);
        if (!success) revert Flamelings_TokenTransferFailed();
    }

    /// @notice Sets minting fee in terms of EARN tokens (only owner)
    /// @param fee New fee in EARN tokens
    function setFee(uint256 fee) external onlyOwner {
        s_fee = fee;
        emit SetFee(msg.sender, fee);
    }

    /// @notice Sets the receiver address for the token fee (only owner)
    /// @param feeAddress New receiver address for tokens received through minting
    function setFeeAddress(address feeAddress) external onlyOwner {
        if (feeAddress == address(0)) revert Flamelings_FeeAddressIsZeroAddress();
        s_feeAddress = feeAddress;
    }

    /// @notice Sets the maximum number of nfts per wallet (only owner)
    /// @param maxPerWallet Maximum number of nfts that can be held by one account
    function setMaxPerWallet(uint256 maxPerWallet) external onlyOwner {
        if (maxPerWallet > MAX_SUPPLY) revert Flamelings_MaxPerWalletExceedsMaxSupply();
        if (maxPerWallet < s_batchLimit) revert Flamelings_MaxPerWalletSmallerThanBatchLimit();
        s_maxPerWallet = maxPerWallet;
        emit SetMaxPerWallet(msg.sender, maxPerWallet);
    }

    /// @notice Sets batch limit - maximum number of nfts that can be minted at once (only owner)
    /// @param batchLimit Maximum number of nfts that can be minted at once
    function setBatchLimit(uint256 batchLimit) external onlyOwner {
        if (batchLimit > 100) revert Flamelings_BatchLimitTooHigh();
        if (batchLimit > s_maxPerWallet) revert Flamelings_BatchLimitExceedsMaxPerWallet();
        s_batchLimit = batchLimit;
        emit SetBatchLimit(msg.sender, batchLimit);
    }

    /// @notice Withdraw tokens from contract (only owner)
    /// @param tokenAddress Contract address of token to be withdrawn
    /// @param receiverAddress Tokens are withdrawn to this address
    /// @return success of withdrawal
    function withdrawTokens(address tokenAddress, address receiverAddress) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        success = tokenContract.transfer(receiverAddress, amount);
    }

    /**
     * Getter Functions
     */

    /// @notice Gets payment token address
    function getPaymentToken() external view returns (address) {
        return address(i_paymentToken);
    }

    /// @notice Gets maximum supply
    function getMaxSupply() external pure returns (uint256) {
        return MAX_SUPPLY;
    }

    /// @notice Gets minting fee in EARN
    function getFee() external view returns (uint256) {
        return s_fee;
    }

    /// @notice Gets address that receives minting fees
    function getFeeAddress() external view returns (address) {
        return s_feeAddress;
    }

    /// @notice Gets number of nfts allowed minted at once
    function getBatchLimit() external view returns (uint256) {
        return s_batchLimit;
    }

    /// @notice Gets maximum number of nfts allowed per address
    function getMaxPerWallet() external view returns (uint256) {
        return s_maxPerWallet;
    }

    /**
     * Private/Internal Functions
     */

    /// @notice Sets base uri
    /// @param baseURI base uri for NFT metadata
    function _setBaseURI(string memory baseURI) private {
        s_baseTokenURI = baseURI;
    }

    /// @notice Retrieves base uri
    function _baseURI() internal view override returns (string memory) {
        return s_baseTokenURI;
    }
}
