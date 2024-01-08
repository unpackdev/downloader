//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
$$$$$$$\   $$$$$$\   $$$$$$\ $$$$$$$$\ $$\   $$\ 
$$  __$$\ $$  __$$\ $$  __$$\\__$$  __|$$$\  $$ |
$$ |  $$ |\__/  $$ |$$ /  $$ |  $$ |   $$$$\ $$ |
$$$$$$$\ | $$$$$$  |$$ |  $$ |  $$ |   $$ $$\$$ |
$$  __$$\ $$  ____/ $$ |  $$ |  $$ |   $$ \$$$$ |
$$ |  $$ |$$ |      $$ |  $$ |  $$ |   $$ |\$$$ |
$$$$$$$  |$$$$$$$$\  $$$$$$  |  $$ |   $$ | \$$ |
\_______/ \________| \______/   \__|   \__|  \__| 
                                                 */

import "./IERC1155.sol";
import "./Ownable.sol";

contract B2OERC1155Buyer is Ownable {

    //ERC1155 contract interface
    IERC1155 private _erc1155Contract;

    //Mapping from token ID to price
    mapping(uint256 => uint256) private _prices;

    //Withdrawals balance for owner
    uint256 private _pendingWithdrawals;

    //Construct with ERC1155 contract address
    constructor(address erc1155Addr) {
        _erc1155Contract = IERC1155(erc1155Addr);
    }

    //Set prices of tokens
    function setPrice(uint256 tokenId, uint256 price) public onlyOwner {

        require(price > 0, 'B2OERC1155Buyer: price must be > 0');

        _prices[tokenId] = price;
    }

    function setPriceBatch(uint256[] memory tokenIds, uint256[] memory prices) public onlyOwner {

        require(tokenIds.length == prices.length, 'B2OERC1155Buyer: tokensIds and prices length do not match');

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(prices[i] > 0, 'B2OERC1155Buyer: price must be > 0');
            _prices[tokenIds[i]] = prices[i];
        }
    }

    function getPrice(uint256 tokenId) public view returns(uint256) {
        return _prices[tokenId];
    }

    //Buy function
    function buyToken(address to, uint256 tokenId, uint256 amount, bytes memory data) public payable {

        require(_prices[tokenId] > 0, 'B2OERC1155Buyer: wrong token id');
        require(amount <= 5, "B2OERC1155Buyer: can't buy more than 5 tokens");
        require(msg.value >= _prices[tokenId] * amount, "B2OERC1155Buyer: not enough ETH sent");

        //Transfer tokens
        _erc1155Contract.safeTransferFrom(
            owner(),
            to,
            tokenId,
            amount,
            data
        );

        //Record payment to signer's withdrawal balance
        _pendingWithdrawals += msg.value;
    }

    //BuyBatch function
    function buyTokenBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data) public payable {
        
        require(tokenIds.length == amounts.length, 'B2OERC1155Buyer: tokensIds and amounts length do not match');

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_prices[tokenIds[i]] > 0, 'B2OERC1155Buyer: wrong token id');
            require(amounts[i] <= 5, "B2OERC1155Buyer: can't buy more than 5 tokens");
            totalAmount += _prices[tokenIds[i]] * amounts[i];
        }
        require(msg.value >= totalAmount, "B2OERC1155Buyer: not enough ETH sent");

        //Transfer tokens
        _erc1155Contract.safeBatchTransferFrom(
            owner(),
            to,
            tokenIds,
            amounts,
            data
        );

        //Record payment to signer's withdrawal balance
        _pendingWithdrawals += msg.value;
    }


    //Transfers all pending withdrawal balance to the owner
    function withdraw() public onlyOwner {
        
        //Owner must be a payable address.
        address payable receiver = payable(msg.sender);

        uint amount = _pendingWithdrawals;

        //Set zero before transfer to prevent re-entrancy attack
        _pendingWithdrawals = 0;
        receiver.transfer(amount);
    }

    //Retuns the amount of Ether available to withdraw.
    function availableToWithdraw() public view onlyOwner returns (uint256) {
        return _pendingWithdrawals;
    }
}