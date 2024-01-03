// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

interface PickleJar {
    /*
    @notice returns price of token / share
    @dev ratio is multiplied by 10 ** 18
    */
    function getRatio() external view returns (uint);

    function deposit(uint _amount) external;

    function withdraw(uint _amount) external;
}
