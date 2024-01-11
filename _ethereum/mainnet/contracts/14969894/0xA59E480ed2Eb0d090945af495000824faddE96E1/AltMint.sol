// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./PackDropBase.sol";

/**
 * @title NFT ALT MINT I on Ethereum Mainnet, featured by Alt.
 *
 * Smart contract architecture inspired by {BackToSchool_ByCourtyard} featured by Courtyard
 * See https://polygonscan.com/address/0x3ea68344480890d582ce7fd7cbf3e7fd7fc23c20#code
 *
 */
contract AltMint is PackDropBase {
    /// @dev Ethereum Mainnet constructor.
    /// See {https://docs.chain.link/docs/vrf-contracts/#ethereum-mainnet} for VRF parameters.
    constructor()
        PackDropBase(
            'ALT MINT I',
            4,                                                                  // Max 4 tokens per transaction
            4,                                                                  // Max 4 tokens per address
            1 * 10**18,                                                         // 1 ETH (subject to updates before the drop)
            0x8b9F2275E958E208099428a8fD16F6B44eC8B7ea,                         // Signer Address for the Allow List
            0xB143199c62d2D351f7d3F4527D9ed117870D27A4,                         // Alt Escrow Admin Multisig
            0x7bA31DdB4bc7C082cd3A55fC412934EFF9791496,                         // Alt Minting Admin Multisig
            0x2b97Af906d580De5e9A415EEc8025E35f4645f44,                         // Alt Vault Proxy deployed on Eth Mainnet
            0x271682DEB8C4E0901D1a1550aD2e64D568E69909,                         // VRFCoordinator on Eth Mainnet
            0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef, // Chainlink keyHash on Eth Mainnet
            173                                                                 // Chainlink v2 Subscription ID 
        )
    {}
}
