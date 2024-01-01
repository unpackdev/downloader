pragma solidity ^0.8.21;

struct AccPlanetData {
    uint256 planetId; // id of the planet or 0
    uint256 tokenStaked; // count of staked tokens of account
    uint256 claimPeriod; // last used claim period
}
