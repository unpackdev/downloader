// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVault {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function totalBondedSupply() external view returns (uint256);

    function balanceWithoutBonded(address who) external view returns (uint256);

    function bond(uint256 amount) external;

    function bondFor(address who, uint256 amount) external;

    function unbond(uint256 amount) external;

    function withdraw() external;

    function getStakedAmount(address who) external view returns (uint256);
}
