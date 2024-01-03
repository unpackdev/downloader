pragma solidity ^0.6.8;

import "./ERC20.sol";
import "./IUniswapV2Factory.sol";

contract TheCannabisCommunity is ERC20 {
    address private _minter;
    address private _staking;
    address private _admin;

    address public factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public rfiPair;

    constructor(address minter_) ERC20("The Cannabis Community", "TCC") public {
        _minter = minter_;
        _admin = msg.sender;
        _mint(msg.sender, 332 ether);
    }

    function mint(address recipient_, uint256 amount_) external {
        require(msg.sender == _minter, 'ONLY MINTER');
        _mint(recipient_, amount_);
    }

    function createPair(address tokenB_) external {
        require(msg.sender == _admin, "FORBIDDEN");
        rfiPair = IUniswapV2Factory(factory).createPair(address(this), tokenB_);
    }
}