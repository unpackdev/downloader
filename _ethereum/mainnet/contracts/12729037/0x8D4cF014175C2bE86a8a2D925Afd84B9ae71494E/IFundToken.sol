// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.7.6;

interface IFundToken {
    function mint(address account, uint value) external;

    function burn(address account, uint value) external;
}
