// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

interface IMiniswapMiner {
    event AddWhitelist(address);
    event RemoveWhitelist(address);

    function owner() external view returns(address);
    function feeder() external view returns(address);

    function whitelistMap(address) external view returns(bool);
    function mineInfo(uint256) external view returns(uint256);
    function minFee() external view returns(uint256);

    function changeMinFee(uint256) external;
    function addWhitelist(address) external;
    function addWhitelistByTokens(address,address,address) external;
    function removeWhitelist(address) external;
    function removeWhitelistByTokens(address,address,address) external;

    function mining(address,address,address,address,uint) external;//factory receiver token amount
}