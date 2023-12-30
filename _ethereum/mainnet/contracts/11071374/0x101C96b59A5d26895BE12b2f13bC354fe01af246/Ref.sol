/**
 *Submitted for verification at BscScan.com on 2020-10-16
*/

// SPDX-License-Identifier: None
pragma solidity ^0.6;

contract Ref {

    mapping(address => address) public referrer;
    mapping(address => uint) public score;
    mapping(address => bool) public admin;

    modifier onlyAdmin() {
        require(admin[msg.sender], "You're not admin");
        _;
    }

    constructor() public  {
        admin[msg.sender] = true;        
    }
    function set_admin(address a) onlyAdmin() external {
        admin[a] = true;
    }
    function set_referrer(address r) onlyAdmin() external {
        if (referrer[tx.origin] == address(0)) {
            referrer[tx.origin] = r;
            emit ReferrerSet(tx.origin, r);
        }
    }
    function add_score(uint d) onlyAdmin() external {
        score[referrer[tx.origin]] += d;
        emit ScoreAdded(tx.origin, referrer[tx.origin], d);
    }

    event ReferrerSet(address indexed origin, address indexed referrer);
    event ScoreAdded(address indexed origin, address indexed referrer, uint score);
}