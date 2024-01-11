//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.9;

interface IAntiSnipe {
    function isBot(address account) external view  returns (bool);
}
