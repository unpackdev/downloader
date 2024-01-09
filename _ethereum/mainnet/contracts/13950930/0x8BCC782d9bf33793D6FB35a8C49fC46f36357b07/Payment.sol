// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./PaymentVerifiable.sol";
import "./Ownable.sol";

contract PunkMunks is PaymentVerifiable, Ownable {
    uint256 tokenSold;

    /**
     * @dev owner fund: Address that revceive payment 
     * @dev amdin: Address that can sign for the user to make payment
     */
    address payable public ownerFund;
    address public admin;
    uint256 public totalSupply;

    //mapping store the tokens that are created
    mapping(uint256 => bool) tokens;

    /**
     * @dev Set address whose owner recieve payments from user
     */
    function setOwnerFund(address newOwnerFundAddress_) public onlyOwner {
        require(newOwnerFundAddress_ != address(0), "Invalid owner fund");
        ownerFund = payable(newOwnerFundAddress_);
    }

    /**
     * @notice only owner can set new admin
     */
    function setAdmin(address newAdmin_) public onlyOwner {
        admin = newAdmin_;
    }

    modifier onlyAuthorizer() {
        require(msg.sender == owner() || msg.sender == admin);
        _;
    }

  
    constructor() {
        ownerFund = payable(msg.sender); //initially set ownerfund to the payment contract creator
        admin = msg.sender; //initially set admin to the payment contract creator
        totalSupply = 10000; //Gallery only sells 10000 items
    }

    event PaymentSucceeded(
        address indexed buyer,
        address ownerFund,
        address nftAddress,
        uint256[] tokenId,
        uint256 price
    );

    /**
     * @dev buyer call this function
     */
    function makePayment(
        bytes memory signature_,
        address buyer_,
        address nftAddress_,
        uint256[] memory tokenId_,
        uint256 tokenPrice_
    ) public payable {
        require(msg.sender == buyer_, "Only Buyer can make payment");

        require(
            tokenSold + tokenId_.length <= totalSupply,
            "Token supply exceeded"
        );

        require(
            msg.value == tokenPrice_,
            "Msg value and token price are not matched"
        );

        // if any token id existed, revert
        for (uint256 i = 0; i < tokenId_.length; i++) {
            require(!isTokenExisted(tokenId_[i]), "TokenId existed");
        }

        address signer = verify(signature_, buyer_, nftAddress_, tokenId_, tokenPrice_);
        require( //accept payment with signing message from either owner or admin
            signer ==  owner() || signer == admin,
            "Signer is not admin or owner"
        );

        ownerFund.transfer(tokenPrice_);
        for (uint256 i = 0; i < tokenId_.length; i++) {
            tokens[tokenId_[i]] = true;
        }

        tokenSold += tokenId_.length;

        emit PaymentSucceeded(
            buyer_,
            ownerFund,
            nftAddress_,
            tokenId_,
            tokenPrice_
        );
    }

    /**
     * @dev unsold a token incase of error - mannualy
     */
    function unsoldToken(uint256 tokenId_) public onlyAuthorizer {
        require(tokens[tokenId_], "token is not sold yet");
        tokens[tokenId_] = false;
    }

    /**
     * @dev Give away case: mark token that are giveawayed from polygon
     */
    function setSoldToken(uint256[] memory tokenId_) public onlyAuthorizer {
        for (uint256 i = 0; i < tokenId_.length; i++) {
            tokens[tokenId_[i]] = true;
        }
    }

    function isTokenExisted(uint256 tokenId_) public view returns (bool) {
        return tokens[tokenId_];
    }
}