// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract MasterCaller {
    address private _master;

    event MastershipTransferred(address indexed previousMaster, address indexed newMaster);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _master = msg.sender;
        emit MastershipTransferred(address(0), _master);
    }

    /**
     * @dev Returns the address of the current MasterCaller.
     */
    function masterCaller() public view returns (address) {
        return _master;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyMasterCaller() {
        require(_master == msg.sender, "Master: caller is not the master");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferMastership(address newMaster) public virtual onlyMasterCaller {
        require(newMaster != address(0), "Master: new owner is the zero address");
        emit MastershipTransferred(_master, newMaster);
        _master = newMaster;
    }
}