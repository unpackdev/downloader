// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IdleCDO {
    function ONE_TRANCHE_TOKEN() external view returns (uint256);

    function token() external view returns (address);

    function depositAA(uint256 _amount) external returns (uint256);

    function depositBB(uint256 _amount) external returns (uint256);

    function withdrawAA(uint256 _amount) external returns (uint256);

    function withdrawBB(uint256 _amount) external returns (uint256);

    function tranchePrice(address _tranche) external view returns (uint256);
}
