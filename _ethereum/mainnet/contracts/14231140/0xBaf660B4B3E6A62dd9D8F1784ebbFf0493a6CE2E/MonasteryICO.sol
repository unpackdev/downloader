// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";

import "./SafeMath.sol";

import "./IERC721Enumerable.sol";

import "./Constants.sol";
import "./Errors.sol";

import "./IDERC20.sol";

contract MonasteryICO is Ownable, Constants, Errors {
    using SafeMath for uint256;

    IERC721Enumerable public NFTToken = IERC721Enumerable(NFT_ADDRESS);
    IDERC20 public purchaseToken = IDERC20(PURCHASE_TOKEN_ADDRESS);
    IDERC20 public receiveToken = IDERC20(RECEIVE_TOKEN_ADDRESS);

    uint256 public purchaseTokenDecimals = 18;
    uint256 public receiveTokenDecimals = 9;

    uint256 public tokenPerNFT = uint256(48).mul(10 ** receiveTokenDecimals);
    uint256 public price = 10;

    mapping(uint256 => uint256) public claimed;

    uint256 public startTime;
    uint256 public endTime;

    constructor() {}

    // Setters

    function setNFTToken(address NFTTokenAddress) public onlyOwner {
        require(NFTTokenAddress != ADDRESS_ZERO, ADDRESS_ZERO_ERROR);
        NFTToken = IERC721Enumerable(NFTTokenAddress);
    }

    function setPurchaseToken(address purchaseTokenAddres) public onlyOwner {
        require(purchaseTokenAddres != ADDRESS_ZERO, ADDRESS_ZERO_ERROR);
        purchaseToken = IDERC20(purchaseTokenAddres);
        purchaseTokenDecimals = purchaseToken.decimals();
    }

    function setReceiveToken(address receiveTokenAddres) public onlyOwner {
        require(receiveTokenAddres != ADDRESS_ZERO, ADDRESS_ZERO_ERROR);
        receiveToken = IDERC20(receiveTokenAddres);
        uint256 prevDecimals = receiveTokenDecimals;
        receiveTokenDecimals = receiveToken.decimals();
        if (receiveTokenDecimals != prevDecimals) {
            tokenPerNFT = tokenPerNFT.div(10 ** prevDecimals).mul(10 ** receiveTokenDecimals);
        }
    }

    function setTokenPerNFT(uint256 _tokenPerNFT) public onlyOwner {
        require(_tokenPerNFT > 0, NOT_POSITIVE_ERROR);
        tokenPerNFT = _tokenPerNFT;
    }

    function setICOTIme(uint256 start, uint256 end) public onlyOwner {
        require(start > block.timestamp, LTN_TIMESTAMP_ERROR);
        require(end > start, LTS_TIMESTAMP_ERROR);
        startTime = start;
        endTime = end;
    }

    function haltICO() public onlyOwner {
        startTime = 0;
        endTime = 0;
    }

    function startBuy() public onlyOwner {
        endTime = block.timestamp;
    }

    function setPrice(uint256 _price) public onlyOwner {
        require(_price > 0, NOT_POSITIVE_ERROR);
        price = _price;
    }

    // Owner

    function deposit(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != ADDRESS_ZERO, ADDRESS_ZERO_ERROR);
        require(amount > 0, NOT_POSITIVE_ERROR);
        IDERC20(tokenAddress).transferFrom(_msgSender(), THIS_ADDRESS, amount);
    }

    function withdraw(address tokenAddress, uint256 amount, address to) public onlyOwner {
        require(tokenAddress != ADDRESS_ZERO, ADDRESS_ZERO_ERROR);
        require(amount > 0, NOT_POSITIVE_ERROR);
        require(to != ADDRESS_ZERO, ADDRESS_ZERO_ERROR);
        IDERC20(tokenAddress).transfer(to, amount);
    }

    function balanceOf(address tokenAddress) public view onlyOwner returns (uint256 balance) {
        balance = IDERC20(tokenAddress).balanceOf(THIS_ADDRESS);
    }

    // Checkers

    function checkClaimable(address owner, uint256 amount) private returns (uint256 canClaim) {
        uint256 balance = NFTToken.balanceOf(owner);
        canClaim = 0;
        for (uint256 index = 0; index < balance && amount > 0; ++index) {
            uint256 tokenId = NFTToken.tokenOfOwnerByIndex(owner, index);
            uint256 remaining = tokenPerNFT.sub(claimed[tokenId]);
            if (remaining > 0) {
                uint256 available = amount > remaining ? remaining : amount;
                claimed[tokenId] = claimed[tokenId].add(available);
                canClaim = canClaim.add(available);
                amount = amount.sub(available);
            }
        }
    }

    // INFO

    function getClaimable() public view returns (uint256 canClaim) {
        address owner = _msgSender();
        uint256 balance = NFTToken.balanceOf(owner);
        canClaim = 0;
        for (uint256 index = 0; index < balance; ++index) {
            uint256 tokenId = NFTToken.tokenOfOwnerByIndex(owner, index);
            uint256 remaining = tokenPerNFT.sub(claimed[tokenId]);
            canClaim = canClaim.add(remaining);
        }
    }

    function isClaimOn() public view returns (bool) {
        return block.timestamp > startTime && block.timestamp < endTime;
    }

    function isBuyOn() public view returns (bool) {
        return endTime != 0 && block.timestamp > endTime;
    }

    function calculatePriceForAmount(uint256 amount) public view returns (uint256) {
        uint256 decimals = 0;
        if (purchaseTokenDecimals >= receiveTokenDecimals) {
            decimals = purchaseTokenDecimals.sub(receiveTokenDecimals);
            return amount.mul(price).mul(10 ** decimals);
        }
        decimals = receiveTokenDecimals.sub(purchaseTokenDecimals);
        return amount.mul(price).div(10 ** decimals);
    }

    // ICO

    function claim(uint256 amount) public {
        require(isClaimOn(), NOT_ON_SALE_ERROR);
        require(amount > 0, NOT_POSITIVE_ERROR);
        require(amount <= receiveToken.balanceOf(THIS_ADDRESS), INSUFFICIENT_BALANCE_ERROR);

        uint256 canClaimAmount = checkClaimable(_msgSender(), amount);
        require(canClaimAmount == amount, BAD_AMOUNT_ERROR);

        purchaseToken.transferFrom(_msgSender(), THIS_ADDRESS, calculatePriceForAmount(amount));
        receiveToken.transfer(_msgSender(), amount);
    }    

    function buy(uint256 amount) public {
        require(isBuyOn(), NOT_ON_BUY_ERROR);
        require(amount > 0, NOT_POSITIVE_ERROR);
        require(amount <= receiveToken.balanceOf(THIS_ADDRESS), INSUFFICIENT_BALANCE_ERROR);
        require(receiveToken.balanceOf(_msgSender()) > 0, NOT_HOLDER_ERROR);

        purchaseToken.transferFrom(_msgSender(), THIS_ADDRESS, calculatePriceForAmount(amount));
        receiveToken.transfer(_msgSender(), amount);
    }
}