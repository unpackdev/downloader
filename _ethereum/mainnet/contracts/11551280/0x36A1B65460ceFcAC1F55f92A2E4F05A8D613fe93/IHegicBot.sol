// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

struct TrackedToken {
    address owner;
    uint256 tokenId;
    uint256 priceTarget;
}

interface IHegicBot {
    event TokenTracked(
        address indexed account,
        uint256 indexed tokenId,
        uint256 indexed trackedTokenId,
        uint256 targetPrice
    );

    event TargetPriceChanged (
        address indexed account,
        uint256 indexed tokenId,
        uint256 indexed trackedTokenId,
        uint256 newTargetPrice
    );

    event TokenUntracked(
        address indexed account,
        uint256 indexed tokenId,
        uint256 indexed trackedTokenId
    );

    event TrackedTokenExercised(
        address indexed account,
        uint256 indexed tokenId,
        uint256 indexed trackedTokenId,
        uint256 grossProfit
    );

    event WorkFeeSet(uint256 workFee);
    event KeeperSet(address keeper);
    event TTMSet(uint256 newTTM);

    function track(uint256, uint256) external returns (uint256);

    function untrack(uint256) external returns (bool);

    function changeTargetPrice(uint256, uint256) external;

    function exercisable(uint256) external view returns (bool);

    function exercise(uint256) external returns (address, uint256);

    function setWorkFee(uint256) external;

    function setKeeper(address) external;

    function setMaxTimeToMaturity(uint256) external;

}
