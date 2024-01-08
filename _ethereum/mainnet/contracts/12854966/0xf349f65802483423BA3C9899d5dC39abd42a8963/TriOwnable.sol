// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

abstract contract TriOwnable {
    address[3] private _owners;

    event OwnershipUpdated(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owners[0] = msg.sender;
        emit OwnershipUpdated(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner(uint8 index) public view virtual returns (address) {
        return _owners[index];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(
            _owners[0] == msg.sender ||
                _owners[1] == msg.sender ||
                _owners[2] == msg.sender,
            "caller is not the owner"
        );
        _;
    }

    function removeOwner(uint8 index) public virtual onlyOwner {
        emit OwnershipUpdated(_owners[index], address(0));
        _owners[index] = address(0);
    }

    function setOwner(uint8 index, address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipUpdated(_owners[index], newOwner);
        _owners[index] = newOwner;
    }
}
