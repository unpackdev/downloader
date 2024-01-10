//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";

contract HypeXShirt is ERC1155Supply, Ownable {
    uint256 private constant TOKEN_ID = 1;
    uint256 public maxSupply = 500;
    address public operator;
    mapping(string => bool) public presetCodes;

    string public name;

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "Shirt: PERMISSION_DENIED");
        _;
    }

    constructor(string memory name_) ERC1155("") {
        name = name_;
    }

    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "Shirt: INVALID_OPERATOR");
        operator = newOperator;
    }

    function setName(string memory name_) external onlyOwnerOrOperator {
        name = name_;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyOwnerOrOperator {
        require(newMaxSupply >= totalSupply(TOKEN_ID), "Shirt: ALREADY_MINTED_OVER");
        maxSupply = newMaxSupply;
    }

    function setPresetCodes(string[] calldata codes, bool[] calldata approved)
        external
        onlyOwnerOrOperator
    {
        for (uint256 i; i < codes.length; i++) presetCodes[codes[i]] = approved[i];
    }

    function mintNFT(string memory code) external {
        require(presetCodes[code], "Shirt: INVALID_CODE");
        require(totalSupply(TOKEN_ID) < maxSupply, "Shirt: INSUFFICIENT_AMOUNT");
        _mint(msg.sender, TOKEN_ID, 1, "");
        presetCodes[code] = false;
    }

    function setURI(string memory uri) external onlyOwnerOrOperator {
        super._setURI(uri);
    }
}
