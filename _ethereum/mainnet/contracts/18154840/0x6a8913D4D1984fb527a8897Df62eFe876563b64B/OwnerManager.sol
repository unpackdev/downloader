// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title OwnerManager
 * @notice A contract managing owner.
 */
abstract contract OwnerManager {
    
    event OwnershipTransferRequested(address indexed from, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    
    address internal constant ADDRESS_PTR = address(1);

    address internal owner;
    address internal pendingOwner;
    
    /**
     * @notice Set the initial onwer. To be called by KnightSafe setup only.
     * @param _owner The initial owner of the KnightSafe
     */
    function setupOwner(address _owner) internal {
        require(owner == address(0), "can only setup once");
        require(_owner != address(0), "owner cannot be null address");
        owner = _owner;
    }


    /**
     * @dev Only trader can call functions marked by this modifier. 
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Owner only");
        _;
    }

    /**
     * @notice Get the owner of the KnightSafe.
     * @return The owner of the KnightSafe.
     */
    function getOwner() public view returns (address) {
        return owner;
    }
    
    /**
     * @notice Get the pending owner of the KnightSafe.
     * @return The pending owner of the KnightSafe.
     */
    function getPendingOwner() public view returns (address) {
        return pendingOwner;
    }

    /**
     * @notice Step 1/2 of transferring ownership to another address.
     * @param newOwner The new proposed owner of the KnightSafe.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        pendingOwner = newOwner;
        emit OwnershipTransferRequested(owner, newOwner);
    }

    /**
     * @notice Step 2/2 of transferring ownership to another address.
     */
    function acceptOwnership() external {
        require(msg.sender == pendingOwner, "Not proposed new owner");
        address exOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);
        emit OwnershipTransferred(exOwner, owner);
    }
}
