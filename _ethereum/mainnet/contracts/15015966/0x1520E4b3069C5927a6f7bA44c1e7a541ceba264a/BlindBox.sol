//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./NFT.sol";

contract BelsBlindBox is BelsERC721 {
    mapping(uint256 => string) private _blindProof;
    mapping(uint256 => bool) private _blindProofExisted;

    bytes32 proofRole = keccak256("PROOF_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        string memory newBaseTokenURI
    ) BelsERC721(name, symbol, newBaseTokenURI) {
        grantRole(proofRole, msg.sender);
    }

    function setProof(uint256 index, string memory proof)
        external
        onlyRole(proofRole)
        returns (bool)
    {
        require(!_blindProofExisted[index], "proof has already been seted");
        _blindProof[index] = proof;
        _blindProofExisted[index] = true;
        return true;
    }

    function getProof(uint256 index) public view returns (string memory) {
        return _blindProof[index];
    }
}
