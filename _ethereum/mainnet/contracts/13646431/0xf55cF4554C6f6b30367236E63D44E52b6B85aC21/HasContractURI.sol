// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.8.0;

import "./OwnableUpgradeable.sol";
import "./ERC165Upgradeable.sol";

import "./AddAddrToURI.sol";

contract HasContractURI is OwnableUpgradeable, ERC165Upgradeable, AddAddrToURI {
    string public contractURI;

    /*
     * bytes4(keccak256('contractURI()')) == 0xe8a3d485
     */
    bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    function __HasContractURI_init_unchained(string memory baseURI_) internal initializer {
        contractURI = string(abi.encodePacked(baseURI_, "0x", toAsciiString(address(this))));
        _registerInterface(_INTERFACE_ID_CONTRACT_URI);
    }

    uint256[50] private __gap;
}
