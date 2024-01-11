// SPDX-License-Identifier: UNLICENSED

/*

 __  ___  _______  __  ___ 
|  |/  / |   ____||  |/  / 
|  '  /  |  |__   |  '  /  
|    <   |   __|  |    <   
|  .  \  |  |____ |  .  \  
|__|\__\ |_______||__|\__\ 
                                                                                                                                                   

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract kekKEKkek is ERC721A, Ownable {
    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;

    uint256 public MAX_TXN = 5;
    uint256 public constant MAX_SUPPLY = 1313;

    constructor() ERC721A("kekKEKkek", "KEK", MAX_TXN) {
        saleEnabled = false;
        price = 0.014 ether;
    }

    function setBaseURI(string memory baseURL) external onlyOwner {
        metadataBaseURL = baseURL;
    }

    function toggleSaleStatus() external onlyOwner {
        saleEnabled = !(saleEnabled);
    }

    function setMaxTxn(uint256 _maxTxn) external onlyOwner {
        MAX_TXN = _maxTxn;
    }


    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return metadataBaseURL;
    }


    function withdraw() external onlyOwner {
        uint256 _balance = address(this).balance;
        address payable _sender = payable(_msgSender());
        _sender.transfer(_balance);
    }

    function reserve(uint256 num) external onlyOwner {
        require((totalSupply() + num) <= MAX_SUPPLY, "Will exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mintKEK(uint256 tokenCount) external payable {
        require(saleEnabled, "Sale is not active");
        require(totalSupply() + tokenCount <= MAX_SUPPLY, "Will exceed max supply");
        require(tokenCount > 0, "Must mint at least 1 token");
        require(tokenCount <= MAX_TXN, "Cant mint more than 5!");
        require(
            (price * tokenCount) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, tokenCount);
    }

}