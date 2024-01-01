// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

library LibClaimTokenStorage {
    event ClaimTokenAdded(
        address indexed claimToken,
        uint256 tokenType,
        address[] pegTokens,
        uint256[] pegTokensPricePercentage,
        address dexRouter
    );

    event ClaimTokenUpdated(
        address indexed claimToken,
        uint256 tokenType,
        address[] pegTokens,
        uint256[] pegTokensPricePercentage,
        address dexRouter
    );

    event ClaimTokenEnabled(address indexed claimToken, bool enabled);

    bytes32 constant CLAIMTOKEN_STORAGE_POSITION =
        keccak256("diamond.standard.CLAIMTOKEN.storage");

    struct ClaimTokenData {
        uint256 tokenType; // token type is used for token type sun or peg token
        address[] pegOrSunTokens; // addresses of the peg or sun tokens
        uint256[] pegOrSunTokensPricePercentage; // peg or sun token price percentages
        address dexRouter; //this address will get the price from the AMM DEX (uniswap, sushiswap etc...)
    }

    struct ClaimStorage {
        mapping(address => bool) approvedClaimTokens; // dev mapping for enable or disbale the claimToken
        mapping(address => ClaimTokenData) claimTokens;
        mapping(address => address) claimTokenofSUN; //sun token mapping to the claimToken
    }

    function claimTokenStorage()
        internal
        pure
        returns (ClaimStorage storage es)
    {
        bytes32 position = CLAIMTOKEN_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}
