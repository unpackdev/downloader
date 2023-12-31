// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./IMuonNodeStaking.sol";

contract TierSetter is Ownable {
    using ECDSA for bytes32;

    address public signer;
    uint256 public signatureValidityPeriod;
    IMuonNodeStaking public nodeStaking;

    constructor(address muonNodeStakingAddress, address _signer) {
        nodeStaking = IMuonNodeStaking(muonNodeStakingAddress);
        signer = _signer;

        signatureValidityPeriod = 600;
    }

    function setTier(
        address stakerAddress,
        uint8 tier,
        uint256 timestamp,
        bytes memory signature
    ) external {
        require(
            block.timestamp <= timestamp + signatureValidityPeriod,
            "Signature has expired."
        );

        bytes32 messageHash = keccak256(
            abi.encodePacked(stakerAddress, tier, timestamp)
        );
        address recoveredSigner = messageHash.recover(signature);
        require(recoveredSigner == signer, "Invalid signature.");

        nodeStaking.setMuonNodeTier(stakerAddress, tier);
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setSignatureValidityPeriod(uint256 _newValidityPeriod)
        external
        onlyOwner
    {
        signatureValidityPeriod = _newValidityPeriod;
    }
}
