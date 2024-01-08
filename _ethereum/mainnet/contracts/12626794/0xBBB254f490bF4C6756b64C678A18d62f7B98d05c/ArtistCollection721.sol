//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";

import "./BaseOpenSea.sol";
import "./ArtistCollection721Storage.sol";
import "./ERC2981Royalties.sol";

/// @title Artist Collection 721 contract
/// @author Simon Fremaux (@dievardump)
/// @notice This contract is made to allow Artists to own their own contract.
/// @notice It expects each tokens to have its own URI
contract ArtistCollection721 is
    OwnableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC2981Royalties,
    BaseOpenSea,
    ArtistCollection721Storage
{
    using ECDSAUpgradeable for bytes32;

    /// @notice Upgradeable contract initializer
    /// @param name_ name of the contract (see ERC721)
    /// @param symbol_ symbol of the contract (see ERC721)
    /// @param contractURI_ The contract URI (containing its metadata) - can be empty ""
    /// @param openseaProxyRegistry_ OpenSea's proxy registry to allow gas-less listings - can be address(0)
    /// @param owner_ Address to whom transfer ownership (can be address(0), then owner is deployer)
    function _initialize(
        string memory name_,
        string memory symbol_,
        string memory contractURI_,
        address openseaProxyRegistry_,
        address owner_
    ) internal initializer {
        // init Ownable & chain
        __Ownable_init();
        // init 721
        __ERC721_init_unchained(name_, symbol_);

        // set contract uri if present
        if (bytes(contractURI_).length > 0) {
            _setContractURI(contractURI_);
        }

        // set OpenSea proxyRegistry for gas-less trading if present
        if (address(0) != openseaProxyRegistry_) {
            _setOpenSeaRegistry(openseaProxyRegistry_);
        }

        // transferOwnership if needed
        if (address(0) != owner_) {
            transferOwnership(owner_);
        }
    }

    /// @inheritdoc	ERC165Upgradeable
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Royalties)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC2981Royalties.supportsInterface(interfaceId);
    }

    /// @notice Mint one token to `to`
    /// @dev Caller needs to be contract owner
    /// @param to the recipient of the token
    /// @param tokenURI_ the tokenURI of the token
    /// @param royaltyRecipient the recipient for royalties (if royaltyValue > 0)
    /// @param royaltyValue the royalties asked for (EIP2981)
    function mint(
        address to,
        string memory tokenURI_,
        address royaltyRecipient,
        uint256 royaltyValue
    ) external onlyOwner {
        uint256 tokenId = nextTokenId;
        _safeMint(to, tokenId, '');
        _setTokenURI(tokenId, tokenURI_);

        if (royaltyValue > 0) {
            _setTokenRoyalty(tokenId, royaltyRecipient, royaltyValue);
        }

        nextTokenId = tokenId + 1;
    }

    /// @notice Mint several tokens at once
    /// @dev Caller needs to be contract owner
    /// @param recipients an array of recipients for each token
    /// @param tokenURIs an array of uris for each token
    /// @param royaltyRecipients an array of recipients for royalties (if royaltyValues[i] > 0)
    /// @param royaltyValues an array of royalties asked for (EIP2981)
    function mintBatch(
        address[] memory recipients,
        string[] memory tokenURIs,
        address[] memory royaltyRecipients,
        uint256[] memory royaltyValues
    ) external onlyOwner {
        uint256 tokenId = nextTokenId;
        require(
            recipients.length == tokenURIs.length &&
                recipients.length == royaltyRecipients.length &&
                recipients.length == royaltyValues.length,
            'ERC721: Arrays length mismatch'
        );

        for (uint256 i; i < recipients.length; i++) {
            _safeMint(recipients[i], tokenId, '');
            _setTokenURI(tokenId, tokenURIs[i]);
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    tokenId,
                    royaltyRecipients[i],
                    royaltyValues[i]
                );
            }
            tokenId++;
        }

        nextTokenId = tokenId;
    }

    /// @notice Allows to burn a tokenId
    /// @dev Burns `tokenId`. See {ERC721-_burn}.  The caller must own `tokenId` or be an approved operator.
    /// @param tokenId the tokenId to burn
    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'ERC721Burnable: caller is not owner nor approved'
        );
        _burn(tokenId);
    }

    /// @notice Allows the owner of the contract to update a tokenURI
    /// @dev However the tokenURI can onlybe updated with the validation of its current owner
    ///      So if the current owner is not the current contract owner, a signed message is expected
    /// @param tokenId the tokenId
    /// @param tokenURI_ the nex token URI
    function setTokenURI(
        uint256 tokenId,
        string memory tokenURI_,
        bytes memory signature
    ) external onlyOwner {
        address tokenOwner = ownerOf(tokenId);
        if (tokenOwner != owner()) {
            require(
                hashTokenURI(tokenURI_).toEthSignedMessageHash().recover(
                    signature
                ) == tokenOwner,
                'setTokenURI: Token owner needs to sign new URI.'
            );
        }

        _setTokenURI(tokenId, tokenURI_);
    }

    /// @notice Hash the token URI so it can be signed by the owner before being changed
    /// @param tokenURI_ the tokenURI to hash
    /// @return the hash to sign
    function hashTokenURI(string memory tokenURI_)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(tokenURI_));
    }

    /// @notice Allows gas-less trading on OpenSea by safelisting the Proxy of the user
    /// @dev Override isApprovedForAll to check first if current operator is owner's OpenSea proxy
    /// @inheritdoc	ERC721Upgradeable
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // allows gas less trading on OpenSea
        if (isOwnersOpenSeaProxy(owner, operator)) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// @notice Helper for the owner of the contract to set the new contract URI
    /// @dev needs to be owner
    /// @param contractURI_ new contract URI
    function setContractURI(string memory contractURI_) external onlyOwner {
        _setContractURI(contractURI_);
    }
}
