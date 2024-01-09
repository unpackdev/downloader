// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "ReentrancyGuard.sol";

/*
                                        Authors: madjin.eth
                                            year: 2021

                ███╗░░░███╗░█████╗░██████╗░███████╗░█████╗░░█████╗░███████╗░██████╗
                ████╗░████║██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
                ██╔████╔██║███████║██║░░██║█████╗░░███████║██║░░╚═╝█████╗░░╚█████╗░
                ██║╚██╔╝██║██╔══██║██║░░██║██╔══╝░░██╔══██║██║░░██╗██╔══╝░░░╚═══██╗
                ██║░╚═╝░██║██║░░██║██████╔╝██║░░░░░██║░░██║╚█████╔╝███████╗██████╔╝
                ╚═╝░░░░░╚═╝╚═╝░░╚═╝╚═════╝░╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚══════╝╚═════╝░

*/

abstract contract CKeys {
    function balanceOf(address account, uint256 id) public view virtual returns (uint256);
    function burnKey(address account, uint256 keyId) external virtual;
}