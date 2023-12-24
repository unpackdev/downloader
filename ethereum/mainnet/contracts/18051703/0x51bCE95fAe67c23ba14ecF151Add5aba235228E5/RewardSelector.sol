// SPDX-License-Identifier: None

pragma solidity >=0.7.0 <0.9.0;

contract RewardSelector {

    struct Reward{
        bytes32[] names;
        uint16[] values;
    }

    mapping(address => Reward) private _reward;


    constructor() {
    }

    function change(bytes32[] memory names, uint16[] memory values) external{
        require(values.length == names.length, "lengths dont match");
        _reward[msg.sender].names = names;
        _reward[msg.sender].values = values;
    }

    function get(address account) view external returns (bytes32[] memory names, uint16[] memory values){
        return (_reward[account].names, _reward[account].values);
    }

}