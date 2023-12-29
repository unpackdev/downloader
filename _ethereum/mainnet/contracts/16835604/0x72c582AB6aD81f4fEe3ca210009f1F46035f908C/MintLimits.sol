// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

abstract contract MintLimits {
    error OverLimit();

    /// @notice Per-wallet mint limit tracked via mapping. Can be used instead-of or alongside MAX_MINT
    uint8 public constant MINT_LIMIT = 5;

    mapping(address account => uint256 minted) private mintedTokens;

    function _trackMints(uint256 quantity) internal {
        mintedTokens[msg.sender] += quantity;
    }

    modifier onlyUnderLimit(uint256 quantity) {
        if (mintedTokens[msg.sender] + quantity > MINT_LIMIT) {
            revert OverLimit();
        }
        _;
    }
}
