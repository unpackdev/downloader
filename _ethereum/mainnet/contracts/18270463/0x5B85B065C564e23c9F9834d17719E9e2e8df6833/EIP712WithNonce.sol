// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./EIP712Upgradeable.sol";

abstract contract EIP712WithNonce is EIP712Upgradeable {
    event NonceConsumed(address indexed owner, uint256 idx);
    mapping(address => mapping(uint256 => uint256)) private _nonces;

    /**
     * @notice EIP 712 domain separator that is used as part of the encoding scheme.
     * @dev Returns the domain separator for the current chain.
     * @return  bytes32 Domain Separator.
     */
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Retuns a nonce for a given address.
     * @param   from  Address.
     * @return  uint256 Nonce Value.
     */
    function nonce(address from) external view virtual returns (uint256) {
        return _nonces[from][0];
    }

    /**
     * @notice Retuns a nonce for a given address and a timeline.
     * @param   from  Address.
     * @param   timeline Timeline.
     * @return  uint256 Nonce value.
     */
    function nonce(address from, uint256 timeline) external view virtual returns (uint256) {
        return _nonces[from][timeline];
    }

    /**
     * @notice Verifies Nonce and Saves.
     * @param   owner Owner's address.
     * @param   idx  Index Value.
     */
    function _verifyAndConsumeNonce(address owner, uint256 idx) internal virtual {
        require(idx % (1 << 128) == _nonces[owner][idx >> 128]++, "EIP712WithNonce:: invalid nonce");
        emit NonceConsumed(owner, idx);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
