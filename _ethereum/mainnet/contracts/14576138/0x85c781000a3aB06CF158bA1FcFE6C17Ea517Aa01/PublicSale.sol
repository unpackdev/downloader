//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "./ERC721.sol";

/**
 * @notice Public sale stage of Adventurers Token workflow
 */
abstract contract PublicSale is ERC721 {
    struct PublicSaleConfig {
        uint128 price;
        uint32 tokensPerTransaction;
    }

    PublicSaleConfig public publicSaleConfig = PublicSaleConfig({
        price: 0.145 ether,
        tokensPerTransaction: 0 // 10 + extra 1 for <
    });
    constructor() {}

    function mintPublic(uint _count) external payable returns (uint oldIndex, uint newIndex) {
        PublicSaleConfig memory _cfg = publicSaleConfig;
        require(_cfg.tokensPerTransaction > 0, "publicsale: disabled");
        require(msg.value == _cfg.price * _count, "publicsale: payment amount");
        require(_count < _cfg.tokensPerTransaction, "publicsale: invalid count");
        
        return _mint(msg.sender, _count);
    }

    function setPublicSaleConfig(uint128 _price, uint32 _tokensPerTransaction) external onlyOwner {
        if (_tokensPerTransaction > 0) {
            _tokensPerTransaction += 1;
        }
        publicSaleConfig = PublicSaleConfig({
            price: _price,
            tokensPerTransaction: _tokensPerTransaction
        });
    }
}
