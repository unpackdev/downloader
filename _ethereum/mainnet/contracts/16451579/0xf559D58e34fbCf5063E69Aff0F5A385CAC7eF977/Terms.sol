// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";

abstract contract Terms is Ownable {
    string public termsURI;

    /**
     * @notice Sets the URI for the contract's terms and conditions
     */
    function setTermsURI(string memory uri) public onlyOwner {
        termsURI = uri;
    }
}
