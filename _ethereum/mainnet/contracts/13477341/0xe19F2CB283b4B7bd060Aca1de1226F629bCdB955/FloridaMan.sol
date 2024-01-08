// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract FloridaMan is ERC721Enumerable, Ownable {
    uint256 public constant PRICE = 0.06 ether;
    uint256 public constant maxTokenPurchase = 20;
    uint256 public constant MAX_TOKENS = 10000;
    string public constant PROVENANCE_HASH = "e3d5386f7a636b083f6fc8e6ad61c58fc8eb1f65edb692c737cef059ff0029e9";
    string public constant baseTokenURI = "ipfs://QmTrrLsqmnNbc8UKt57CoDLz8SiV7Htf2kZ5WULnoZmRcw/";
    bool public saleIsActive = false;
    uint256 private _top = MAX_TOKENS;
    uint256 private _bottom = 1;
    address private _devAddress;
    address private _artistAddress;

    constructor(
        address devAddress,
        address artistAddress
    ) ERC721("FloridaMan", "FLMN") {
        _devAddress = devAddress;
        _artistAddress = artistAddress;
    }

    function mintToken(uint256 numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint");
        require(totalSupply() + numberOfTokens <= MAX_TOKENS,"Purchase would exceed max supply");
        require(numberOfTokens <= maxTokenPurchase, "Can only mint 20 FloridaMen at a time");
        require(PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _mint(numberOfTokens);
    }

    function reserveFM() external onlyOwner {
        _mint(20);
    }

    function _mint(uint256 tokens) internal {
        for (uint256 i = 0; i < tokens; i++) {
            if (totalSupply() < MAX_TOKENS) {
                uint256 coin = flipCoin();
                if (coin == 0) {
                    _safeMint(_msgSender(), _bottom);
                    _bottom += 1;
                } else {
                    _safeMint(_msgSender(), _top);
                    _top -= 1;
                }
            }
        }
    }

    function flipCoin() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,_top,_bottom))) % 2;
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Cannot withdraw 0");
        _widthdraw(_devAddress, balance / 2);
        _widthdraw(_artistAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
}
