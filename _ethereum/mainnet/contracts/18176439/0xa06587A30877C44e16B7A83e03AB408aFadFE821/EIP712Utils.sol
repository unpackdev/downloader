// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IBridge.sol";

abstract contract EIP712Utils is IBridge {
    bytes32 constant PERMIT_TYPEHASH = keccak256(
        "Permit(address receiver,uint256 amount,address token,uint256 tokenId,string chain,uint256 nonce)"
    );
    bytes32 constant VERIFYPRICE_TYPEHASH = keccak256(
        "VerifyPrice(uint256 stargateAmountForOneUsd,uint256 transferedTokensAmountForOneUsd,address token,uint256 nonce)"
    );
    /// @dev Generates the digest that is used in signature verification
    /// @param typeHash abi encoded type hash digest
    function getPermitDigest(bytes32 typeHash) internal view returns (bytes32) {
        bytes32 domainSeparator = getDomainSeparator("1", block.chainid, address(this));
        bytes32 permitDigest = keccak256(
            abi.encodePacked(
                uint16(0x1901),
                domainSeparator,
                typeHash
            )
        );
        return permitDigest;
    }

    /// @dev Generates domain separator
    /// @dev Used to generate permit digest afterwards
    /// @param version The version of separator
    /// @param chainId The ID of the current chain
    /// @param verifyingAddress The address of the contract that will verify the signature
    function getDomainSeparator(
        string memory version,
        uint256 chainId, 
        address verifyingAddress
    ) internal pure returns (bytes32) {
            
        return keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingAddress)"
                ),
                keccak256(bytes("StargateBridge")),
                // Version
                keccak256(bytes(version)),
                // ChainID
                chainId,
                // Verifying contract
                verifyingAddress
            ) 
        );   
    }

    /// @dev Generates the type hash for verify price digest
    /// @param params sourceBridgeParams structure (see definition in IBridge.sol)
    function getVerifyPriceTypeHash(sourceBridgeParams calldata params) internal pure returns (bytes32) {
        bytes32 permitHash;
        permitHash = keccak256(
            abi.encode(
                VERIFYPRICE_TYPEHASH,
                params.stargateAmountForOneUsd,
                params.transferedTokensAmountForOneUsd,
                params.token,
                params.nonce
            )
        );
        return permitHash;
    }
    /// @dev Generates the type hash for permit digest
    /// @param params targetBridgeParams structure (see definition in IBridge.sol)
    /// @param chain If not price verification (unlock or mint) we check chain
    function getPermitTypeHash(
        address receiver,
        targetBridgeParams calldata params,
        string memory chain
    ) internal pure returns (bytes32) {
        bytes32 permitHash;
        permitHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                receiver,
                params.amount,
                params.token,
                params.tokenId,
                chain,
                params.nonce
            )
        );
        return permitHash;
    }
}

