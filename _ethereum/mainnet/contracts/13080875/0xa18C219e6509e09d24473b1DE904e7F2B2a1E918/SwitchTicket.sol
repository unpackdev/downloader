// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./SwitchERC20.sol";

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract SwitchTicket is SwitchERC20 {
    bool initialized;
    uint public constant version = 1;
    address public token;
    address public owner;

    event OwnerChanged(address indexed _user, address indexed _old, address indexed _new);

    modifier onlyOwner() {
        require(msg.sender == owner, 'SwitchTicket: FORBIDDEN');
        _;
    }
 
    function initialize(address _owner, address _token, string calldata _symbol, string calldata _name) external {
        require(!initialized, 'SwitchTicket: initialized');
        initialized = true;
        owner = _owner;
        token = _token;
        symbol = _symbol;
        name = _name;
        decimals = SwitchERC20(_token).decimals();
    }

    function changeOwner(address _user) external onlyOwner {
        require(owner != _user, 'SwitchTicket: NO CHANGE');
        emit OwnerChanged(msg.sender, owner, _user);
        owner = _user;
    }

    function mint(address to, uint value) external onlyOwner returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(address from, uint value) external onlyOwner returns (bool) {
        _burn(from, value);
        return true;
    }
}
