// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LoopopTokenBase.sol";

// 高级卡
/// @custom:security-contact developer@loopop.io
contract LoopopSuperCard is LoopopTokenBase {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() LoopopTokenBase("Loopop Super Card", "LSC") {
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function safeBatchMint(address[] memory tos, string[] memory uris) public onlyRole(MINTER_ROLE) {
        require(tos.length == uris.length, "tos and uris length mismatch");

        for (uint256 i = 0; i < tos.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(tos[i], tokenId);
            _setTokenURI(tokenId, uris[i]);
        }
    }

    function publicMint(address to, uint256 price, uint32 nonce, string memory uri, bytes memory validatorSig) public payable nonReentrant {
        checkPublicMintValidator(to, price, nonce, uri, validatorSig);
        require(msg.value == price, "Incorrect payment value");
        require(!_isNonceUsed[nonce], "Nonce had already used!");
        _isNonceUsed[nonce] = true;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        payable(cfo).transfer(price);
    }

}
