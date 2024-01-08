/**
 * SPDX-License-Identifier: UNLICENSED
 *
 * © 2021 Nonagon Technologies LLC
 * All rights reserved
 */

pragma solidity ^0.8.5;

import "./IERC1155.sol";

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./ERC165Upgradeable.sol";

//----------------------------------------------------------------------------------------
// Errors
//----------------------------------------------------------------------------------------

error InvalidTokenOperator(address operator);

error InvalidSenderAddress(address contractAddress);

error InsufficientArrayLengths();

error InsufficientTokenAmount(uint256 present, uint256 required);

//----------------------------------------------------------------------------------------
// Constants
//----------------------------------------------------------------------------------------

bytes4 constant successERC1155Received = bytes4(
    keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
);

bytes4 constant successERC1155BatchReceived = bytes4(
    keccak256(
        "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
    )
);

//----------------------------------------------------------------------------------------
// Contract
//----------------------------------------------------------------------------------------

/// @title NFTF marketplace contract
/// @notice This contract is responsible for:
/// 		- managing NFTF Tokens
/// 		- managing purchase flow
contract NFTFMarketplace is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC165Upgradeable, // supportsInterface function
    IERC1155ReceiverUpgradeable
{
    //----------------------------------------------------------------------------------------
    // Variables
    //----------------------------------------------------------------------------------------

    IERC1155 private _tokenContractAddress;

    /// @dev amount that is owned but not publicly listed
    mapping(uint256 => uint256) private _tokensReservedAmounts;

    mapping(uint256 => uint256) private _tokensPricesInWei;

    //----------------------------------------------------------------------------------------
    // Events
    //----------------------------------------------------------------------------------------

    /// @notice Indicates when token was purchased
    /// @param tokenId ID of ERC1155 token
    /// @param buyerAddress Address of buyer
    /// @param amount Amount of tokens purchased
    /// @param tokenPriceInWei Total price of purchase
    event Purchased(
        uint256 indexed tokenId,
        address indexed buyerAddress,
        uint256 amount,
        uint256 tokenPriceInWei
    );

    //----------------------------------------------------------------------------------------
    // Infrastructure
    //----------------------------------------------------------------------------------------

    function initialize(IERC1155 tokenContractAddress) public initializer {
        OwnableUpgradeable.__Ownable_init();
        updateTokenContractAddress(tokenContractAddress);
    }

    /// @inheritdoc UUPSUpgradeable
    function _authorizeUpgrade(address) internal override onlyOwner {}

    /// @inheritdoc ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    //----------------------------------------------------------------------------------------
    // Token receiving logic
    //----------------------------------------------------------------------------------------

    /// @inheritdoc IERC1155ReceiverUpgradeable
    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes memory
    ) public view override returns (bytes4) {
        if (operator != owner()) revert InvalidTokenOperator(operator);

        if (msg.sender != address(_tokenContractAddress))
            revert InvalidSenderAddress(msg.sender);

        return successERC1155Received;
    }

    /// @inheritdoc IERC1155ReceiverUpgradeable
    function onERC1155BatchReceived(
        address operator,
        address sender,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) external view override returns (bytes4) {
        if (tokenIds.length != amounts.length)
            revert InsufficientArrayLengths();

        for (uint256 index = 0; index < tokenIds.length; ++index) {
            uint256 tokenId = tokenIds[index];
            uint256 amount = amounts[index];

            if (
                onERC1155Received(operator, sender, tokenId, amount, data) !=
                successERC1155Received
            ) revert("onERC1155Received not thrown or returned");
        }

        return successERC1155BatchReceived;
    }

    //----------------------------------------------------------------------------------------
    // Internal getters
    //----------------------------------------------------------------------------------------

    /// @param tokenId ID of token
    /// @param reserved Return listed or reserved amount
    /// @return Token amount owned (listed or reserved)
    function _getTokenAvailableAmount(uint256 tokenId, bool reserved)
        private
        view
        returns (uint256)
    {
        uint256 tokenReservedAmount = _tokensReservedAmounts[tokenId];

        if (reserved) return tokenReservedAmount;

        return
            _tokenContractAddress.balanceOf(address(this), tokenId) -
            tokenReservedAmount;
    }

    /// @param tokenId ID of token
    /// @return Token price in wei
    function _getTokenPriceInWei(uint256 tokenId)
        private
        view
        returns (uint256)
    {
        return _tokensPricesInWei[tokenId];
    }

    //----------------------------------------------------------------------------------------
    // Modifiers
    //----------------------------------------------------------------------------------------

    /// @dev Checks if `minimumAvailableAmount` tokens present (listed or reserved)
    modifier isTokenAvailabletAtLeast(
        uint256 tokenId,
        uint256 minimumAvailableAmount,
        bool reserved
    ) {
        uint256 availableAmount = _getTokenAvailableAmount(tokenId, reserved);

        if (availableAmount < minimumAvailableAmount)
            revert InsufficientTokenAmount(
                availableAmount,
                minimumAvailableAmount
            );

        _;
    }

    //----------------------------------------------------------------------------------------
    // Transfer logic
    //----------------------------------------------------------------------------------------

    /// @dev Transfers tokens to address
    /// @param tokenId ID of token
    /// @param amount Token amount
    /// @param recipientAddress Address that will receive tokens
    /// @param transferReserved If true, transfers reserved tokens (decrements reserved amount)
    function _transferToken(
        uint256 tokenId,
        uint256 amount,
        address recipientAddress,
        bool transferReserved
    ) private isTokenAvailabletAtLeast(tokenId, amount, transferReserved) {
        if (transferReserved) _unreserveToken(tokenId, amount);

        _tokenContractAddress.safeTransferFrom(
            address(this),
            recipientAddress,
            tokenId,
            amount,
            ""
        );
    }

    //----------------------------------------------------------------------------------------
    // Reserving logic
    //----------------------------------------------------------------------------------------

    function _reserveToken(uint256 tokenId, uint256 amount)
        private
        isTokenAvailabletAtLeast(tokenId, amount, false)
    {
        _tokensReservedAmounts[tokenId] += amount;
    }

    function _unreserveToken(uint256 tokenId, uint256 amount)
        private
        isTokenAvailabletAtLeast(tokenId, amount, true)
    {
        _tokensReservedAmounts[tokenId] -= amount;
    }

    //----------------------------------------------------------------------------------------
    // Management
    //----------------------------------------------------------------------------------------

    function updateTokenContractAddress(IERC1155 tokenContractAddress)
        public
        onlyOwner
    {
        _tokenContractAddress = tokenContractAddress;
    }

    function payout(uint256 amount) external onlyOwner {
        require(
            address(this).balance >= amount,
            "Insufficient contract balance"
        );

        payable(owner()).transfer(amount);
    }

    function reserveToken(uint256 tokenId, uint256 amount) external onlyOwner {
        _reserveToken(tokenId, amount);
    }

    function unreserveToken(uint256 tokenId, uint256 amount)
        external
        onlyOwner
    {
        _unreserveToken(tokenId, amount);
    }

    function setTokenPrice(uint256 tokenId, uint256 priceInWei)
        external
        onlyOwner
    {
        _tokensPricesInWei[tokenId] = priceInWei;
    }

    function setTokensPrices(
        uint256[] memory tokenIds,
        uint256[] memory pricesInWei
    ) external onlyOwner {
        if (tokenIds.length != pricesInWei.length)
            revert InsufficientArrayLengths();

        for (uint256 index = 0; index < tokenIds.length; ++index) {
            uint256 tokenId = tokenIds[index];
            uint256 priceInWei = pricesInWei[index];

            _tokensPricesInWei[tokenId] = priceInWei;
        }
    }

    function transferToken(
        uint256 tokenId,
        uint256 amount,
        address recipient,
        bool transferReserved
    ) external onlyOwner {
        _transferToken(tokenId, amount, recipient, transferReserved);
    }

    //----------------------------------------------------------------------------------------
    // Public getters
    //----------------------------------------------------------------------------------------

    function getTokenListingDataBatch(uint256[] calldata tokenIds)
        external
        view
        returns (
            uint256[] memory tokenListedAmounts,
            uint256[] memory tokenPricesInWei
        )
    {
        tokenListedAmounts = new uint256[](tokenIds.length);
        tokenPricesInWei = new uint256[](tokenIds.length);

        for (uint256 index = 0; index < tokenIds.length; ++index) {
            uint256 tokenId = tokenIds[index];

            tokenListedAmounts[index] = _getTokenAvailableAmount(
                tokenId,
                false
            );
            tokenPricesInWei[index] = _getTokenPriceInWei(tokenId);
        }
    }

    //----------------------------------------------------------------------------------------
    // Purchase logic
    //----------------------------------------------------------------------------------------

    function purchase(uint256 tokenId, uint256 amount)
        external
        payable
        isTokenAvailabletAtLeast(tokenId, amount, false)
    {
        uint256 tokenPriceInWei = _getTokenPriceInWei(tokenId);

        require(tokenPriceInWei * amount == msg.value);

        emit Purchased(tokenId, msg.sender, amount, msg.value);

        _transferToken(tokenId, amount, msg.sender, false);
    }
}
