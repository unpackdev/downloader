// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./SafeMath.sol";

contract VirtualBalanceWrapper {
    using SafeMath for uint256;

    address public owner;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _owner) public {
        owner = _owner;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _for) public view returns (uint256) {
        return _balances[_for];
    }

    function stakeFor(address _for, uint256 _amount) public returns (bool) {
        require(
            msg.sender == owner,
            "VirtualBalanceWrapper: !authorized stakeFor"
        );
        require(_amount > 0, "VirtualBalanceWrapper: !_amount");

        _totalSupply = _totalSupply.add(_amount);
        _balances[_for] = _balances[_for].add(_amount);

        return true;
    }

    function withdrawFor(address _for, uint256 _amount) public returns (bool) {
        require(
            msg.sender == owner,
            "VirtualBalanceWrapper: !authorized withdrawFor"
        );
        require(_amount > 0, "VirtualBalanceWrapper: !_amount");

        _totalSupply = _totalSupply.sub(_amount);
        _balances[_for] = _balances[_for].sub(_amount);

        return true;
    }
}

contract VirtualBalanceWrapperFactory {
    event NewOwner(address indexed sender, address operator);
    event RemoveOwner(address indexed sender, address operator);

    mapping(address => bool) private owners;

    modifier onlyOwners() {
        require(isOwner(msg.sender), "vbw: caller is not an owner onlyOwners");
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address _newOwner) public onlyOwners {
        require(!isOwner(_newOwner), "vbw: address is already owner addOwner");

        owners[_newOwner] = true;

        emit NewOwner(msg.sender, _newOwner);
    }

    function addOwners(address[] calldata _newOwners) external onlyOwners {
        for (uint256 i = 0; i < _newOwners.length; i++) {
            addOwner(_newOwners[i]);
        }
    }

    function removeOwner(address _owner) external onlyOwners {
        require(isOwner(_owner), "vbw: address is not owner removeOwner");

        owners[_owner] = false;

        emit RemoveOwner(msg.sender, _owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return owners[_owner];
    }

    function createWrapper(address _owner) public onlyOwners returns (address) {
        return address(new VirtualBalanceWrapper(_owner));
    }
}
