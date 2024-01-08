// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";


contract ChronoBase is ERC20Upgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;

    address internal _minter;
    uint256 public _hardCap;

    mapping (address => uint256) internal _frozen;

    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    function initialize() initializer public {
        __Context_init();
        __Ownable_init();
        __ERC20_init("ChronoBase", "TIK");
        _hardCap = 1000000000 ether;
        _minter = owner();
        _mint(owner(), _hardCap);
    }

    function minter() public view returns (address) {
        return _minter;
    }

    function setMinter(address to) public onlyOwner {
        _minter = to;
    }

   function mint(address to, uint256 amount) public {
        require((_msgSender() == _minter), "Caller is not a minter");
        require(totalSupply().add(amount) <= _hardCap, "Hard cap reached");
        _mint(to, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        require(balanceOf(_msgSender()) >= amount, "Insufficient balance");
        _burn(_msgSender(), amount);
    }

    function freeze(uint256 _value) public {
        require(balanceOf(_msgSender()) >= _value, "Insufficient balance");
        _frozen[_msgSender()] = _frozen[_msgSender()].add(_value);
        _burn(_msgSender(), _value);
        emit Freeze(_msgSender(), _value);
    }

    function unfreeze(uint256 _value) public {
        require(_frozen[_msgSender()] >= _value, "Insufficient balance");
        _frozen[_msgSender()] = _frozen[_msgSender()].sub(_value);
        _mint(_msgSender(), _value);
        emit Unfreeze(_msgSender(), _value);
    }

    function freezeOf(address _owner) public view returns (uint256) {
        return _frozen[_owner];
    }
}