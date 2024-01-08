// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./ERC20.sol";

contract UToken is ERC20 {

    address private _owner;

    constructor(string memory _symbol, uint8 _decimals) ERC20(_symbol, _symbol, _decimals) {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, 'Only Owner!');
        _;
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
        emit Mint(msg.sender, account, amount);
    }

    function burn(address account, uint256 value) external onlyOwner {
        _burn(account, value);
        emit Burn(msg.sender, account, value);
    }

    event Mint(address sender, address account, uint amount);
    event Burn(address sender, address account, uint amount);

}
