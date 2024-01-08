/*

__________    _____ _____.___._________  
\______   \  /  _  \\__  |   |\_   ___ \ 
 |    |  _/ /  /_\  \/   |   |/    \  \/ 
 |    |   \/    |    \____   |\     \____
 |______  /\____|__  / ______| \______  /
        \/         \/\/               \/ 

⭐ BAYC Token⭐ 

The BAYC Token is a token focused on buying coins and using those profits to benefit holders.

https://t.me/BAYC_YIELD

*/

pragma solidity ^0.8.0;

import "./base.sol";

contract BAYC is ERC20 {
    uint8 private immutable _decimals = 18;
    uint256 private _totalSupply = 1000000000000 * 10**18;

    constructor() ERC20(unicode"Buying All Yielding Coins", "BAYC") {
        _deploy(_msgSender(), _totalSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
