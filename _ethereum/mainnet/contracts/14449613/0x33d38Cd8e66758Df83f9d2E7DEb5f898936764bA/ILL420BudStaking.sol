//
//  __   __      _____    ______
// /__/\/__/\   /_____/\ /_____/\
// \  \ \: \ \__\:::_:\ \\:::_ \ \
//  \::\_\::\/_/\   _\:\| \:\ \ \ \
//   \_:::   __\/  /::_/__ \:\ \ \ \
//        \::\ \   \:\____/\\:\_\ \ \
//         \__\/    \_____\/ \_____\/
//
// 420.game Bud / Game Key Staking Interface
//
// by LOOK LABS
//
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

interface ILL420BudStaking {
    function setTHC(uint256[] calldata _ids, uint256[] calldata _thc) external;

    function getBudInfo(uint256[] memory _ids) external view returns (uint256[] memory, uint256[] memory);

    function getGKBuds(uint256 _id, address _user) external view returns (uint256[] memory);
}
