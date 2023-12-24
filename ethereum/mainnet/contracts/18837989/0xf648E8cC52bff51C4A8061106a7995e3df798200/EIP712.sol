// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./MessageHashUtils.sol";
import "./IERC5267.sol";
import "./Initializable.sol";

abstract contract EIP712 is Initializable, IERC5267 {
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant TYPE_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    function _EIP712NameHash() internal view virtual returns (bytes32) {
        return keccak256(bytes(_EIP712Name()));
    }

    function _EIP712VersionHash() internal pure returns (bytes32) {
        return keccak256(bytes(_EIP712Version()));
    }

    function _EIP712Name() internal view virtual returns (string memory);

    function _EIP712Version() internal pure virtual returns (string memory);

    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TYPE_HASH,
                    _EIP712NameHash(),
                    _EIP712VersionHash(),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return
            MessageHashUtils.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f",
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}
