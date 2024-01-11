
//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IGateway {

    function claimRoot() external view returns (bytes32);

    function relayRoot() external view returns (bytes32);

    function chainId() external view returns (uint256);

}
