// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./Strings.sol";


contract SPOProxy is Ownable {

    address public _pwrdf;

    // SPOs[tokenID][predicateIdx][objectIdx] = object
    mapping (uint256 => mapping (uint8 => mapping ( uint8 => string ))) public _SPOs;

    constructor() {}

    modifier onlyPwrdf() {
        require(msg.sender == _pwrdf, "Only callable by the PWRDF contract");
        _;
    }

    // MARK: - Only Owner
    function setPwrdf(address pwrdf) external onlyOwner {
        _pwrdf = pwrdf;
    }

    // MARK: - Only PWRDF
    function addSPO(uint256 tokenId, uint8 predicateIdx, uint8 objectIdx, string memory object) external onlyPwrdf {
        _SPOs[tokenId][predicateIdx][objectIdx] = object;
    }

    function removeRDF(uint256 tokenId, uint8 predicateIdx, uint8 objectIdx) external onlyPwrdf {
        delete _SPOs[tokenId][predicateIdx][objectIdx];
    }

    // Mark: - View
    function getObject(uint256 tokenId, uint8 predicateIdx, uint8 objectIdx) external view returns (string memory) {
        return _SPOs[tokenId][predicateIdx][objectIdx];
    }

}