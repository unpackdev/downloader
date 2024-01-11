// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

abstract contract Ownable {
    error Ownable_NotOwner();
    error Ownable_NewOwnerZeroAddress();

    address private _owner;
    address public nominatedOwner;

    event OwnerNominated(address newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Ownable_NewOwnerZeroAddress();
        _transferOwnership(newOwner);
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Internal function without access restriction.
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function nominateNewOwner(address _nominatedOwner) external onlyOwner {
        nominatedOwner = _nominatedOwner;
        emit OwnerNominated(_nominatedOwner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        _owner = nominatedOwner;
        nominatedOwner = address(0);
        emit OwnershipTransferred(_owner, nominatedOwner);
    }
}
