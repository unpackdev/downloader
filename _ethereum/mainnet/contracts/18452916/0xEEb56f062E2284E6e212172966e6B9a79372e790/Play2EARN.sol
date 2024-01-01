/**
        BUY, HOLD, EARN, BURN!
        X: https://twitter.com/buyholdearn
        Telegram: https://t.me/buyholdearn
        Website: http://buyholdearn.com
        Mint: http://app.buyholdearn.com
        Play: http://play.buyholdearn.com
        
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Play2EARN is ERC721A, Ownable {
    uint256 public constant MAX_SUPPLY = 10000;

    IERC20 public immutable paymentToken;
    address public feeAddress;
    uint256 public fee = 100000 * 10 ** 18;
    uint256 public batchLimit = 10;
    uint256 public maxPerWallet = 10;

    string private _baseTokenURI;

    constructor(
        address initialOwner,
        address initialFeeAddress,
        address tokenAddress,
        string memory baseURI
    ) ERC721A("Play2EARN", "P2EARN") Ownable(msg.sender) {
        require(initialFeeAddress != address(0), "Fee address is zero address");
        feeAddress = initialFeeAddress;
        paymentToken = IERC20(tokenAddress);
        _setBaseURI(baseURI);
        _transferOwnership(initialOwner);
    }

    // set base uri
    function _setBaseURI(string memory baseURI) private {
        _baseTokenURI = baseURI;
    }

    // retrieve base uri
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // mint NFT for token fee
    function mint(uint256 quantity) external {
        require(quantity <= batchLimit, "Exceeds batch limit");
        require(_totalMinted() + quantity <= MAX_SUPPLY, "Exceeds max supply");
        require(
            balanceOf(msg.sender) + quantity <= maxPerWallet,
            "Exceeds max per wallet"
        );
        _mint(msg.sender, quantity);
        bool success = paymentToken.transferFrom(
            msg.sender,
            feeAddress,
            fee * quantity
        );
        require(success, "Token transfer failed");
    }

    // set fee (only owner)
    function setFee(uint256 newFee) external onlyOwner {
        fee = newFee;
    }

    // set the receiver address (only owner)
    function setFeeAddress(address newFeeAddress) external onlyOwner {
        require(newFeeAddress != address(0), "Fee address is zero address");
        feeAddress = newFeeAddress;
    }

    // set the maximum number of nfts per wallet (only owner)
    function setMaxPerWallet(uint256 newMaxMint) external onlyOwner {
        require(
            newMaxMint < MAX_SUPPLY,
            "Max mint per wallet exceeds max supply"
        );
        require(
            newMaxMint >= batchLimit,
            "Max mint per wallet smaller than batch limit"
        );
        maxPerWallet = newMaxMint;
    }

    // set batch limit (only owner)
    function setBatchLimit(uint256 newLimit) external onlyOwner {
        require(newLimit <= 100, "Batch limit exceeds maximum allowed");
        require(
            newLimit <= maxPerWallet,
            "Batch limit exceeds max mint per wallet"
        );
        batchLimit = newLimit;
    }

    // withdraw tokens from contract (only owner)
    function withdrawTokens(
        address tokenAddress,
        address receiverAddress
    ) external onlyOwner returns (bool success) {
        IERC20 tokenContract = IERC20(tokenAddress);
        uint256 amount = tokenContract.balanceOf(address(this));
        success = tokenContract.transfer(receiverAddress, amount);
    }

}
