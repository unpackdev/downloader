pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



contract PairTokenManager {
    /// @dev Max amount of pair tokens registered in the network.
    /// This is computed by: 2048 - 512 = 1536
    uint16 constant MAX_AMOUNT_OF_PAIR_TOKENS = 1536;
    uint16 constant PAIR_TOKEN_START_ID = 512;

    /// @dev Total number of pair tokens registered in the network
    uint16 public totalPairTokens;

    /// @dev List of registered tokens by tokenId
    mapping(uint16 => address) public tokenAddresses;

    /// @dev List of registered tokens by address
    mapping(address => uint16) public tokenIds;
    
    /// @dev Token added to Franklin net
    event NewToken(
        address indexed token,
        uint16 indexed tokenId
    );

    function addPairToken(address _token) internal {
        require(tokenIds[_token] == 0, "pan1"); // token exists
        require(totalPairTokens < MAX_AMOUNT_OF_PAIR_TOKENS, "pan2"); // no free identifiers for tokens
        uint16 newPairTokenId = PAIR_TOKEN_START_ID + totalPairTokens;
        totalPairTokens++;

        // tokenId -> token
        tokenAddresses[newPairTokenId] = _token;
        // token -> tokenId
        tokenIds[_token] = newPairTokenId;
        emit NewToken(_token, newPairTokenId);
    }

    /// @dev Validate pair token address
    /// @param _tokenAddr Token address
    /// @return tokens id
    function validatePairTokenAddress(address _tokenAddr) public view returns (uint16) {
        uint16 tokenId = tokenIds[_tokenAddr];
        require(tokenId != 0, "pms3");
        require(tokenId < (PAIR_TOKEN_START_ID + MAX_AMOUNT_OF_PAIR_TOKENS), "pms4");
        require(tokenId >= PAIR_TOKEN_START_ID, "pms5");
        return tokenId;
    }
}
