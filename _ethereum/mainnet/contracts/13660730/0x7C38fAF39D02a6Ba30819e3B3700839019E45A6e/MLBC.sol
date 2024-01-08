// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
    
contract MLBC {

    function exists(uint256 _tokenId) public virtual view returns (bool _exists) {}
    function ownerOf(uint256 _tokenId) external virtual view returns (address) {}
    function setApprovalForAll(address _operator, bool _approved) public {}
}


