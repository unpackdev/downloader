// SPDX-License-Identifier: <SPDX-License>
pragma solidity 0.7.5;

interface IOracle {
    function fetch(address token, bytes calldata data)
        external
        returns (uint256 price);

    function fetchAquaPrice() external returns (uint256 price);
}
