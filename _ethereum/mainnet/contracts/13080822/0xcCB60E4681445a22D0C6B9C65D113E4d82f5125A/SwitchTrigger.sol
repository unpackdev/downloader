// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./Configable.sol";
import "./Initializable.sol";


contract SwitchTrigger is Configable, Initializable {
    string public constant name = "SwitchTrigger";

    mapping(address => bool) whiteList;
    event Trigger(address indexed user, uint indexed signal);

    function initialize() public initializer {
        owner = msg.sender;
        whiteList[msg.sender] = true;
    }

    function setWhite(address _user, bool _value) public onlyDev {
        whiteList[_user] = _value;
    }

    function trigger(uint _signal) public {
        require(whiteList[msg.sender], "FORBIDDEN");
        emit Trigger(msg.sender, _signal);
    }

    function subscribeTreasury(address _from, address _to, address _token, uint _value) external returns (bool) {
        return true;
    }
}