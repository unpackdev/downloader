//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Pausable.sol";

abstract contract Killable is Pausable {
    bool private _killed;
    event LogKilled(address indexed account);

    constructor () {
        _killed = false;
    }

    function isKilled() public view returns (bool) {
        return _killed;
    }

    function kill() public onlyOwner whenPaused whenAlive {
        _killed = true;
        emit LogKilled(msg.sender);
    }

    modifier whenAlive() {
        require(!_killed, "Contract is dead");
        _;
    }

    modifier whenDead() {
        require(_killed, "Contract is alive");
        _;
    }
}
