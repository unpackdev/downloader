//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./Auth.sol";


interface IVesting {
    function transferLockOwnership(uint256 _lockID, address _newOwner) external;
    function LOCKS(uint _lockID) external view returns (address, uint, uint, uint, uint, uint, address, address);
    function NONCE() external view returns (uint);
}

contract VestingEscrow is Auth {


    uint public purchasePrice = 34.7 ether;
    address public unicryptVesting = address(0xDba68f07d1b7Ca219f78ae8582C213d975c25cAf);
    uint public lockId;
    address public buyer;

    constructor(address buyer_)
    Auth(msg.sender, Authority(address(0))){
        buyer = buyer_;
    }

    function buy() external payable {
        if (buyer != address(0)) {
            require(msg.sender == buyer, "you are not the right purchaser");
        }
        require(msg.value == purchasePrice, "invalid purchase price");
        //no need for owner checks as the following will fail if escrow is not owner
        IVesting(unicryptVesting).transferLockOwnership(lockId, payable(msg.sender));
        owner.call{value:msg.value, gas: gasleft()}("");
    }

    function setPurchasePrice(uint purchasePrice_) requiresAuth external {
        purchasePrice = purchasePrice_;
    }

    function setBuyer(address buyer_) requiresAuth external {
        buyer = buyer_;
    }

    function setLockID(uint newLockID_) requiresAuth external {
        lockId = newLockID_;
    }

    function reclaim() requiresAuth external {
        //no need for owner checks as the following will fail if escrow is not owner
        IVesting(unicryptVesting).transferLockOwnership(lockId, payable(owner));
    }

}
