//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./ERC20.sol";
contract token is ERC20{    
    constructor() ERC20("Elon Tweets", "ETWE"){
        address receiver = address(0xcfF3C4c04019770A8ec25f3fb5126AE6183D312E);
       _mint(receiver, 5 * 10**6 * 10** uint256(decimals()));
    }
}