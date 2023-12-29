// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

/// @title   IAvocado
/// @notice  interface to access internal vars on-chain
interface IAvocado {
    function _avoImpl() external view returns (address);

    function _data() external view returns (uint256);

    function _owner() external view returns (address);
}

/// @title      Avocado
/// @notice     Proxy for Avocados as deployed by the AvoFactory.
///             Basic Proxy with fallback to delegate and address for implementation contract at storage 0x0
//
// @dev        If this contract changes then the deployment addresses for new Avocados through factory change too!!
//             Relayers might want to pass in version as new param then to forward to the correct factory
contract Avocado {
    /// @notice flexible immutable data slot.
    /// first 20 bytes: address owner
    /// next 4 bytes: uint32 index
    /// next 1 byte: uint8 type
    /// next 9 bytes: used flexible for use-cases found in the future
    uint256 internal immutable _data;

    /// @notice address of the Avocado logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    //
    // @dev    _avoImpl MUST ALWAYS be the first declared variable here in the proxy and in the logic contract
    //         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    //         To reduce deployment costs this variable is internal but can still be retrieved with
    //         _avoImpl(), see code and comments in fallback below
    address internal _avoImpl;

    /// @notice   sets _avoImpl & immutable _data, fetching it from msg.sender.
    //
    // @dev      those values are not input params to not influence the deterministic Create2 address!
    constructor() {
        // "\x8c\x65\x73\x89" is hardcoded bytes of function selector for transientDeployData()
        (, bytes memory deployData_) = msg.sender.staticcall(bytes("\x8c\x65\x73\x89"));

        address impl_;
        uint256 data_;
        assembly {
            // cast first 20 bytes to version address (_avoImpl)
            impl_ := mload(add(deployData_, 0x20))

            // cast bytes in position 0x40 to uint256 data; deployData_ plus 0x40 due to padding
            data_ := mload(add(deployData_, 0x40))
        }

        _data = data_;
        _avoImpl = impl_;
    }

    /// @notice Delegates the current call to `_avoImpl` unless one of the view methods is called:
    ///         `_avoImpl()` returns the address for `_avoImpl`, `_owner()` returns the first
    ///         20 bytes of `_data`, `_data()` returns `_data`.
    //
    // @dev    Mostly based on OpenZeppelin Proxy.sol
    // logic contract must not implement a function `_avoImpl()`, `_owner()` or  `_data()`
    // as they will not be callable due to collision
    fallback() external payable {
        uint256 data_ = _data;
        assembly {
            let functionSelector_ := calldataload(0)

            // 0xb2bdfa7b = function selector for _owner()
            if eq(functionSelector_, 0xb2bdfa7b00000000000000000000000000000000000000000000000000000000) {
                // store address owner at memory address 0x0, loading only last 20 bytes through the & mask
                mstore(0, and(data_, 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff))
                return(0, 0x20) // send 32 bytes of memory slot 0 as return value
            }

            // 0x68beab3f = function selector for _data()
            if eq(functionSelector_, 0x68beab3f00000000000000000000000000000000000000000000000000000000) {
                mstore(0, data_) // store uint256 _data at memory address 0x0
                return(0, 0x20) // send 32 bytes of memory slot 0 as return value
            }

            // load address avoImpl_ from storage
            let avoImpl_ := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // first 4 bytes of calldata specify which function to call.
            // if those first 4 bytes == 874095c6 (function selector for _avoImpl()) then we return the _avoImpl address
            // The value is right padded to 32-bytes with 0s
            if eq(functionSelector_, 0x874095c600000000000000000000000000000000000000000000000000000000) {
                mstore(0, avoImpl_) // store address avoImpl_ at memory address 0x0
                return(0, 0x20) // send 32 bytes of memory slot 0 as return value
            }

            // @dev code below is taken from OpenZeppelin Proxy.sol _delegate function

            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), avoImpl_, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
