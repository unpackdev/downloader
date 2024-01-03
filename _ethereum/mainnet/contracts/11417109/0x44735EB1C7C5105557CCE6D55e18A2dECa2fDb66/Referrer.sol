// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";


contract Referrer {
    using SafeMath for uint;

    mapping(address => address) public referrer;
    mapping(address => address[]) public referree;
    mapping(address => uint) public referReward;
    event ReferReward(address indexed referrer, address indexed referree, uint amount);
    event Refered(address indexed referrer, address indexed referree);

    function setReferrer(address _referrer) public {
        require(!hasReferrer(msg.sender), "already has referrer");
        require(_referrer != address(0), "invalid referrer");
        require(_referrer != msg.sender, "invalid referrer");
        require(referreeCount(msg.sender) == 0, "already has referree");
        referrer[msg.sender] = _referrer;
        referree[_referrer].push(msg.sender);
        emit Refered(_referrer, msg.sender);
    }

    function hasReferrer(address self) public view returns (bool){
        return referrer[self] != address(0);
    }


    function referreeCount(address self) public view returns (uint){
        return referree[self].length;
    }

    function notifyReferReward(address _referrer, address _referree, uint amount) internal {
        referReward[_referrer] = referReward[_referrer].add(amount);
        emit ReferReward(_referrer, _referree, amount);
    }
    
}