// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./Math.sol";


contract Formula {
    using SafeMath for uint;

    constructor (){}

    function div(uint a, uint b) external pure returns(uint){
      return a.div(b);
    }

    function mul(uint a, uint b) external pure returns(uint){
      return a.mul(b);
    }

    function add(uint a, uint b) external pure returns(uint){
      return a.add(b);
    }

    function sub(uint a, uint b) external pure returns(uint){
      return a.sub(b);
    }
}
