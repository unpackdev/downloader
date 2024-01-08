// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./IERC721Receiver.sol";
import "./IOCProtectionSeller.sol";
import "./IUUNNRegistry.sol";
import "./MErc20Interface.sol";
import "./EIP20Interface.sol";
import "./MProtection.sol";

/**
 * @title MOAR's LendingRouter Contract
 * @notice Helps to buy C-OP, deposit it and make a borrow in one transaction
 * @author MOAR
 */
contract LendingRouter is IERC721Receiver, Ownable{

    /**
     * @notice Event emitted when C-OP is received by LendingRouter contract
     */
    event ProtectionReceived(address operator, address from, uint256 tokenId);

    IUUNNRegistry private protectionToken;
    MProtection private cProtectionToken;
    EIP20Interface private baseCurrency;

    /**
     * @notice LendingRouter constructor 
     * @param _protectionToken Address of C-OP contract
     * @param _cProtectionToken Address of MProtection contract
     * @param _baseCurrency Address of base token contract used to pay premium
     */
    constructor(address _protectionToken, address _cProtectionToken, address _baseCurrency) public {
        protectionToken = IUUNNRegistry(_protectionToken);
        cProtectionToken = MProtection(_cProtectionToken);
        baseCurrency = EIP20Interface(_baseCurrency);
    }

    /**
     * @notice Set new C-OP contract address
     * @param _protectionToken Address of C-OP contract
     */
    function setProtection(address _protectionToken) onlyOwner public {
        protectionToken = IUUNNRegistry(_protectionToken);
    }

    /**
     * @notice Set new MProtection contract address
     * @param _cProtectionToken Address of MProtection contract
     */
    function setCProtection(address _cProtectionToken) onlyOwner public {
        cProtectionToken = MProtection(_cProtectionToken);
    }

    /**
     * @notice Set new base token contract address
     * @param _baseCurrency Address of base token contract
     */
    function setBaseCurrency(address _baseCurrency) onlyOwner public {
        baseCurrency = EIP20Interface(_baseCurrency);
    }

    /**
     * @notice Allows admin to rescue tokens lost on LendingRouter contract (which shoundn't happen)
     * @param to Address of base token contract
     * @param amount Amount of token to rescue
     */
    function rescueBaseCurrency(address to, uint256 amount) onlyOwner public {
        baseCurrency.transfer(to, amount);
    }

    /**
     * @notice Allows admin to rescue tokens lost on LendingRouter contract (which shoundn't happen)
     * @param protectionSeller Address of C-OP Protection Seller contract
     * @param merc20Token MToken synthetic of token that should be borrowed
     * @param borrowAmount Amount of tokens to borrow
     * @param pool Address of pool passed to Protection Seller contract
     * @param validTo Lifetime period passed to Protection Seller contract
     * @param amount Amount of tokens that will be covered by C-OP 
     * @param strike Strike price passed to C-OP Protection Seller contract
     * @param deadline Expiration time of C-OP passed to Protection Seller contract
     * @param data Additional data passed to Protection Seller contract
     * @param signature Signature used to validate data passed to Protection Seller contract
     */
    function purchaseProtectionAndMakeBorrow(IOCProtectionSeller protectionSeller, MErc20Interface merc20Token, uint256 borrowAmount, address pool, uint256 validTo, uint256 amount, uint256 strike, uint256 deadline, uint256[11] memory data, bytes memory signature) public {
        baseCurrency.transferFrom(msg.sender, address(this), data[1]);
        baseCurrency.approve(address(protectionSeller), data[1]);
        protectionSeller.create(pool, validTo, amount, strike, deadline, data, signature);
        uint256 underlyingTokenId = data[0];
        protectionToken.approve(address(cProtectionToken), underlyingTokenId);
        
        uint cProtectionId = cProtectionToken.mintFor(underlyingTokenId, msg.sender);
        cProtectionToken.lockProtectionValue(cProtectionId, 0);
        merc20Token.borrowFor(msg.sender, borrowAmount);
    }

    /**
     * @notice Deposits C-OP, mints MProtection token and optimizes it
     * @param underlyingTokenId Id of C-OP token that will be deposited
     */
    function depositProtectionAndOptimize(uint256 underlyingTokenId) public {
        require(protectionToken.ownerOf(underlyingTokenId) == msg.sender, "Only owner of C-OP can call this action");
        protectionToken.transferFrom(msg.sender, address(this), underlyingTokenId);
        protectionToken.approve(address(cProtectionToken), underlyingTokenId);
        uint cProtectionId = cProtectionToken.mintFor(underlyingTokenId, msg.sender);
        cProtectionToken.lockProtectionValue(cProtectionId, 0);
    }

    /**
     * @notice Called when contract receives ERC-721 token
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external override returns (bytes4){
        emit ProtectionReceived(operator, from, tokenId);
        return this.onERC721Received.selector;
    }

}