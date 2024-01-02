// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGame {

    event LandDeposited(address from, uint256[] landId);
    event LandWithdrew(address from, uint256[] landId);
    event TokenWithdrewFromLand(address from, uint256 landId, uint256 amount, bytes32 nonce);
    event TokenDeposited(address from, uint256 amount);
    event TokenWithdrew(address from, uint256 amount, bytes32 nonce);
    
    function getLand(address account) external view returns (uint256[] memory);

    function ownerOfLand(
        address account,
        uint256 landId
    ) external view returns (bool);

    function directDeposit(address account, uint256[] memory landIds) external;

}
