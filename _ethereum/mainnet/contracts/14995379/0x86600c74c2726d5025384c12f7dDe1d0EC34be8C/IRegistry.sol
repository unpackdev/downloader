// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./UpgradeableBeacon.sol";
import "./IERC721.sol";
import "./IERC20.sol";

interface IRegistry {
    function listingBeacon() external returns (UpgradeableBeacon);

    function brickTokenBeacon() external returns (UpgradeableBeacon);

    function buyoutBeacon() external returns (UpgradeableBeacon);

    function iroBeacon() external returns (UpgradeableBeacon);

    function propNFT() external returns (IERC721);

    function treasuryAddr() external returns (address);
}
