// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

interface IPreCommit {
    function commit(address _from, uint _amount) external;
}
