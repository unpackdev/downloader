// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ERC2981.sol";
import "./IMintable.sol";
import "./Minting.sol";

/// @custom:royalty Token can have custom royalty, if not: default royalty will be considered, if default royalty is deleted: then will be no royalty.
/// @custom:minters Addresses added to minters can mint tokens.
/// @custom:ownership Renounce ownership does NOT remove from minters.
contract AgletSneakers is ERC721URIStorage, Ownable, IMintable, ERC2981 {
    /// @notice Event emitted on withdraw from ImmutableX
    event TokenMintedFor(uint256 id, address to);

    /// @notice Address that are authorized to mint tokens.
    mapping(address => bool) public minters;

    /// @notice Additional details about tokens
    mapping(uint256 => string) public sneakerDetails;

    /// @param name Name of collection
    /// @param symbol Symbol of collection
    /// @param _imx ImmutableX address
    /// @param royaltyDefaultReceiver Address which will be royalty default receiver
    /// @param royaltyDefaultNumerator Numerator of default royalty
    /// @dev Notice owner is added to minters
    constructor(
        string memory name,
        string memory symbol,
        address _imx,
        address royaltyDefaultReceiver,
        uint96 royaltyDefaultNumerator)
    ERC721(name, symbol) Ownable() {
        minters[_imx] = true;
        minters[_msgSender()] = true;
        _setDefaultRoyalty(royaltyDefaultReceiver, royaltyDefaultNumerator);
    }

    /// @notice Modifier, allow only authorized minters
    modifier onlyMinters() {
        require(minters[msg.sender], "Function can only be called by minters");
        _;
    }

    /// @notice Method to mint
    /// @param to Who receive token
    /// @param tokenId Identifier of minted token
    /// @param tokenUri Uri to token
    /// @param tokenDetails Details about token to set, to mint without details, pass empty string
    function safeMint(
        address to,
        uint256 tokenId,
        string memory tokenUri,
        string memory tokenDetails)
    public onlyMinters {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenUri);
        _setTokenDetails(tokenId, tokenDetails);
    }

    /// @notice Method to mint and set custom royalty
    /// @param to Who receive token
    /// @param tokenId Identifier of minted token
    /// @param tokenUri Uri to token
    /// @param royaltyReceiver Address which will be royalty receiver to set
    /// @param royaltyNumerator Numerator of royalty to set
    /// @param tokenDetails Details about token to set, to mint without details, pass empty string
    function safeMintWithRoyalty(
        address to,
        uint256 tokenId,
        string memory tokenUri,
        address royaltyReceiver,
        uint96 royaltyNumerator,
        string memory tokenDetails)
    public onlyMinters {
        safeMint(to, tokenId, tokenUri, tokenDetails);
        _setTokenRoyalty(tokenId, royaltyReceiver, royaltyNumerator);
    }

    /// @notice Method to withdraw token from ImmutableX
    /// @param user Who receive token
    /// @param quantity Quantity of withdraw tokens. Only handle quantity = 1
    /// @param mintingBlob Tokens data, format {'tokenId'}:{'royaltyNumerator''royaltyReceiver''tokenURILength':'tokenURI''tokenDetailsLength':'tokenDetails'}
    /// @dev to mint without royalty set royaltyNumerator to zero
    /// @dev to mint without details skip 'tokenDetailsLength':'tokenDetails' in mintingBlob
    function mintFor(
        address user,
        uint256 quantity,
        bytes calldata mintingBlob)
    public override onlyMinters {
        require(quantity == 1, "Invalid quantity");
        uint256 tokenId;
        uint256 index;
        uint96 royaltyNumerator;
        address royaltyReceiver;
        string memory tokenURI;
        string memory tokenDetails;
        (tokenId, index) = Minting.getTokenId(mintingBlob);
        (royaltyNumerator, index) = Minting.getRoyaltyFraction(mintingBlob, index);
        (royaltyReceiver, index) = Minting.getRoyaltyReceiver(mintingBlob, index);
        (tokenURI, index) = Minting.getURI(mintingBlob, index);
        tokenDetails = Minting.getDetails(mintingBlob, index);
        safeMintWithRoyalty(user, tokenId, tokenURI, royaltyReceiver, royaltyNumerator, tokenDetails);
        emit TokenMintedFor(tokenId, user);
    }

    /// @notice Set token details
    /// @param tokenId Identifier of the token
    /// @param tokenDetails Token details to set
    function _setTokenDetails(
        uint256 tokenId,
        string memory tokenDetails)
    internal {
        require(_exists(tokenId), "Details set of nonexistent token");
        sneakerDetails[tokenId] = tokenDetails;
    }

    /// @notice method to transfer smart contract ownership
    /// @param newOwner Address to transfer smart contract ownership
    /// @dev Notice old owner will be removed from minters and new owner will be added
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        super.transferOwnership(newOwner);
        delete minters[_msgSender()];
        minters[newOwner] = true;
    }

    /// @notice Add address to minters
    /// @param to Address which will be added to minters
    function addMinter(
        address to)
    public onlyOwner {
        minters[to] = true;
    }

    /// @notice Remove address from minters
    /// @param to Address which will be removed from minters
    function removeMinter(
        address to)
    public onlyOwner {
        delete minters[to];
    }

    /// @notice Set custom royalty for the token
    /// @param tokenId Identifier of the token
    /// @param royaltyReceiver Address which will be royalty receiver to set
    /// @param royaltyNumerator Numerator of royalty to set
    function setTokenRoyalty(
        uint256 tokenId,
        address royaltyReceiver,
        uint96 royaltyNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, royaltyReceiver, royaltyNumerator);
    }

    /// @notice Remove custom royalty for the token
    /// @param tokenId Identifier of the token
    function resetTokenRoyalty(
        uint256 tokenId)
    public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }

    /// @notice Remove default royalty for the smart contract
    function deleteDefaultRoyalty()
    public onlyOwner {
        _deleteDefaultRoyalty();
    }

    /// @notice Set default royalty for the smart contract
    /// @param royaltyReceiver Address which will be royalty receiver to set
    /// @param royaltyNumerator Numerator of royalty to set
    function setDefaultRoyalty(
        address royaltyReceiver,
        uint96 royaltyNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(royaltyReceiver, royaltyNumerator);
    }

    /// @notice Return true if smart contract support the interface
    /// @param interfaceId Interface identifier to check support
    function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC721, ERC2981)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}