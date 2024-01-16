// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LoopopTokenBase.sol";

// 明星通用NFT pass
/// @custom:security-contact developer@loopop.io
contract LoopopPremiumPass is LoopopTokenBase {
    
    uint32 public maxSupply;
    uint32 public currentSupply;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor(uint32 maxSupply_) LoopopTokenBase("Loopop Premium Pass", "LPP") {
        maxSupply = maxSupply_;
    }

    function safeBatchMint(address[] memory tos, string[] memory uris) public onlyRole(MINTER_ROLE) {
        require(tos.length == uris.length, "tos and uris length mismatch");
        require(currentSupply + tos.length < maxSupply, "totalSupply exceed maxSupply!");

        for (uint256 i = 0; i < tos.length; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(tos[i], tokenId);
            currentSupply +=1;
            _setTokenURI(tokenId, uris[i]);
        }
    }

    function safeMint(address to, string memory uri) public onlyRole(MINTER_ROLE) {
        require(currentSupply < maxSupply, "totalSupply exceed maxSupply!");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        currentSupply +=1;
        _setTokenURI(tokenId, uri);
    }

    function publicMint(address to, uint256 price, uint32 nonce, string memory uri, bytes memory validatorSig) public payable nonReentrant {
        checkPublicMintValidator(to, price, nonce, uri, validatorSig);
        require(msg.value == price, "Incorrect payment value");
        require(!_isNonceUsed[nonce], "Nonce had already used!");
        require(currentSupply < maxSupply, "totalSupply exceed maxSupply!");
        _isNonceUsed[nonce] = true;
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        currentSupply +=1;
        _setTokenURI(tokenId, uri);
        payable(cfo).transfer(price);
    }

    function setMaxSupply(uint32 maxSupply_) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        require(currentSupply < maxSupply_, "invalid maxSupply Coount!");
        maxSupply = maxSupply_;
    }

}
