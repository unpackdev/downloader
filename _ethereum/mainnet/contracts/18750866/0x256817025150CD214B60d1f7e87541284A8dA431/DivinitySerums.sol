// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

/**
 *    ______  _____ _    _ _____ __   _ _____ _______ __   __
 *    |     \   |    \  /    |   | \  |   |      |      \_/
 *    |_____/ __|__   \/   __|__ |  \_| __|__    |       |
 */

contract DivinitySerums is ERC721A, Ownable, ReentrancyGuard {
    error MintingIsClosed();
    error IncorrectEtherAmount(uint256 required, uint256 sent);
    error FailedToSendEther();
    error ExceedsMaxMintPerTransaction();
    error SoulboundToken();

    uint128 public constant MAX_TOKENS_PER_MINT = 5;
    uint128 public tokenPrice = 0.021 ether;
    bool public isSoulbound = true;
    bool public isMintingEnabled;
    string private _baseTokenURI;

    constructor(
        string memory name_,
        string memory symbol_,
        address _owner
    ) ERC721A(name_, symbol_) Ownable(_owner) {}

    /**
     * @notice Allows a user to mint a specified quantity of Divinity Serums.
     * @dev This function includes checks for minting status, quantity limits,
     *      and ether value sent. It reverts if any conditions are not met.
     * @param qty The quantity of Divinity Serums to mint. Must not exceed the
     *      `MAX_TOKENS_PER_MINT` limit.
     * @custom:error MintingIsClosed Throws an error if minting is currently disabled.
     * @custom:error ExceedsMaxMintPerTransaction Throws an error if the requested
     *      quantity exceeds the maximum tokens allowed per transaction.
     * @custom:error IncorrectEtherAmount Throws an error if the ether sent is not
     *      equal to the product of `tokenPrice` and `qty`.
     */
    function mintSerum(uint256 qty) external payable nonReentrant {
        if (!isMintingEnabled) revert MintingIsClosed();

        if (qty > MAX_TOKENS_PER_MINT) revert ExceedsMaxMintPerTransaction();

        uint256 requiredValue = tokenPrice * qty;
        if (msg.value < requiredValue) {
            revert IncorrectEtherAmount(requiredValue, msg.value);
        }

        _safeMint(_msgSender(), qty);
    }

    /**
     * @notice Mints a single Divinity Serum to a specified address.
     * @dev Reverts if insufficient ether is sent. Only callable by the owner.
     * @param _to The address to which the Serum will be minted.
     * @custom:error IncorrectEtherAmount If the ether sent is less than
     *      the token price.
     */
    function mintTo(address _to) external payable nonReentrant {
        if (!isMintingEnabled) revert MintingIsClosed();

        if (msg.value < tokenPrice) {
            revert IncorrectEtherAmount(tokenPrice, msg.value);
        }
        _safeMint(_to, 1);
    }

    /**
     * @notice Internal function to return the base URI for token metadata.
     * @dev Overrides the ERC721A's `_baseURI` function.
     * @return The currently set base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Enables or disables soulbound tokens.
     * @dev Only callable by the contract owner.
     * @param enabled The boolean flag to enable or disable soulbound.
     */
    function setIsSoulbound(bool enabled) external onlyOwner {
        isSoulbound = enabled;
    }

    /**
     * @notice Enables or disables the minting of Divinity Serums.
     * @dev Only callable by the contract owner.
     * @param enabled The boolean flag to enable or disable minting.
     */
    function setMintingEnabled(bool enabled) external onlyOwner {
        isMintingEnabled = enabled;
    }

    /**
     * @notice Sets the base URI for the Divinity Serums tokens.
     * @dev Only callable by the contract owner. Used to set the metadata URI.
     * @param newBaseURI The new base URI string.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    /**
     * @notice Sets the price for minting a single Divinity Serum.
     * @dev Only callable by the contract owner. Price must be greater
     *      than zero.
     * @param _tokenPrice The new price per token in wei.
     * @custom:error TokenPriceMustBeGreaterThanZero If the new token
     *      price is set to zero.
     */
    function setTokenPrice(uint128 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    /**
     * @notice Withdraws Ether from the contract to a specified address.
     * @dev Only callable by the contract owner. Reverts if the transfer fails.
     * @param recipient The address to receive the Ether. If zero, Ether is
     *      sent to the owner.
     * @custom:error FailedToSendEther If Ether transfer fails.
     */
    function withdraw(address payable recipient) public onlyOwner {
        if (recipient == address(0)) recipient = payable(_msgSender());
        (bool success, ) = recipient.call{ value: address(this).balance }("");
        if (!success) revert FailedToSendEther();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (isSoulbound && from != address(0)) revert SoulboundToken();

        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}
