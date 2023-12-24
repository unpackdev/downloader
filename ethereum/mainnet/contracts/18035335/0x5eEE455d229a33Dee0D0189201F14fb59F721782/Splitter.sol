// SPDX-License-Identifier: MIT
// 
//          NNNNNNNN        NNNNNNNN     OOOOOOOOO     NNNNNNNN        NNNNNNNNEEEEEEEEEEEEEEEEEEEEEE
//          N:::::::N       N::::::N   OO:::::::::OO   N:::::::N       N::::::NE::::::::::::::::::::E
//          N::::::::N      N::::::N OO:::::::::::::OO N::::::::N      N::::::NE::::::::::::::::::::E
//          N:::::::::N     N::::::NO:::::::OOO:::::::ON:::::::::N     N::::::NEE::::::EEEEEEEEE::::E
//          N::::::::::N    N::::::NO::::::O   O::::::ON::::::::::N    N::::::N  E:::::E       EEEEEE
//          N:::::::::::N   N::::::NO:::::O     O:::::ON:::::::::::N   N::::::N  E:::::E             
//          N:::::::N::::N  N::::::NO:::::O     O:::::ON:::::::N::::N  N::::::N  E::::::EEEEEEEEEE   
//          N::::::N N::::N N::::::NO:::::O     O:::::ON::::::N N::::N N::::::N  E:::::::::::::::E   
//          N::::::N  N::::N:::::::NO:::::O     O:::::ON::::::N  N::::N:::::::N  E:::::::::::::::E   
//          N::::::N   N:::::::::::NO:::::O     O:::::ON::::::N   N:::::::::::N  E::::::EEEEEEEEEE   
//          N::::::N    N::::::::::NO:::::O     O:::::ON::::::N    N::::::::::N  E:::::E             
//          N::::::N     N:::::::::NO::::::O   O::::::ON::::::N     N:::::::::N  E:::::E       EEEEEE
//          N::::::N      N::::::::NO:::::::OOO:::::::ON::::::N      N::::::::NEE::::::EEEEEEEE:::::E
//          N::::::N       N:::::::N OO:::::::::::::OO N::::::N       N:::::::NE::::::::::::::::::::E
//          N::::::N        N::::::N   OO:::::::::OO   N::::::N        N::::::NE::::::::::::::::::::E
//          NNNNNNNN         NNNNNNN     OOOOOOOOO     NNNNNNNN         NNNNNNNEEEEEEEEEEEEEEEEEEEEEE
// 
// 
//                  An enterprise level discord based NFT and shitcoin trading tool...
// 
//                                          https://noneth.io
//                                        https://docs.noneth.io
//                                      https://discord.gg/noneth
//                                     https://twitter.com/nonethio
// 
//                                          None Splitter Contract
//                      The purpose of this contract is to run the bot fees through it,
//                                     and automatically splitting it.
//                                              40% Team
//                                             40% Holders
//                                             20% Referrer

pragma solidity 0.8.19;

contract Splitter {
    address payable public constant team = payable(0x8B8af6C77C6AD634a236448143f888BEd585348b); // team address
    address payable public constant holder = payable(0x6dE12E27A193E036f0C91C5762794cC6410a13C1); // holder address
    event Split(address indexed referrer, uint256 value);

    constructor() payable {
    }
    error TransferToTeamFailed();
    error TransferToReferrerFailed();
    error TransferToHolderFailed();
    function splitFunds_j78(address payable referrer) external payable {
        uint256 teamAndHolderAmount;
        uint256 referrerAmount;
        unchecked {
            if (referrer != address(0)) 
                referrerAmount = (msg.value * 20) / 100; // If referrer is supplied 20%

            teamAndHolderAmount = (msg.value - referrerAmount) / 2; // Split this and send equal amounts to team/holders
        }

        // Transfer the amounts 
        (bool successTeam, ) = team.call{value: teamAndHolderAmount}("");
        if (!successTeam) {
            revert TransferToTeamFailed();
        }

        (bool successHolder, ) = holder.call{value: teamAndHolderAmount}("");
        if (!successHolder) {
            revert TransferToHolderFailed();
        }

        if (referrerAmount >= 1) {
            (bool successReferrer, ) = referrer.call{value: referrerAmount}("");
            if (!successReferrer) {
                revert TransferToReferrerFailed();
            }
        }

        emit Split(referrer, msg.value); // Event emission
    }
}