// SPDX-License-Identifier: UNLICENSED

/*

...                                                                                                           

*/

pragma solidity ^0.8.10;

import "./ERC721A.sol";
import "./Ownable.sol";

contract TheKongz is ERC721A, Ownable {
    bool public saleEnabled;
    string public metadataBaseURL;

    uint256 public TXN_MAX_GLOBAL = 1111;
    uint256 public MAX_TXN = 1;
    uint256 public MAX_PER_WALLET = 1;
    uint256 public constant MAX_SUPPLY = 1111;
    mapping(address => uint256) public claims;

    constructor() ERC721A("The Kongz", "KONGZ", TXN_MAX_GLOBAL) {
        saleEnabled = false;
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

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        MAX_PER_WALLET = _maxPerWallet;
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

    function mint(uint256 numOfTokens) external payable {
        require(
            (claims[msg.sender] + numOfTokens) <= MAX_PER_WALLET,
            "Minted max for wallet"
        );
        require(saleEnabled, "Sale must be active.");
        require(totalSupply() + numOfTokens <= MAX_SUPPLY, "Exceed max supply");
        require(numOfTokens > 0, "Must mint at least 1 token");
        require(numOfTokens <= MAX_TXN, "Cant mint more than 1");

        claims[msg.sender] += numOfTokens;
        _safeMint(msg.sender, numOfTokens);
    }
}
