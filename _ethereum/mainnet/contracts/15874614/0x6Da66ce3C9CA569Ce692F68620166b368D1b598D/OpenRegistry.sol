// SPDX-License-Identifier: MIT
//
// Derived from Kredeum NFTs
// https://github.com/Kredeum/kredeum
//
//       ___           ___         ___           ___              ___           ___                     ___
//      /  /\         /  /\       /  /\         /__/\            /__/\         /  /\        ___        /  /\
//     /  /::\       /  /::\     /  /:/_        \  \:\           \  \:\       /  /:/_      /  /\      /  /:/_
//    /  /:/\:\     /  /:/\:\   /  /:/ /\        \  \:\           \  \:\     /  /:/ /\    /  /:/     /  /:/ /\
//   /  /:/  \:\   /  /:/~/:/  /  /:/ /:/_   _____\__\:\      _____\__\:\   /  /:/ /:/   /  /:/     /  /:/ /::\
//  /__/:/ \__\:\ /__/:/ /:/  /__/:/ /:/ /\ /__/::::::::\    /__/::::::::\ /__/:/ /:/   /  /::\    /__/:/ /:/\:\
//  \  \:\ /  /:/ \  \:\/:/   \  \:\/:/ /:/ \  \:\~~\~~\/    \  \:\~~\~~\/ \  \:\/:/   /__/:/\:\   \  \:\/:/~/:/
//   \  \:\  /:/   \  \::/     \  \::/ /:/   \  \:\  ~~~      \  \:\  ~~~   \  \::/    \__\/  \:\   \  \::/ /:/
//    \  \:\/:/     \  \:\      \  \:\/:/     \  \:\           \  \:\        \  \:\         \  \:\   \__\/ /:/
//     \  \::/       \  \:\      \  \::/       \  \:\           \  \:\        \  \:\         \__\/     /__/:/
//      \__\/         \__\/       \__\/         \__\/            \__\/         \__\/                   \__\/
//
//   OpenERC165
//        |
//   OpenERC173
//        |
//  OpenRegistry —— IOpenRegistry
//
pragma solidity 0.8.9;

import "./OpenERC173.sol";
import "./IOpenRegistry.sol";

abstract contract OpenRegistry is IOpenRegistry, OpenERC173 {
    mapping(address => uint256) private _numAddress;
    address[] private _addresses;
    address public registerer;

    /// @notice onlyRegisterer, by default owner is registerer and can add addresses, can be overriden
    modifier onlyRegisterer() virtual {
        require(msg.sender == owner() || msg.sender == registerer, "Not registerer nor owner");
        _;
    }

    /// @notice isValid, by default all addresses valid
    modifier onlyValid(address) virtual {
        _;
    }

    function setRegisterer(address registerer_) external override (IOpenRegistry) onlyOwner {
        _setRegisterer(registerer_);
    }

    function addAddresses(address[] memory addrs) external override (IOpenRegistry) {
        for (uint256 i = 0; i < addrs.length; i++) {
            _addAddress(addrs[i]);
        }
    }

    function addAddress(address addr) external override (IOpenRegistry) {
        _addAddress(addr);
    }

    function removeAddress(address addr) external override (IOpenRegistry) {
        _removeAddress(addr);
    }

    function countAddresses() external view override (IOpenRegistry) returns (uint256) {
        return _addresses.length;
    }

    function isRegistered(address addr) public view returns (bool) {
        return _numAddress[addr] >= 1;
    }

    function getAddresses() public view override (IOpenRegistry) returns (address[] memory) {
        return _addresses;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (OpenERC173)
        returns (bool)
    {
        return interfaceId == type(IOpenRegistry).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function _setRegisterer(address registerer_) internal {
        registerer = registerer_;
    }

    function _addAddress(address addr) private onlyRegisterer onlyValid(addr) {
        if (!isRegistered(addr)) {
            _addresses.push(addr);
            _numAddress[addr] = _addresses.length;
        }
    }

    function _removeAddress(address addr) private onlyRegisterer {
        require(isRegistered(addr), "Not registered");

        uint256 num = _numAddress[addr];
        if (num != _addresses.length) {
            address addrLast = _addresses[_addresses.length - 1];
            _addresses[num - 1] = addrLast;
            _numAddress[addrLast] = num;
        }

        delete (_numAddress[addr]);
        _addresses.pop();
    }
}
