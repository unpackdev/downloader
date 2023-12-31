// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "./ERC20.sol";
import "./Ownable.sol";

contract HI is ERC20, Ownable {
    bool public mintingFinished = false;

    constructor() ERC20("Hares Intelligence", "HI") {}

    function mint(address to) public onlyOwner {
        require(!mintingFinished);
        mintingFinished = true;

        _mint(to, 1000000000 * (10 ** decimals()));
    }
}
