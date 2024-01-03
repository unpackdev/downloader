// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

struct TrackedToken {
    address owner;
    uint256 tokenId;
    uint256 priceTarget;
}

interface IHegicBot {
    event TokenTracked(uint256 trackedTokenId);
    event TokenUntracked(uint256 trackedTokenId);
    event TrackedTokenExercised(uint256 trackedTokenId, uint256 grossProfit);
    event WorkFeeSet(uint256 workFee);
    event KeeperSet(address keeper);

    function track(uint256, uint256) external returns (uint256);

    function untrack(uint256) external returns (bool);

    function exercisable(uint256) external view returns (bool);

    function exercise(uint256) external returns (address, uint256);

    function setWorkFee(uint256) external;

    function setKeeper(address) external;
}
