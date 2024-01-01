pragma solidity ^0.8.23;

struct AccLandData {
    uint256 landId; // id of the land or 0
    uint256 tokenStaked; // count of staked tokens of account
    uint256 takePeriod; // last used take period
}
