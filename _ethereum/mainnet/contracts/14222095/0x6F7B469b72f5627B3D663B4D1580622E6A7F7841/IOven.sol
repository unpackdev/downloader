//SPDX-License-Identifier: MIT
pragma solidity >=0.6.5 <0.8.0;




interface IOven {
    function distribute (address origin, uint256 amount) external;
}