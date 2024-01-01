// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

abstract contract EndemicEIP712 {
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    bytes32 private constant SALT_HASH = keccak256("Endemic Exchange Salt");

    string private constant DOMAIN_NAME = "Endemic Exchange";

    error InvalidSignature();

    function _buildDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes("1")),
                block.chainid,
                address(this),
                SALT_HASH
            )
        );
    }

    /**
     * @notice See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
}
