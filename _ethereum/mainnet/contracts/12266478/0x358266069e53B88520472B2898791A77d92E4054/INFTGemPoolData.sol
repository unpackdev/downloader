// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface INFTGemPoolData {

    // pool is inited with these parameters. Once inited, all
    // but ethPrice are immutable. ethPrice only increases. ONLY UP
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function ethPrice() external view returns (uint256);
    function minTime() external view returns (uint256);
    function maxTime() external view returns (uint256);
    function difficultyStep() external view returns (uint256);
    function maxClaims() external view returns (uint256);

    // these describe the pools created contents over time. This is where
    // you query to get information about a token that a pool created
    function claimedCount() external view returns (uint256);
    function claimAmount(uint256 claimId) external view returns (uint256);
    function claimQuantity(uint256 claimId) external view returns (uint256);
    function mintedCount() external view returns (uint256);
    function totalStakedEth() external view returns (uint256);
    function tokenId(uint256 tokenHash) external view returns (uint256);
    function tokenType(uint256 tokenHash) external view returns (uint8);
    function allTokenHashesLength() external view returns (uint256);
    function allTokenHashes(uint256 ndx) external view returns (uint256);
    function nextClaimHash() external view returns (uint256);
    function nextGemHash() external view returns (uint256);
    function nextGemId() external view returns (uint256);
    function nextClaimId() external view returns (uint256);

    function claimUnlockTime(uint256 claimId) external view returns (uint256);
    function claimTokenAmount(uint256 claimId) external view returns (uint256);
    function stakedToken(uint256 claimId) external view returns (address);

    function allowedTokensLength() external view returns (uint256);
    function allowedTokens(uint256 idx) external view returns (address);
    function isTokenAllowed(address token) external view returns (bool);
    function addAllowedToken(address token) external;
    function removeAllowedToken(address token) external;
}
