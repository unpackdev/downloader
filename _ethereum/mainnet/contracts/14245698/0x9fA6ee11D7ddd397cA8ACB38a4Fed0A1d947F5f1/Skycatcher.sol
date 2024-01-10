//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./OpenSea.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";

error TokenDoesNotExist();

contract Skycatcher is Ownable, ERC721Enumerable {
    using Strings for uint256;

    string public baseURI;
    string public uriExtension;

    OSProxyRegistry private immutable _osProxyRegistry;

    constructor(
        address ownerAddress,
        address osProxyRegistry,
        string memory baseURI_,
        string memory uriExtension_,
        address[] memory initialOwners
    ) ERC721("Skycatcher", "SKY") {
        _transferOwnership(ownerAddress);
        _osProxyRegistry = OSProxyRegistry(osProxyRegistry);
        baseURI = baseURI_;
        uriExtension = uriExtension_;

        for (uint256 index = 1; index <= initialOwners.length; ++index) {
            _safeMint(initialOwners[index - 1], index);
        }
    }

    function mint(address to) external onlyOwner {
        _safeMint(to, totalSupply() + 1);
    }

    function setURIComponents(
        string calldata baseURI_,
        string calldata uriExtension_
    ) external onlyOwner {
        baseURI = baseURI_;
        uriExtension = uriExtension_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist();

        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), uriExtension)
                )
                : "";
    }

    function isApprovedForAll(address owner_, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            super.isApprovedForAll(owner_, operator) ||
            (address(_osProxyRegistry) != address(0) &&
                address(_osProxyRegistry.proxies(owner_)) == operator);
    }
}
