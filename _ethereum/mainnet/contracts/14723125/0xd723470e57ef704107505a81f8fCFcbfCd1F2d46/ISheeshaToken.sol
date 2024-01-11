//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ISheeshaToken is IERC20 {
    function isUserExisting(address) external view returns (bool);
    function participateLGE() external;
}
