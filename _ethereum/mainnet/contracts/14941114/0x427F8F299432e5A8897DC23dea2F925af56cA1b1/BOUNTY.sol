pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract BOUNTY is ERC20, ERC20Burnable, Ownable {

    constructor() ERC20("BOUNTY", "$BOUNTY") {}

    function mint(address to, uint256 amount) public onlyOwner{
        _mint(to, amount);
    }
}
