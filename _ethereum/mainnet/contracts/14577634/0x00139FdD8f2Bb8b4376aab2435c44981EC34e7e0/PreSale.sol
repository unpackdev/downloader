//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC165Checker.sol";
import "./IERC1155.sol";

/**
 * @notice Presale (Crystal exchange) stage of Adventurers Token workflow
 */
abstract contract PreSale is ERC721 {
    using ERC165Checker for address;

    struct PresaleConfig {
        uint128 price;
        uint32 tokensPerCrystal;
    }

    /* state */
    address public crystal;
    PresaleConfig public presaleConfig = PresaleConfig({
        price: 0.095 ether,
        tokensPerCrystal: 4 // 3 + extra 1 for <
    });

    constructor() {}

    function mintCrystalHolders(uint _count, uint _id) external payable returns (uint oldIndex, uint newIndex) {
        require(crystal != address(0), "presale: disabled");
        PresaleConfig memory _cfg = presaleConfig;
        require(msg.value == _cfg.price * _count, "presale: invalid payment amount");
        require(_count > 0 && _count < _cfg.tokensPerCrystal, "presale: invalid count");
        IERC1155(crystal).safeTransferFrom(msg.sender, address(this), _id, 1, "");
        return _mint(msg.sender, _count);
    }
    
    function setPresaleConfig(uint128 _price, uint32 _tokensPerCrystal) external onlyOwner {
        presaleConfig = PresaleConfig({
            price: _price,
            tokensPerCrystal: _tokensPerCrystal + 1
        });
    }

    function setCrystal(address _value) external onlyOwner {
        require(_value == address(0) 
            || _value.supportsInterface(type(IERC1155).interfaceId),
            "presale: 0 or valid IERC1155");
        crystal = _value;
        if (_value != address(0)) {
            IERC1155(_value).setApprovalForAll(owner(), true); // we want to regift crystals
        }
    }
}
