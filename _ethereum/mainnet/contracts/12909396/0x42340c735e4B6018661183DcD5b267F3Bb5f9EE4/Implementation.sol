/*
    Copyright 2021 Empty Set Squad <emptysetsquad@protonmail.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

import "./Address.sol";
import "./Interfaces.sol";

/**
 * @title Implementation
 * @notice Common functions and accessors across upgradeable, ownable contracts
 */
contract Implementation {

    /**
     * @notice Emitted when {owner} is updated with `newOwner`
     */
    event OwnerUpdate(address newOwner);

    /**
     * @notice Emitted when {registry} is updated with `newRegistry`
     */
    event RegistryUpdate(address newRegistry);

    /**
     * @dev Storage slot with the address of the current implementation
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1
     */
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the admin of the contract
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
     */
    bytes32 private constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @notice Storage slot with the owner of the contract
     */
    bytes32 private constant OWNER_SLOT = keccak256("emptyset.v2.implementation.owner");

    /**
     * @notice Storage slot with the owner of the contract
     */
    bytes32 private constant REGISTRY_SLOT = keccak256("emptyset.v2.implementation.registry");

    /**
     * @notice Storage slot with the owner of the contract
     */
    bytes32 private constant NOT_ENTERED_SLOT = keccak256("emptyset.v2.implementation.notEntered");

    // UPGRADEABILITY

    /**
     * @notice Returns the current implementation
     * @return Address of the current implementation
     */
    function implementation() external view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @notice Returns the current proxy admin contract
     * @return Address of the current proxy admin contract
     */
    function admin() external view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    // REGISTRY

    /**
     * @notice Updates the registry contract
     * @dev Owner only - governance hook
     *      If registry is already set, the new registry's timelock must match the current's
     * @param newRegistry New registry contract
     */
    function setRegistry(address newRegistry) external onlyOwner {
        IRegistry registry = registry();

        // New registry must have identical owner
        require(newRegistry != address(0), "Implementation: zero address");
        require(
            (address(registry) == address(0) && Address.isContract(newRegistry)) ||
                IRegistry(newRegistry).timelock() == registry.timelock(),
            "Implementation: timelocks must match"
        );

        _setRegistry(newRegistry);

        emit RegistryUpdate(newRegistry);
    }

    /**
     * @notice Updates the registry contract
     * @dev Internal only
     * @param newRegistry New registry contract
     */
    function _setRegistry(address newRegistry) internal {
        bytes32 position = REGISTRY_SLOT;
        assembly {
            sstore(position, newRegistry)
        }
    }

    /**
     * @notice Returns the current registry contract
     * @return Address of the current registry contract
     */
    function registry() public view returns (IRegistry reg) {
        bytes32 slot = REGISTRY_SLOT;
        assembly {
            reg := sload(slot)
        }
    }

    // OWNER

    /**
     * @notice Takes ownership over a contract if none has been set yet
     * @dev Needs to be called initialize ownership after deployment
     *      Ensure that this has been properly set before using the protocol
     */
    function takeOwnership() external {
        require(owner() == address(0), "Implementation: already initialized");

        _setOwner(msg.sender);

        emit OwnerUpdate(msg.sender);
    }

    /**
     * @notice Updates the owner contract
     * @dev Owner only - governance hook
     * @param newOwner New owner contract
     */
    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(this), "Implementation: this");
        require(Address.isContract(newOwner), "Implementation: not contract");

        _setOwner(newOwner);

        emit OwnerUpdate(newOwner);
    }

    /**
     * @notice Updates the owner contract
     * @dev Internal only
     * @param newOwner New owner contract
     */
    function _setOwner(address newOwner) internal {
        bytes32 position = OWNER_SLOT;
        assembly {
            sstore(position, newOwner)
        }
    }

    /**
     * @notice Owner contract with admin permission over this contract
     * @return Owner contract
     */
    function owner() public view returns (address o) {
        bytes32 slot = OWNER_SLOT;
        assembly {
            o := sload(slot)
        }
    }

    /**
     * @dev Only allow when the caller is the owner address
     */
    modifier onlyOwner {
        require(msg.sender == owner(), "Implementation: not owner");

        _;
    }

    // NON REENTRANT

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(notEntered(), "Implementation: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _setNotEntered(false);

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _setNotEntered(true);
    }

    /**
     * @notice The entered status of the current call
     * @return entered status
     */
    function notEntered() internal view returns (bool ne) {
        bytes32 slot = NOT_ENTERED_SLOT;
        assembly {
            ne := sload(slot)
        }
    }

    /**
     * @notice Updates the entered status of the current call
     * @dev Internal only
     * @param newNotEntered New entered status
     */
    function _setNotEntered(bool newNotEntered) internal {
        bytes32 position = NOT_ENTERED_SLOT;
        assembly {
            sstore(position, newNotEntered)
        }
    }

    // SETUP

    /**
     * @notice Hook to surface arbitrary logic to be called after deployment by owner
     * @dev Governance hook
     *      Does not ensure that it is only called once because it is permissioned to governance only
     */
    function setup() external onlyOwner {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _setNotEntered(true);
        _setup();
    }

    /**
     * @notice Override to provide addition setup logic per implementation
     */
    function _setup() internal { }
}
