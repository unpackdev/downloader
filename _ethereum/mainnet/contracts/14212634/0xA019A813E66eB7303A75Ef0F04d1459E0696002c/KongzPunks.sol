// SPDX-License-Identifier: UNLICENSED

/*

 ___   _  _______  __   __  __    _  ___   _  _______ 
|   | | ||       ||  | |  ||  |  | ||   | | ||       |
|   |_| ||    _  ||  | |  ||   |_| ||   |_| ||  _____|
|      _||   |_| ||  |_|  ||       ||      _|| |_____ 
|     |_ |    ___||       ||  _    ||     |_ |_____  |
|    _  ||   |    |       || | |   ||    _  | _____| |
|___| |_||___|    |_______||_|  |__||___| |_||_______|                                                                                                        


*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract KongzPunks is ERC721A, Ownable {
    bool public saleEnabled;
    uint256 public price;
    string public metadataBaseURL;

    uint256 public MAX_TXN = 25;
    uint256 public constant MAX_SUPPLY = 10000;

    constructor() ERC721A("Kongz Punks", "Kpunks", MAX_TXN) {
        saleEnabled = false;
        price = 0.01 ether;
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
        require((totalSupply() + num) <= MAX_SUPPLY, "Exceed max supply");
        _safeMint(msg.sender, num);
    }

    function mint(uint256 tokenCount) external payable {
        require(saleEnabled, "The Sale must be active.");
        require(totalSupply() + tokenCount <= MAX_SUPPLY, "Exceed max supply");
        require(tokenCount > 0, "You must mint at least 1 token.");
        require(tokenCount <= MAX_TXN, "Token Count must be 25 or less.");
        require(
            (price * tokenCount) <= msg.value,
            "Insufficient funds to claim."
        );

        _safeMint(msg.sender, tokenCount);
    }

}