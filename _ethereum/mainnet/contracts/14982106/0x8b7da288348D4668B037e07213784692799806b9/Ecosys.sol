pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";

contract Ecosys is Ownable, ERC20 {
    constructor() public ERC20("Ecosys", "ECO") { }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}