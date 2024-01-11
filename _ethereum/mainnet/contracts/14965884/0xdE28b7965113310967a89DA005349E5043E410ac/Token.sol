pragma solidity >=0.7.0 <0.9.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Token is ERC20, Ownable {

    constructor() ERC20("TeleToken", "TELE"){
        _mint(0x362f9E3d085B6d869501ca73c70F3b4d6Db5BfB9, 10000000000e18);
        _transferOwnership(0x362f9E3d085B6d869501ca73c70F3b4d6Db5BfB9);
    }

    function mint(address to, uint value) public onlyOwner {
        _mint(to, value);
    }
}
