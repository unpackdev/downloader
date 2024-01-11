// SPDX-License-Identifier: GPL-3.0 License

pragma solidity ^0.8.0;


interface IBLXMTreasuryManager {

    event TreasuryPut(address indexed sender, address oldTreasury, address newTreasury, address indexed token);

    function putTreasury(address token, address treasury) external;
    function getTreasury(address token) external view returns (address treasury);
    function getReserves(address token) external view returns (uint reserveBlxm, uint reserveToken);

    function updateRatioAdmin(address _ratioAdmin) external;
    function getRatio(address token) external view returns (uint ratio);
}