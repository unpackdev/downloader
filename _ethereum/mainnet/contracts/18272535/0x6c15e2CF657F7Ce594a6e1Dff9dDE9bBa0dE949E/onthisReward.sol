// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";

// https://onthis.xyz
/*
 .d88b.  d8b   db d888888b db   db d888888b .d8888. 
.8P  Y8. 888o  88    88    88   88    88    88   YP 
88    88 88V8o 88    88    88ooo88    88     8bo. 
88    88 88 V8o88    88    88   88    88       Y8b. 
`8b  d8' 88  V888    88    88   88    88    db   8D 
 `Y88P'  VP   V8P    YP    YP   YP Y888888P  8888Y  
*/

contract OnthisReward is OwnableUpgradeable {
    // shortcut => multiplier
    mapping(address => uint256) public shortcutMultipliers;
    // user => totalCutPower
    mapping(address => uint256) public usersCutPower;

    uint256[50] private _gap;

    function initialize() public initializer {
        __Ownable_init();
    }

    function registerShortcut(
        address _shortcutAddr,
        uint256 muliplier
    ) public onlyOwner {
        shortcutMultipliers[_shortcutAddr] = muliplier;
    }

    function applyBonus(uint256 value) public {
        uint256 shortcutMultiplier = shortcutMultipliers[msg.sender];

        require(
            shortcutMultiplier != 0,
            "OnthisReward: Shortcut does not registered"
        );

        usersCutPower[tx.origin] += shortcutMultiplier * value;
    }
}
