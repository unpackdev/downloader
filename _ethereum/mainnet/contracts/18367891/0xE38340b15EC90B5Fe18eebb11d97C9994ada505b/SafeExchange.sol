// Copyright (c) Peter Robinson 2023
// SPDX-License-Identifier: BSD
// Use 0.7.6 to be compatible with Open Zeppelin 3.4.0
pragma solidity ^0.7.6;

import "./AccessControl.sol";

/**
 * SafeExchange allows a contract with AccessControl to be sold. This contract is 
 * deployed by the buyer. The seller then calls the exchange function.
 */
contract SafeExchange {
    // The only admin role of the contract. All other roles, if they exist, 
    // should be revoked. The code in this contract does not check that this 
    // has occurred however.
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    // Owner of this contract and account wanting to buy the contract that is for sale.
    address public buyer;

    // Account wanting to sell the contract that is for sale.
    address public seller;

    // Administrator that will have DEFAULT_ADMIN_ROLE after the exchange.
    address public newAdmin;

    // Amount offered in exchange for the contract being sold.
    uint256 public offer;

    // Bonus amount available.
    uint256 public bonus;

    // Contract that is to be exchanged
    AccessControl public contractForSale;

    // Emitted when the exchange has been completed.
    event Exchanged(address seller);

    // Regained ownerhsip as the exchange failed for some reason.
    event RegainedOwnership(address seller);

    // Modifier to only allow the buyer to execute a function.
    modifier onlyBuyer() {
        require(msg.sender == buyer, "Not buyer");
        _;
    }

    // Modifier to only allow the seller to execute a function.
    modifier onlySeller() {
        require(msg.sender == seller, "Not seller");
        _;
    }


    /** 
     * @notice Buyer creates the contract, sending the offered and bonus amount as the transaction value.
     * @param _newAdmin Administrator to be given sole ownership on completion of the sale.
     * @param _seller Account selling the contract.
     * @param _contractForSale The contract which is to be bought.
     * @param _offer The amount offered for sale of the contract. msg.value - offer is a bonus amount.
     */
    constructor(address _newAdmin, address _seller, address _contractForSale, uint256 _offer) payable {
        require(_offer <= msg.value, "Offer smaller than value");
        buyer = msg.sender;
        seller = _seller;
        newAdmin = _newAdmin;
        contractForSale = AccessControl(_contractForSale);
        offer = _offer;
        bonus = msg.value - offer;
    }

    /** 
     * @notice Seller calls this, to exchange control of admin rights for the balance of this contract.
     * @dev This contract must have been granted DEFAULT_ADMIN_ROLE and be the only admin prior to calling 
     *  this function.
     * @param _expectedAmount The expected sale price in Wei. This is needed to mitigate front running. 
     *     That is, the balance of this contract changing immediately prior to this function being called.
     */
    function exchange(uint256 _expectedAmount) external onlySeller {
        // Prevent contract accounts calling this. This prevents MultiCall contracts possibly 
        // doing something "extra" in the same transaction.
        require(msg.sender == tx.origin, "Not an EOA");

        // Ensure the buyer doesn't front run this transaction reducing the amount offered
        uint256 price = offer;
        require(_expectedAmount <= price, "Insufficient funds");

        // Check that the number of admins is 1. The issue that we are guarding against is there being 
        // other accounts with DEFAULT_ADMIN_ROLE, and one of them immediately after this call, revoking 
        // the  DEFAULT_ADMIN_ROLE role of the newAdmin account. 
        // NOTE: If there other classes of admins, they should be revoked prior to this call.
        // This revocation is not checked for in this code.
        uint256 numAdmins = contractForSale.getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        require(numAdmins == 1, "Too many admins");

        // Grant role DEFAULT_ADMIN_ROLE to the newAdmin.
        contractForSale.grantRole(DEFAULT_ADMIN_ROLE, newAdmin);

        // Renounce DEFAULT_ADMIN_ROLE role for msg.sender
        contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, address(this));

        // Send price to msg.sender
        transferMoney(msg.sender, price);

        // Offer has been paid out. No more offer is available.
        offer = 0;

        // Indicate exchange completed.
        emit Exchanged(msg.sender);
    }

    /**
     * @notice If the seller transfers admin rights for the contract that is for sale 
     *  to this contract, and then either they change their mind before called exchange, 
     *  or exchange fails for some reason, this function allows them to regain control 
     *  of the contract for sale. 
     * @dev This function will fail after exchange has been called because this contract 
     *  will not be an admin at that point.
     */
    function regainOwnership() external onlySeller {
        contractForSale.grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        contractForSale.renounceRole(DEFAULT_ADMIN_ROLE, address(this));
        emit RegainedOwnership(msg.sender);
    }


    /**
     * @notice Pay a bonus payment to the seller.
     * @dev For this to work, the increaseOffer funcion needs to be called 
     *      to add value to the contract.
     */
    function payBonusPayment() external onlyBuyer() {
        transferMoney(seller, bonus);
        bonus = 0;
    }


    /**
     * @notice Buyer (or anyone) calls this function to increase the offer.
     */
    function increaseOffer() external payable {
        offer += msg.value;
    }

    /**
     * @notice Buyer calls this function to decrease the offer.
     * @param _amount Amount to decrease in Wei.
     */
    function decreaseOffer(uint256 _amount) external payable onlyBuyer() {
        require(_amount <= offer, "Amount greater than offer");
        offer -= _amount;
        transferMoney(msg.sender, _amount);
    }

    /**
     * @notice Buyer (or anyone) calls this function to increase the bonus.
     */
    function increaseBonus() external payable {
        bonus += msg.value;
    }

    /**
     * @notice Buyer calls this function to decrease the bonus.
     * @param _amount Amount to decrease in Wei.
     */
    function decreaseBonus(uint256 _amount) external payable onlyBuyer() {
        require(_amount <= bonus, "Amount greater than bonus");
        bonus -= _amount;
        transferMoney(msg.sender, _amount);
    }


    /**
     * @notice Transfer money.
     * @param _to Recipient of the value.
     * @param _amount Amount to transfer in wei.
     */
    function transferMoney(address _to, uint256 _amount) private {
        (bool success, ) = payable(_to).call{value: _amount}("");
        require(success, "Transfer failed");
    }
}