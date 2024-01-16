// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC20.sol";

/*****************************************************************************
 *  ______   _______   ______   _____    _   _   _____   _______  __     __
 * |  ____| |__   __| |  ____| |  __ \  | \ | | |_   _| |__   __| \ \   / /
 * | |__       | |    | |__    | |__) | |  \| |   | |      | |     \ \_/ / 
 * |  __|      | |    |  __|   |  _  /  | . ` |   | |      | |      \   /  
 * | |____     | |    | |____  | | \ \  | |\  |  _| |_     | |       | |   
 * |______|    |_|    |______| |_|  \_\ |_| \_| |_____|    |_|       |_|   
 *                                                                         
 ******************************************************************************/


contract LiberEternity is ERC721A, Ownable {
    
    uint256 public mintPrice = 50000000000000000;
    uint256 public freeNum = 300;
    uint256 public totalNum = 666;
    uint256 public mintLimit = 10;
    bool public saleIsActive = false;
    string public baseURI;
    constructor() ERC721A("LiberEternity", "LBE") {}

    function mint(uint256 num) external payable {
        uint256 mintedNum = _totalMinted();
        require(saleIsActive, "sale is not active.");
        require(balanceOf(msg.sender) + num <= mintLimit, "mint limit reached.");
        require(mintedNum+num <= totalNum, "no enough nfts left.");
        require(mintedNum+num <= freeNum || msg.value >= num * mintPrice, "free mint ended, you can purchase some.");
        _mint(msg.sender, num);
    }

    function airdrop(address[] calldata addrs) external onlyOwner {
        uint256 mintedNum = _totalMinted();
        require(addrs.length + mintedNum <= totalNum, "no enough nfts left.");
        for (uint256 i = 0; i < addrs.length; i++) {
          _mint(addrs[i], 1);
        }
    }

    function reserve(uint256 num) external onlyOwner {
        uint256 mintedNum = _totalMinted();
        require(mintedNum+num <= totalNum, "no enough nfts left.");
        _mint(msg.sender, num);
    }

    function flipSaleState() external onlyOwner {
      saleIsActive = !saleIsActive;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }
    
    function withdrawToken(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function setBaseURI(string calldata source) external onlyOwner {
        baseURI = source;
    }

    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

   function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseURI;
    }
}