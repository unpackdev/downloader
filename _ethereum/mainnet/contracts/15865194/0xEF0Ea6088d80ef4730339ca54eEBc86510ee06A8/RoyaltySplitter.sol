// SPDX-License-Identifier: MIT
// Derived and inspired by CashCowsS2Treasury.sol (https://github.com/Cash-Cows/)
// dev: hello@criox.io (@CrioxIO)
// git: https://github.com/criox-io
//    _   _   _   _   _   _   _   _  
//   / \ / \ / \ / \ / \ / \ / \ / \ 
//  ( c | r | i | o | x | . | i | o )
//   \_/ \_/ \_/ \_/ \_/ \_/ \_/ \_/ 
pragma solidity ^0.8.17;

import "./IERC721Enumerable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Address.sol";
import "./console.sol";
error InvalidCall();

contract RoyaltySplitter is ReentrancyGuard, Context {
    IERC721Enumerable COLLECTION;

    //total amount of ETH released
    uint256 private _ethTotalReleased;
    //amount of ETH released per NFT token id
    mapping(uint256 => uint256) private _ethReleased;

    //total amount of ERC20 released
    mapping(IERC20 => uint256) private _erc20TotalReleased;
    //amount of ERC20 released per NFT token id
    mapping(IERC20 => mapping(uint256 => uint256)) private _erc20Released;

    event PaymentReceived(address sender, uint256 value);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(
        IERC20 indexed token,
        address to,
        uint256 amount
    );

    constructor(IERC721Enumerable _collection) payable {
        COLLECTION = _collection;
    }

    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function releaseable(uint256 tokenId) public view returns (uint256) {
        return
            _pendingPayment(
                address(this).balance + totalReleased(),
                released(tokenId)
            );
    }

    function releaseableBatch(uint256[] memory tokenIds)
        external
        view
        returns (uint256 totalReleaseable)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //get payment and should be more than zero
            totalReleaseable += releaseable(tokenIds[i]);
        }
    }

    function releaseableErc20(IERC20 token, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return
            _pendingPayment(
                token.balanceOf(address(this)) + totalReleased(token),
                releasedErc20(token, tokenId)
            );
    }

    function releaseableErc20Batch(IERC20 token, uint256[] memory tokenIds)
        external
        view
        returns (uint256 totalReleaseable)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //get payment and should be more than zero
            totalReleaseable += releaseableErc20(token, tokenIds[i]);
        }
    }

    function released(uint256 tokenId) public view returns (uint256) {
        return _ethReleased[tokenId];
    }

    function releasedErc20(IERC20 token, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _erc20Released[token][tokenId];
    }

    function totalReleased() public view returns (uint256) {
        return _ethTotalReleased;
    }

    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    function payee(uint256 tokenId) public view returns (address) {
        return COLLECTION.ownerOf(tokenId);
    }

    function release(uint256 tokenId) external nonReentrant {
        //get account and should be the sender
        address account = payee(tokenId);
        if (account != _msgSender()) revert InvalidCall();
        //get payment and should be more than zero
        uint256 payment = releaseable(tokenId);
        if (payment == 0) revert InvalidCall();
        //add released payment
        _ethReleased[tokenId] += payment;
        _ethTotalReleased += payment;
        //send it off.. buh bye!
        Address.sendValue(payable(account), payment);
        //let everyone know what happened
        emit PaymentReleased(account, payment);
    }

    function ownsAll(address owner, uint256[] memory tokenIds)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (owner != COLLECTION.ownerOf(tokenIds[i])) {
                return false;
            }
        }

        return true;
    }

    function releaseBatch(uint256[] memory tokenIds) external nonReentrant {
        //get account and should be the owner
        address account = _msgSender();
        if (!ownsAll(_msgSender(), tokenIds)) revert InvalidCall();

        uint256 payment;
        uint256 totalPayment;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //get payment and should be more than zero
            payment = releaseable(tokenIds[i]);
            //skip if noting is releaseable
            if (payment == 0) continue;
            //add released payment
            _ethReleased[tokenIds[i]] += payment;
            //add to total payment
            totalPayment += payment;
        }
        //if no payments are due
        if (totalPayment == 0) revert InvalidCall();
        //add released payment
        _ethTotalReleased += totalPayment;
        //send it off.. buh bye!
        Address.sendValue(payable(account), totalPayment);
        //let everyone know what happened
        emit PaymentReleased(account, totalPayment);
    }

    function releaseErc20(IERC20 token, uint256 tokenId) external nonReentrant {
        //get account and should be the sender
        address account = payee(tokenId);
        if (account != _msgSender()) revert InvalidCall();
        //get payment and should be more than zero
        uint256 payment = releaseableErc20(token, tokenId);
        if (payment == 0) revert InvalidCall();
        //add released payment
        _erc20Released[token][tokenId] += payment;
        _erc20TotalReleased[token] += payment;
        //send it off.. buh bye!
        SafeERC20.safeTransfer(token, payable(account), payment);
        //let everyone know what happened
        emit ERC20PaymentReleased(token, account, payment);
    }

    function releaseErc20Batch(IERC20 token, uint256[] memory tokenIds)
        external
        nonReentrant
    {
        //get account and should be the owner
        address account = _msgSender();
        if (!ownsAll(_msgSender(), tokenIds)) revert InvalidCall();

        uint256 payment;
        uint256 totalPayment;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            //get payment and should be more than zero
            payment = releaseableErc20(token, tokenIds[i]);
            //skip if noting is releaseable
            if (payment == 0) continue;
            //add released payment
            _erc20Released[token][tokenIds[i]] += payment;
            //add to total payment
            totalPayment += payment;
        }
        //if no payments are due
        if (totalPayment == 0) revert InvalidCall();
        //add released payment
        _erc20TotalReleased[token] += totalPayment;
        //send it off.. buh bye!
        SafeERC20.safeTransfer(token, payable(account), totalPayment);
        //let everyone know what happened
        emit ERC20PaymentReleased(token, account, payment);
    }

    function _pendingPayment(uint256 totalReceived, uint256 alreadyReleased)
        private
        view
        returns (uint256)
    {
        uint256 amount = totalReceived / COLLECTION.totalSupply();
        if (amount < alreadyReleased) return 0;
        return amount - alreadyReleased;
    }
}
