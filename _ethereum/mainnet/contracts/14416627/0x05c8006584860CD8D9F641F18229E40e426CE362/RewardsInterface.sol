// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.10;

interface RewardsInterface {
    function mint(
        address otoken,
        address account,
        uint256 amount
    ) external;

    function burn(
        address otoken,
        address account,
        uint256 amount
    ) external;

    function getReward(address otoken, address account) external;
}
