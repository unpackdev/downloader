// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./ERC721Delegated.sol";
import "./ERC721Base.sol";
import "./CountersUpgradeable.sol";

contract PFPNFT is ERC721Delegated {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter currentTokenId;

    mapping(uint256 => string) tokenURIs;

    constructor(address baseFactory)
        ERC721Delegated(
            baseFactory,
            "PFP NFT",
            "PFP",
            ConfigSettings({
                royaltyBps: 0,
                uriBase: "",
                uriExtension: "",
                hasTransferHook: false
            })
        )
    {}

    function mint(string memory tokenURI) public {
        currentTokenId.increment();
        tokenURIs[currentTokenId.current()] = tokenURI;
        _mint(msg.sender, currentTokenId.current());
    }

    function changeTokenURI(uint256 tokenId, string memory newURI) public {
        require(_exists(tokenId));
        require(
            _isApprovedOrOwner(msg.sender, tokenId) || msg.sender == _owner()
        );
        tokenURIs[tokenId] = newURI;
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "No token");
        return tokenURIs[tokenId];
    }
}
