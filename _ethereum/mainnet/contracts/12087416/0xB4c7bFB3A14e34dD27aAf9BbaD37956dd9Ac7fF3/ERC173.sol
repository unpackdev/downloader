// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//import "./ERC165.sol";

/// @title ERC-173 Contract Ownership Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-173.md
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 /* is ERC165 */ {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @notice Set the address of the new owner of the contract
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

abstract contract ERC173 is IERC173 {
    address private _owner;

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner(), "Must be owner");
        _;
    }

    function owner() override public view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) virtual override public onlyOwner() {
        _transferOwnership(_newOwner);
    }

    function _transferOwnership(address _newOwner) internal {
        address previousOwner = owner();
	_owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }
}
