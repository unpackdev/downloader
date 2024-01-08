// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";

/**
 * @title ReceivePayments
 * @dev Keep track of Obscura pass payments
 */
contract ReceivePayments is Ownable {
    address payable treasury;
    mapping(uint256 => uint256) public passCost;
    mapping(uint256 => uint256) public userCount; // how many passes have been purchased
    mapping(uint256 => uint256) public maxCount;
    uint256 nextPassId;

    constructor() {
        treasury = payable(0xb94404C28FeAA59f8A3939d53E6b2901266Fa529);
    }

    event PaymentReceived(
        address sender,
        uint256 passId,
        uint256 value,
        uint256 numberOfPasses
    );
    event NewPassCreated(uint256 passId, uint256 cost);
    event TreasuryAddressChanged(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev receive payment for each of 3 Pass types
     * @param passId corresponds with type of Pass e.g. Curated SP1 (ID: 1), Foundry SP1 (ID: 2), Community SP1 (ID: 3)
     */
    function receivePassPayment(uint256 passId, uint256 numberOfPasses)
        public
        payable
    {
        require(
            (userCount[passId] + numberOfPasses) <= maxCount[passId],
            "Pass subscription is full."
        );
        userCount[passId] = userCount[passId] + numberOfPasses;

        // check that correct amount was sent
        require(
            msg.value == passCost[passId] * numberOfPasses,
            "Incorrect ETH amount provided."
        );

        (bool sent, ) = treasury.call{value: msg.value}("");

        emit PaymentReceived(msg.sender, passId, msg.value, numberOfPasses);

        require(sent, "Failed to send Ether");
    }

    /**
     * @dev create pass type
     * @param maxUsers max number of payments that can be made.
     * @param cost price of pass
     */
    function createPass(uint256 maxUsers, uint256 cost) public onlyOwner {
        passCost[nextPassId] = cost;
        maxCount[nextPassId] = maxUsers;

        emit NewPassCreated(nextPassId, cost);
        nextPassId++;
    }

    function changeTreasuryAddress(address newTreasuryAddress)
        public
        onlyOwner
    {
        emit TreasuryAddressChanged(treasury, newTreasuryAddress);
        treasury = payable(newTreasuryAddress);
    }
}
