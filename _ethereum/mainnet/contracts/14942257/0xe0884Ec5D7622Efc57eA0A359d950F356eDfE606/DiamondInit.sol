// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import "./LibAppStorage.sol";
import "./LibDiamond.sol";
import "./IDiamondLoupe.sol";
import "./IDiamondCut.sol";
import "./IERC173.sol";
import "./IERC165.sol";

// It is exapected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

contract DiamondInit {
    AppStorage internal s;

    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init() external {
        //string arrays
        s.LETTERS = [
            "a",
            "b",
            "c",
            "d",
            "e",
            "f",
            "g",
            "h",
            "i",
            "j",
            "k",
            "l",
            "m",
            "n",
            "o",
            "p",
            "q",
            "r",
            "s",
            "t",
            "u",
            "v",
            "w",
            "x",
            "y",
            "z"
        ];

        s.MAX_SUPPLY = 3000;

        //Declare all the rarity tiers
        //Head
        s.TIERS[0] = [ 100, 125, 125, 125, 150, 150, 150, 150, 150, 200, 250, 250, 300, 400, 400, 400, 400, 1000, 1100, 1200, 1300, 1850];
        //Face
        s.TIERS[1] = [ 275, 325, 1400, 1500, 1600, 1600, 3300 ];
        //Eyes
        s.TIERS[2] = [ 100, 100, 150, 200, 250, 300, 300, 300, 300, 300, 350, 350, 350, 350, 350, 400, 400, 400, 400, 400, 600, 600, 600, 600, 600, 950];
        //Hands
        s.TIERS[3] = [ 500, 1000, 1000, 2250, 2250, 3000 ];
        //Back
        s.TIERS[4] = [ 50, 500, 500, 1500, 1500, 1500, 4450 ];
        //Body
        s.TIERS[5] = [ 50, 50, 60, 70, 70, 1200, 1200, 1240, 1240, 1240, 1240, 2340 ];

        s._owner = msg.sender;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
    }


}
