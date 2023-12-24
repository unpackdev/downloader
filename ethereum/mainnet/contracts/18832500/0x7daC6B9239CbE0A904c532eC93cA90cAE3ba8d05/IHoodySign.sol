// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./IHoody.sol";

interface IHoodySign is IHoody {
    function verifyForTraits(
        address,
        string memory,
        uint16[] memory,
        bytes memory
    ) external view returns (bool);

    function verifyForStake(
        address,
        uint256[] memory,
        HoodyGangRarity[] memory,
        bytes memory
    ) external view returns (bool);

    function verifyForMigrate(
        address,
        uint256,
        string memory,
        bytes memory
    ) external view returns (bool);

    function increaseNonce(address) external;
}
