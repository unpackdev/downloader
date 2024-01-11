//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IDB {
    function getOwnerFee() external view returns (uint256);

    function getPolkaLokrFee() external view returns (uint256);

    function getRecepient() external view returns (address);

    event BridgEdit(address bridgeContract, address bridgeOwner);

    function addBridge(address bridgeContract, address bridgeOwner) external;
}
