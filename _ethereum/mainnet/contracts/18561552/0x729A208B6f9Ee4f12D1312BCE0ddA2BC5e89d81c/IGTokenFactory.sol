// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IGTokenFactory {
    function deployGToken(address _spToken) external returns (address _gToken);
}
