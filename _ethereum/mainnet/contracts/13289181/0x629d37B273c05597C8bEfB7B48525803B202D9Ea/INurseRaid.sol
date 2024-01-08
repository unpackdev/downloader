// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IMaids.sol";
import "./IMaidCoin.sol";
import "./IMaidCafe.sol";
import "./INursePart.sol";
import "./ICloneNurses.sol";
import "./IRNG.sol";

interface INurseRaid {
    event Create(
        uint256 indexed id,
        uint256 entranceFee,
        uint256 indexed nursePart,
        uint256 maxRewardCount,
        uint256 duration,
        uint256 endBlock
    );
    event Enter(address indexed challenger, uint256 indexed id, IMaids indexed maids, uint256 maidId);
    event Exit(address indexed challenger, uint256 indexed id);
    event ChangeMaidEfficacy(uint256 numerator, uint256 denominator);

    function isMaidsApproved(IMaids maids) external view returns (bool);

    function maidCoin() external view returns (IMaidCoin);

    function maidCafe() external view returns (IMaidCafe);

    function nursePart() external view returns (INursePart);

    function rng() external view returns (IRNG);

    function cloneNurses() external view returns (ICloneNurses);

    function maidEfficacy() external view returns (uint256, uint256);

    function raidCount() external view returns (uint256);

    function create(
        uint256[] calldata entranceFee,
        uint256[] calldata nursePart,
        uint256[] calldata maxRewardCount,
        uint256[] calldata duration,
        uint256[] calldata endBlock
    ) external returns (uint256 id);

    function enter(
        uint256 id,
        IMaids maids,
        uint256 maidId
    ) external;

    function enterWithPermit(
        uint256 id,
        IMaids maids,
        uint256 maidId,
        uint256 deadline,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) external;

    function enterWithPermitAll(
        uint256 id,
        IMaids maids,
        uint256 maidId,
        uint256 deadline,
        uint8 v1,
        bytes32 r1,
        bytes32 s1,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
    ) external;

    function checkDone(uint256 id) external view returns (bool);

    function exit(uint256[] calldata ids) external;
}
