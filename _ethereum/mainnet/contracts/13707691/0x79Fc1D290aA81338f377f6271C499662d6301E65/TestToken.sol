// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


import "./BEP20Upgradeable.sol";

contract TestToken is BEP20Upgradeable {
    // STATE VARIABLES
    mapping(address => bool) private _minters;
    uint public ownerInt;

    // MODIFIERS
    modifier onlyMinter() {
        require(isMinter(msg.sender), "TestToken: caller is not the minter");
        _;
    }

    // INITIALIZER
    function initialize() external initializer {
        __BEP20__init("TestToken Token", "TST", 18);
        _minters[owner()] = true;
        ownerInt = 0;
    }

    // RESTRICTED FUNCTIONS
    function setOwnerInt(uint _ownerInt) external onlyOwner {
        ownerInt = _ownerInt;
    }

    function multiplyOwnerInt(uint multiplier, uint plus) external onlyOwner {
        ownerInt = ownerInt.mul(multiplier).add(plus);
    }

    function setMinter(address minter, bool canMint) external onlyOwner {
        _minters[minter] = canMint;
    }

    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }


    // VIEWS
    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }
}
