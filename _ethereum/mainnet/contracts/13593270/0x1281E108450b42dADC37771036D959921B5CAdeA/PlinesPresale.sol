// SPDX-License-Identifier: MIT

// presale DApp https://presale.plines.io

import "./Plines.sol";

pragma solidity ^0.8.10;

contract PlinesPresale {
    string public presaleDAppURI;
    uint256 public price;
    uint256 public maxTokensPerPurchase;
    address payable public vault;
    Plines public token;

    event Buy(address indexed from, uint256 amount, uint256 value);

    constructor(
        uint256 _price,
        uint256 _maxTokensPerPurchase,
        address payable _vault,
        Plines _token,
        string memory _presaleDAppURI
    ) {
        price = _price;
        maxTokensPerPurchase = _maxTokensPerPurchase;
        vault = _vault;
        token = _token;
        presaleDAppURI = _presaleDAppURI;
    }

    function getTotalPrice(uint256 _amount) public view returns (uint256) {
        return _amount * price;
    }

    function buy(uint256 _amount, string memory _presaleDAppURI) public payable {
        require(
            keccak256(abi.encodePacked(presaleDAppURI)) == keccak256(abi.encodePacked(_presaleDAppURI)),
            "Wrong presaleDAppURI"
        );
        require(_amount <= maxTokensPerPurchase, "Can not buy > maxAmountPerPurchase");
        require(msg.value == getTotalPrice(_amount), "BAD_VALUE");

        token.mintMultiple(msg.sender, _amount);
        vault.transfer(msg.value);
        emit Buy(msg.sender, _amount, msg.value);
    }
}
