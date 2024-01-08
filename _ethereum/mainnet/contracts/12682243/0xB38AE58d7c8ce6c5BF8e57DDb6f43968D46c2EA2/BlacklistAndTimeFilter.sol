// SPDX-License-Identifier: Business Source License 1.1 see LICENSE.txt
pragma solidity ^0.8.0;

import "./Ownable.sol";

import "./ApprovalInterface.sol";

import "./ClipperPool.sol";

contract BlacklistAndTimeFilter is Ownable, ApprovalInterface {

    mapping (address => bool) public blocked;
    uint public minDays;
    bool public swapsAllowed;
    bool public depositsAllowed;

    ClipperPool public theExchange;

    // exclusiveDepositAddress is 0 if deposits can come from anywhere
    address public exclusiveDepositAddress;

    modifier anySigner() {
        require(msg.sender==theExchange.owner() || msg.sender==theExchange.triage(), "Clipper: Only owner or triage");
        _;
    }

    modifier onlyPoolOwner(){
        require(msg.sender==theExchange.owner(), "Clipper: Only owner");
        _;
    }

    constructor() {
        swapsAllowed = true;
        depositsAllowed = true;
        // Unique, checksum-repaired OFAC blocked ETH wallets ASOF June 7, 2021
        blocked[address(0x1da5821544e25c636c1417Ba96Ade4Cf6D2f9B5A)] = true;
        blocked[address(0x72a5843cc08275C8171E582972Aa4fDa8C397B2A)] = true;
        blocked[address(0x7Db418b5D567A4e0E8c59Ad71BE1FcE48f3E6107)] = true;
        blocked[address(0x7F19720A857F834887FC9A7bC0a0fBe7Fc7f8102)] = true;
        blocked[address(0x7F367cC41522cE07553e823bf3be79A889DEbe1B)] = true;
        blocked[address(0x8576aCC5C05D6Ce88f4e49bf65BdF0C62F91353C)] = true;
        blocked[address(0x901bb9583b24D97e995513C6778dc6888AB6870e)] = true;
        blocked[address(0x9F4cda013E354b8fC285BF4b9A60460cEe7f7Ea9)] = true;
        blocked[address(0xA7e5d5A720f06526557c513402f2e6B5fA20b008)] = true;
        blocked[address(0xd882cFc20F52f2599D84b8e8D58C7FB62cfE344b)] = true;
    }

    // Fire exactly once after deployment
    function setPoolAddress(address payable poolAddress) external onlyOwner {
        theExchange = ClipperPool(poolAddress);
        renounceOwnership();
    }

    function approveSwap(address recipient) external override view returns (bool){
        return swapsAllowed && !blocked[recipient];
    }

    function _exclusiveDepositAddressNotSet() internal view returns (bool) {
        return exclusiveDepositAddress == address(0);
    }

    function _depositSenderAllowed(address depositor) internal view returns (bool) {
        return _exclusiveDepositAddressNotSet() || (exclusiveDepositAddress==depositor);
    }

    function depositAddressAllowed(address depositor) internal view returns (bool) {
        return depositsAllowed && !blocked[depositor] && _depositSenderAllowed(depositor);
    }

    function approveDeposit(address depositor, uint nDays) external override view returns (bool){
        return depositAddressAllowed(depositor) && (nDays >= minDays);
    }

    function allowSwaps() external onlyPoolOwner {
        swapsAllowed = true;
    }

    function denySwaps() external anySigner {
        swapsAllowed = false;
    }

    function setExclusiveDepositAddress(address newAddress) external onlyPoolOwner {
        exclusiveDepositAddress = newAddress;
    }

    function allowDeposits() external onlyPoolOwner {
        depositsAllowed = true;
    }

    function denyDeposits() external onlyPoolOwner {
        depositsAllowed = false;
    }

    function blockAddress(address blockMe) external onlyPoolOwner {
        blocked[blockMe] = true;
    }

    function unblockAddress(address unblockMe) external onlyPoolOwner {
        delete blocked[unblockMe];
    }

    function modifyMinDays(uint newMinDays) external onlyPoolOwner {
        minDays = newMinDays;
    }
}
