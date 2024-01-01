pragma solidity ^0.8.23;

struct Land {
    // constant for land
    uint256 id; // id of land or 0 if it not exists
    uint256 creationTime; // when was created
    uint256 periodSeconds; // period time season
    uint256 takeGoldSeconds; // time seconds to extract gold on new take period
    // erase
    uint256 eraseTime; // time when will be eraseed or 0
    // total savings
    uint256 eth; // eth to take
    uint256 token1; // token1 to take
    uint256 token2; // token2 to take
    // accounts data
    uint256 accountsCount; // accounts count on land
    uint256 tokenStaked; // total staked tokens
    // snapshot
    uint256 takePeriodSnapshot; // number of snapshot period to take
    uint256 tokenStakedSnapshot; // tokens staked for takes on take period
    uint256 ethSnapshot;
    uint256 tokenSnapshot;
    uint256 token2Snapshot;
}
