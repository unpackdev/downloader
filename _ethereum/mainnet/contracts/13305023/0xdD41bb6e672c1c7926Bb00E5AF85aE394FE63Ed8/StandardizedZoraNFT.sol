// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ZoraMedia.sol";
import "./Strings.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract StandardizedZoraNFT is ZoraMedia, Ownable {
    using Strings for string;

    address proxyRegistryAddress;

    string internal baseTokenURI;
    /// @dev Suffix is needed because when using a folder uploaded to Arweave for metadata storage, Arweave gateways return content-type as specified in the path manifest, which is determined by file extension and defaults to `application/octet-stream`, which potentially could trip up consumers of the metadata URI that are strictly checking content-type returned for JSON, so we need to suffix uploaded files with `.json` to set the content-type correctly (unless we built our own path manifest rather than using arweave-deploy helpers).
    string internal baseTokenURISuffix;
    string internal contractMetadataURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseTokenURI,
        string memory _baseTokenURISuffix,
        string memory _contractMetadataURI,
        address _marketContractAddr,
        address _proxyRegistryAddress
    ) public ZoraMedia(name, symbol, _marketContractAddr) {
        baseTokenURI = _baseTokenURI;
        baseTokenURISuffix = _baseTokenURISuffix;
        contractMetadataURI = _contractMetadataURI;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * @dev Mints a token to an address.
     * @param to Address of the creator and initial owner of the token
     * @param bidShares Zora bid share settings
     */
    function mintTo(address to, IMarket.BidShares calldata bidShares)
        external
        onlyOwner
    {
        _mintForCreator(to, bidShares);
    }

    /**
     * @dev Mints a token to an address.
     * @param to Address of the creator and initial owner of the tokens
     * @param amount Number of tokens to mint
     * @param bidShares Zora bid share settings for all the tokens
     */
    function mintBatchTo(
        address to,
        uint256 amount,
        IMarket.BidShares calldata bidShares
    ) external onlyOwner {
        for (uint256 i = 0; i < amount; i++) {
            _mintForCreator(to, bidShares);
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIDs
    ) external {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            safeTransferFrom(from, to, tokenIDs[i]);
        }
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata tokenIDs
    ) external {
        for (uint256 i = 0; i < tokenIDs.length; i++) {
            transferFrom(from, to, tokenIDs[i]);
        }
    }

    function updateBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
        // @TODO we should emit an event, see e.g. Zora contrat https://github.com/ourzora/core/blob/410849e5b4c9afd5d3c4d03507744405750760d7/contracts/Media.sol#L380
    }

    function updateBaseURISuffix(string calldata _baseTokenURISuffix)
        external
        onlyOwner
    {
        baseTokenURISuffix = _baseTokenURISuffix;
        // @TODO we should emit an event
    }

    function ownerRemoveBid(uint256 tokenID, address bidder)
        external
        nonReentrant
        onlyTokenCreated(tokenID)
        onlyOwner
    {
        IMarket(marketContract).removeBid(tokenID, bidder);
    }

    function ownerBatchRemoveBids(
        uint256[] calldata tokenIDs,
        address[] calldata bidders
    ) external nonReentrant onlyOwner {
        require(
            tokenIDs.length == bidders.length,
            "StandardizedZoraNFT: tokenIds and bidders must be the same length"
        );

        for (uint256 i = 0; i < tokenIDs.length; i++) {
            require(
                _exists(tokenIDs[i]),
                "StandardizedZoraNFT: token with that id does not exist"
            );
            IMarket(marketContract).removeBid(tokenIDs[i], bidders[i]);
        }
    }

    /** Used by OpenSea (and maybe others) to get information about this contract. */
    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function updateContractURI(string calldata _contractMetadataURI)
        external
        onlyOwner
    {
        contractMetadataURI = _contractMetadataURI;
        // @TODO we should emit an event
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        onlyTokenCreated(tokenId)
        returns (string memory)
    {
        string memory baseAndTokenURI =
            Strings.strConcat(baseTokenURI, Strings.uint2str(tokenId));
        return
            bytes(baseTokenURISuffix).length > 0
                ? Strings.strConcat(baseAndTokenURI, baseTokenURISuffix)
                : baseAndTokenURI;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
