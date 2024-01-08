// SPDX-License-Identifier: MIT
// this is copied from MintableOwnableToken
// https://etherscan.io/address/0x987a4d3edbe363bc351771bb8abdf2a332a19131#code
// modified by TART-tokyo

pragma solidity =0.8.6;

import "./ERC165.sol";

contract HasContractURI is ERC165 {

    string public contractURI;

    /*
     * bytes4(keccak256('contractURI()')) == 0xe8a3d485
     */
    bytes4 private constant _INTERFACE_ID_CONTRACT_URI = 0xe8a3d485;

    constructor(string memory _contractURI) {
        contractURI = _contractURI;
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == _INTERFACE_ID_CONTRACT_URI || 
            super.supportsInterface(interfaceId);
    }

    function _setContractURI(string memory _contractURI) internal {
        contractURI = _contractURI;
    }
}
