pragma solidity ^0.6.8;

import "./ERC20.sol";

contract CROPu is ERC20 {
    address private _minter;

    constructor(address minter_) ERC20("CROP(Public)", "CROPu") public {
        _minter = minter_;
        _mint(msg.sender, 2 ether);
    }

    function mint(address recipient, uint256 amount_) external {
        require(msg.sender == _minter, 'ONLY MINTER');
        _mint(recipient, amount_);
    }

}
