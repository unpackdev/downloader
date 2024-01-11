// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.1;

import "./Bank.sol";

interface IBank {
    function addManyToBankAndPack(address account, uint16[] calldata tokenIds) external;
    function randomAlienOwner(uint256 seed) external view returns (address);
    function bank(uint256) external view returns(uint16, uint80, address);
    function totalLANDEarned() external view returns(uint256);
    function lastClaimTimestamp() external view returns(uint256);
    function setOldTokenInfo(uint256 _tokenId) external;

    function pack(uint256, uint256) external view returns(Bank.Stake memory);
    function packIndices(uint256) external view returns(uint256);

}