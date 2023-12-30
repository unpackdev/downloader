// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface ILotManager {
    function isLotManager() external view returns (bool);
    function lotPrice() external view returns (uint256);
    function balaceOfUnderlying() external view returns (uint256);
    function claimRewards() external returns (bool);
    function buyLot() external returns (bool);
    function sellLot() external returns (bool);
}
