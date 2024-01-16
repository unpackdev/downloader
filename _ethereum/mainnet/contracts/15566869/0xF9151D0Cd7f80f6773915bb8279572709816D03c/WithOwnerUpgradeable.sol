//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";

contract WithOwnerUpgradeable is Initializable,ContextUpgradeable {
    address internal _owner;

    function __WithOwner_init(address owner_) internal onlyInitializing {
        __WithOwner_init_unchained(owner_);
    }

    function __WithOwner_init_unchained(address owner_) internal onlyInitializing {
        _owner = owner_;
    }

    /// @dev Emits when the contract owner is changed.
    /// @param oldOwner The address of the previous owner.
    /// @param newOwner The address of the new owner.
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_msgSender() == _owner, "ADMIN_ONLY");
        _;
    }

    /// @dev Get the current owner of this contract.
    /// @return The current owner of this contract.
    function getOwner() external view returns (address) {
        return _owner;
    }

    /// @dev Change the owner to be `newOwner`.
    /// @param newOwner The address of the new owner.
    function changeOwner(address newOwner) external onlyOwner {
        address owner = _owner;
        emit OwnerChanged(owner, newOwner);
        _owner = newOwner;
    }
}
