// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

/*
* @title Ninety1
* @author lileddie.eth / Enefte Studio
*/

contract EnefteOwnership {
    
    mapping(address => bool) _dev;  
    address _owner;
    
    /**
     * @dev notice if called by any account other than the dev or owner.
     */
    modifier onlyDevOrOwner() {
        require(owner() == msg.sender || _dev[msg.sender], "Ownable: caller is not the owner or dev");
        _;
    }  

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Adds a new dev role user
     */
    function addDev(address _newDev) external onlyOwner {
        _dev[_newDev] = true;
    }

    /**
     * @notice Removes address from dev role
     */
    function removeDev(address _removeDev) external onlyOwner {
        delete _dev[_removeDev];
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        setOwner(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}