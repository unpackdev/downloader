//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC1155Burnable.sol";

import "./BaseContractUtils.sol";

/// @title WallkandaMintPass
/// @author Simon Fremaux (@dievardump) for Wallkanda.art
/// @notice This contract allows to create ERC1155 MintPasses for Wallkanda's products
contract WallkandaMintPass is Ownable, BaseContractUtils, ERC1155Burnable {
    using Strings for uint256;

    error NotAuthorized();
    error LengthMismatch();

    error AlreadyMinted();

    error UnknownToken(uint256 tokenId);

    /// @notice the royalties recipient if not owner()
    address public royaltiesRecipient;

    /// @notice the baseURI
    string public baseURI;

    /// @notice keeps track of tokens that have already been created, and doesn't allow more mint
    mapping(uint256 => uint256) public minted;

    constructor(
        string memory contractURI_,
        string memory baseURI_,
        address owner_,
        address newRoyaltiesRecipient
    ) ERC1155("") {
        _setContractURI(contractURI_);

        baseURI = baseURI_;

        if (newRoyaltiesRecipient != address(0)) {
            royaltiesRecipient = newRoyaltiesRecipient;
        }

        if (owner_ != address(0)) {
            _transferOwnership(owner_);
        }
    }

    function uri(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == this.royaltyInfo.selector ||
            super.supportsInterface(interfaceId);
    }

    ////////////////////////////////////////////////////
    ///// Royalties                                   //
    ////////////////////////////////////////////////////

    function royaltyInfo(uint256, uint256 amount)
        public
        view
        returns (address, uint256)
    {
        address recipient = royaltiesRecipient;
        if (recipient == address(0)) {
            recipient = owner();
        }

        // (royaltiesRecipient || owner), 5%
        return (recipient, (amount * 500) / 10000);
    }

    ////////////////////////////////////////////////////
    ///// Only Owner                                  //
    ////////////////////////////////////////////////////

    /// @notice Mint tokenId
    /// @param tokenId token id to mint
    /// @param amount amount to mint
    /// @param to recipient
    function mint(
        uint256 tokenId,
        uint256 amount,
        address to
    ) external onlyOwner {
        _mint(to, tokenId, amount);
    }

    /// @notice Mint batch tokens
    /// @param tokenIds tokens ids to mint
    /// @param amounts amount for each token
    /// @param to recipient
    function batchMint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        address to
    ) external onlyOwner {
        uint256 idsLength = tokenIds.length;
        if (idsLength != amounts.length) {
            revert LengthMismatch();
        }

        // not using _batchMint because we need to make sure none of the tokenIds exist
        for (uint256 i; i < idsLength; i++) {
            _mint(to, tokenIds[i], amounts[i]);
        }
    }

    /// @notice Allows owner to change the baseURI
    /// @param newBaseURI the new uri
    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    /// @notice allows owner to set contract URI
    /// @param contractURI_ the new contract uri
    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }

    /// @notice allows owner to set the royalties recipient
    /// @param newRoyaltiesRecipient the new contract uri
    function setRoyaltiesRecipient(address newRoyaltiesRecipient)
        external
        onlyOwner
    {
        royaltiesRecipient = newRoyaltiesRecipient;
    }

    ////////////////////////////////////////////////////
    ///// Internal                                    //
    ////////////////////////////////////////////////////

    /// @dev Internal mint.
    function _mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (minted[tokenId] > 0) {
            revert AlreadyMinted();
        }

        minted[tokenId] = amount;

        super._mint(to, tokenId, amount, "");
    }
}
