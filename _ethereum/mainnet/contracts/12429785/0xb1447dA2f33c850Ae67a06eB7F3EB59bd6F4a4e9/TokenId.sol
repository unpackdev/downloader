pragma solidity ^0.8.0;

uint256 constant TOKEN_ID_LIMIT = 100000000;

library TokenIdLib {
    uint256 internal constant tokenIdLimit = TOKEN_ID_LIMIT;
    uint256 internal constant collectionIdMultiplier =
        tokenIdLimit * tokenIdLimit;
    uint256 internal constant seriesIdMultiplier = tokenIdLimit;

    // Combine the collection ID, series ID and the token's position into a
    // single token ID. For example, if the series ID is `0` and the token
    // position is `23`, generate `100000023`.
    function encodeTokenId(
        uint256 collectionId,
        uint256 seriesId,
        uint256 tokenPosition
    ) internal pure returns (uint256) {
        return
            (collectionId + 1) *
            collectionIdMultiplier +
            (seriesId + 1) *
            seriesIdMultiplier +
            tokenPosition +
            1;
    }

    function extractEdition(uint256 tokenId) internal pure returns (uint256) {
        return ((tokenId % seriesIdMultiplier)) - 1;
    }

    // Extract the series ID from the tokenId. For example, `100000010` returns
    // `0`.
    function extractSeriesId(uint256 tokenId) internal pure returns (uint256) {
        return ((tokenId % collectionIdMultiplier) / seriesIdMultiplier) - 1;
    }

    // Extract the series ID from the tokenId. For example, `100000010` returns
    // `0`.
    function extractCollectionId(uint256 tokenId)
        internal
        pure
        returns (uint256)
    {
        uint256 id = tokenId / collectionIdMultiplier;
        return id == 0 ? 0 : id - 1;
    }
}

contract TokenId {
    uint256 internal constant tokenIdLimit = TOKEN_ID_LIMIT;
    uint256 public constant collectionIdMultiplier =
        tokenIdLimit * tokenIdLimit;
    uint256 public constant seriesIdMultiplier = tokenIdLimit;

    // Combine the collection ID, series ID and the token's position into a
    // single token ID. For example, if the series ID is `0` and the token
    // position is `23`, generate `100000023`.
    function encodeTokenId(
        uint256 collectionId,
        uint256 seriesId,
        uint256 tokenPosition
    ) public pure returns (uint256) {
        return TokenIdLib.encodeTokenId(collectionId, seriesId, tokenPosition);
    }

    function extractEdition(uint256 tokenId) public pure returns (uint256) {
        return TokenIdLib.extractEdition(tokenId);
    }

    // Extract the series ID from the tokenId. For example, `100000010` returns
    // `0`.
    function extractSeriesId(uint256 tokenId) public pure returns (uint256) {
        return TokenIdLib.extractSeriesId(tokenId);
    }

    // Extract the series ID from the tokenId. For example, `100000010` returns
    // `0`.
    function extractCollectionId(uint256 tokenId)
        public
        pure
        returns (uint256)
    {
        return TokenIdLib.extractCollectionId(tokenId);
    }
}
