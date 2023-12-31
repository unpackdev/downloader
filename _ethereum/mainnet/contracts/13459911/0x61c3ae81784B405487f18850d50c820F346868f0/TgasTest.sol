pragma solidity >=0.5.16;

import "./ERC2917Impl.sol";

contract TgasTest is ERC2917Impl("Demax Gas", "DGAS", 18, 1 * (10 ** 18)) {

    constructor() public {
        totalSupply += 1000000000000000* 10 ** 18;
        balanceOf[msg.sender] = 1000000000000000* 10 ** 18;   
    }
}
