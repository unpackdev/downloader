pragma solidity ^0.8.21;

struct Planet {
    // constant for planet
    uint256 id; // id of planet or 0 if it not exists
    uint256 creationTime; // when was created
    uint256 periodTimer; // period time interval
    uint256 claimResourcesTimer; // time seconds to extract resources on new claim period
    // destruction
    uint256 destroyTime; // time when will be destroyed or 0
    // total savings
    uint256 eth; // eth to claim
    uint256 token; // token to claim
    uint256 token2; // token2 to claim
    // accounts data
    uint256 accountsCount; // accounts count on planet
    uint256 tokenStaked; // total staked tokens
    // snapshot
    uint256 claimPeriodSnapshot; // number of snapshot period to claim
    uint256 tokenStakedSnapshot; // tokens staked for claims on claim period
    uint256 ethSnapshot;
    uint256 tokenSnapshot;
    uint256 token2Snapshot;
}
