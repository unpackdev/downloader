// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";

import "./IMinted.sol";
import "./ITicket.sol";

error SaleInactive();
error SoldOut();
error InvalidPrice();
error ExceedQuota();
error WithdrawFailed();
error FreezeMint();

contract Seller is Ownable {

    uint256 public nextTokenId = 1;

    uint256 public allowlistPrice = 0.05 ether;
    uint256 public publicPrice = 0.07 ether;

    uint256 public constant MAX_MINT = 4;
    uint256 public constant MAX_SUPPLY = 2048;

    // 0: closed; 1: allowlist mint; 2: public mint
    uint8 public saleStage;

    address public beneficiary;

    ITicket public ticket;
    IMinted public token;

    bool public isDevMintFreeze;

    constructor(address ticket_) {
        ticket = ITicket(ticket_);
    }

    /**
     * Public functions
     */
    function allowlistMint(bytes[] calldata _signatures, uint256[] calldata spotIds)
        external
        payable
    {
        uint256 _nextTokenId = nextTokenId;
        // must be allowlist mint stage
        if (saleStage != 1) revert SaleInactive();
        // offset by 1 because we start at 1, and nextTokenId is incremented _after_ mint
        if (_nextTokenId + (spotIds.length - 1) > MAX_SUPPLY) revert SoldOut();
        // cannot mint exceed 4 catddles
        if (spotIds.length > MAX_MINT) revert ExceedQuota();
        if (msg.value < allowlistPrice * spotIds.length) revert InvalidPrice();

        for (uint256 i = 0; i < spotIds.length; i++) {
            // invalidate the spotId passed in
            ticket.claimAllowlistSpot(_signatures[i], msg.sender, spotIds[i]);
            token.authorizedMint(msg.sender, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }
        // update nextTokenId
        nextTokenId = _nextTokenId;
    }

    function publicMint(uint256 amount)
        external
        payable
    {
        uint256 _nextTokenId = nextTokenId;
        // must be public mint stage
        if (saleStage != 2) revert SaleInactive();
        // offset by 1 because we start at 1, and nextTokenId is incremented _after_ mint
        if (_nextTokenId + (amount - 1) > MAX_SUPPLY) revert SoldOut();
        // cannot mint exceed 4 catddles
        if (amount > MAX_MINT) revert ExceedQuota();
        if (msg.value < publicPrice * amount) revert InvalidPrice();

        for (uint256 i = 0; i < amount; i++) {
            token.authorizedMint(msg.sender, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }
        // update nextTokenId
        nextTokenId = _nextTokenId;
    }

    /**
     *  OnlyOwner functions
     */

    function setToken(address tokenAddress) public onlyOwner {
        token = IMinted(tokenAddress);
    }

    function setTicket(address ticket_) public onlyOwner {
        ticket = ITicket(ticket_);
    }

    function setSaleStage(uint8 stage) public onlyOwner {
        saleStage = stage;
    }

    function setAllowlistPrice(uint256 price) public onlyOwner {
        allowlistPrice = price;
    }

    function setPublicPrice(uint256 price) public onlyOwner {
        publicPrice = price;
    }

    function freezeDevMint() public onlyOwner {
        // freeze dev mint forever
        isDevMintFreeze = true;
    }

    function devMint(address receiver, uint256 amount) public onlyOwner {
        if (isDevMintFreeze) revert FreezeMint();
        uint256 _nextTokenId = nextTokenId;
        if (_nextTokenId + (amount - 1) > MAX_SUPPLY) revert SoldOut();

        for (uint256 i = 0; i < amount; i++) {
            token.authorizedMint(receiver, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }
        nextTokenId = _nextTokenId;
    }

    function setBeneficiary(address beneficiary_) public onlyOwner {
        beneficiary = beneficiary_;
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(beneficiary != address(0), "Cannot withdraw to zero address");
        require(amount <= address(this).balance, "Cannot withdraw exceed balance");
        (bool success, ) = beneficiary.call{value: amount}("");
        if (!success) {
            revert WithdrawFailed();
        }
    }
   
}