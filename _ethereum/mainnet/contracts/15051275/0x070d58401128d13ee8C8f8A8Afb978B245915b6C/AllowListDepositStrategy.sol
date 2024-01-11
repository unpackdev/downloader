// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IMerkleTreeVerifier} from "IMerkleTreeVerifier.sol";
import {IBasePortfolio} from "IBasePortfolio.sol";

contract AllowListDepositStrategy {
    IMerkleTreeVerifier public immutable verifier;
    uint256 public immutable allowListIndex;

    constructor(IMerkleTreeVerifier _verifier, uint256 _allowListIndex) {
        verifier = _verifier;
        allowListIndex = _allowListIndex;
    }

    function deposit(
        IBasePortfolio portfolio,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public {
        require(
            verifier.verify(allowListIndex, keccak256(abi.encodePacked(msg.sender)), merkleProof),
            "AllowListDepositStrategy: Invalid proof"
        );
        portfolio.deposit(amount, msg.sender);
    }
}
