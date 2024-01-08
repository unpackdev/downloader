// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";

contract HyperUnity is Ownable, ERC20Capped {
    
    address constant public TREASURE_ADDRESS = 0xD57196e9d2D2980647A04aFa5dB83F3919117A5d;
    address constant public DEV_ADDRESS = 0x9A4fA16Cc8eEfE428A0eD0e3feCA1290dF7D32f0;
    address constant public COLLATERAL_ADDRESS = 0xA8e0250eC7F57Ad8107C8Df3138838e02d856434;

    constructor() ERC20("HyperUnity", "HYCO") ERC20Capped(10000 * 10**6 * 10**18) {
        uint256 cap = 10000 * 10**6 * 10**18;
        uint256 treasure = 700 * 10**6 * 10**18;
        uint256 dev = 500 * 10**6* 10**18;
        uint256 collateral = 1000*  10**6* 10**18;
        uint256 owner = 7800 * 10**6* 10**18;
        uint256 initialBalance = treasure + dev + collateral + owner;
        require(initialBalance == cap, "CommonERC20: initial allocations wrong"); 
        ERC20._mint(msg.sender, owner);
        ERC20._mint(TREASURE_ADDRESS, treasure);
        ERC20._mint(DEV_ADDRESS, dev);
        ERC20._mint(COLLATERAL_ADDRESS, collateral);
    }
}