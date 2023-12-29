// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Proxy.sol";

contract OrionProxy is  Proxy
{
    /**
    * @dev Emitted when the implementation is upgraded.
    * @param implementation Address of the new implementation.
    */
    event Upgraded(address indexed implementation);

    /**
    * @dev Emitted when the administration has been transferred.
    * @param previousAdmin Address of the previous admin.
    * @param newAdmin Address of the new admin.
    */
    event AdminChanged(address previousAdmin, address newAdmin);

    constructor()
    {
        assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        assert(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1));

        _setAdmin(msg.sender);
    }

    /**
    * @dev Upgrade the backing implementation of the proxy.
    * Only the admin can call this function.
    * @param newImplementation Address of the new implementation.
    */
    function upgradeTo(address newImplementation) external
    {
        require(msg.sender == _admin(),"Need only owner access");

        _setImplementation(newImplementation);
    }

    /**
    * @dev Changes the admin of the proxy.
    * Only the current admin can call this function.
    * @param newAdmin Address to transfer proxy administration to.
    */
    function changeAdmin(address newAdmin) external 
    {
        require(msg.sender == _admin(),"Need only owner access");
        require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");

        _setAdmin(newAdmin);
    }

    //ERC1967
    /**
    * @dev Storage slot with the admin of the contract.
    * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
    * validated in the constructor.
    */

    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }
    /**
    * @return adm The admin slot.
    */
    function _admin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
        adm := sload(slot)
        }
    }


    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {

        emit Upgraded(newImplementation);

        bytes32 slot = IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }

    }
    /**
    * @dev Sets the address of the proxy admin.
    * @param newAdmin Address of the new proxy admin.
    */
    function _setAdmin(address newAdmin) internal {

        emit AdminChanged(_admin(), newAdmin);

        bytes32 slot = ADMIN_SLOT;

        assembly {
        sstore(slot, newAdmin)
        }

    }

    function implementation() external view returns (address)
    {
        return _implementation();
    }

    function admin() external view returns (address)
    {
        return _admin();
    }

}

