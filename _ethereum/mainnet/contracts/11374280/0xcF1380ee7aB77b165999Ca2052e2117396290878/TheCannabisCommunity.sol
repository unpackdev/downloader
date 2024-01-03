pragma solidity ^0.6.2;

import "./ERC20.sol";

contract TheCannabisCommunity is ERC20 {
    address private _minter;

    constructor(address minter_) ERC20("The Cannabis Community", "TCC") public {
        _minter = minter_;
        _mint(msg.sender, 2 ether);
    }

    function mint(address recipient, uint256 amount_) external {
        require(msg.sender == _minter, 'ONLY MINTER');
        _mint(recipient, amount_);
    }

}
