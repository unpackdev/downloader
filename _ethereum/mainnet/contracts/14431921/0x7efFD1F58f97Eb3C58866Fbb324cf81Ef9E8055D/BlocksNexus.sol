// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: BLOCKS

import "./BlocksERC721Parcels.sol";

/**
 * BlocksNexus - BlocksERC721Parcels for the Nexus community

MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOxkxONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMNXKKKKKKKKKKXXNMWNXKKKKXNMMMMMMMMWNOl'..;. 'lkXWMMMMMMWNXXKXKKXKKKXWMWNXKKKKXNMWXKKKKXNMWXKKKKXXXKKXNWMMMMMMMM
MMMMMMMWx.......'.....,dKl......dWMMMMWXkl'    .;.    'ckXWMMKl'....''.....;kKc.....'xWk,....:Ox;.....''....'oXMMMMMMM
MMMMMMMWo      ':.     'x;      lNMMMKl.       .;.       .cdOo      ':.     'x,      oO,    .xO'     .:'     .dWMMMMMM
MMMMMMMWo      ,c.     'x;      lNMMWd         .:.         .ll      ,c.     'd,      ::    .xWO.     .c,      dWMMMMMM
MMMMMMMWo      ,c.     ;k;      lNMMWo         .:.         .cl      ,c.     'd;      .    .dWM0,     .:c,,,,:oKMMMMMMM
MMMMMMMWo      .'     ;OK;      cXWWWo       ..,;,..       .cl      ,xocccccxO,          .oNMMWOc,'''',......cKMMMMMMM
MMMMMMMWo      .;.    .cO;      .,,;xl    ..''.   .''..    .cc      ,dc,,,,,lk,           lNMMKc,'''':o'     .dWMMMMMM
MMMMMMMWo      ,c.     'x:          cl..'''.         ..''...lc      ,c.     'd;      .    .oNMO.     .c,      dWMMMMMM
MMMMMMMWo      ,c.     'x:          cOl,.               .'cdOl      ,c.     'd;      cc    .oNO.     .c,      dWMMMMMM
MMMMMMMWo      ';.     ,k:          lNXxc.             .:xXWWd.     ';.     ,x;      o0;    .dO'     .:.     .xWMMMMMM
MMMMMMMWx,''''',,'''',cOXo''''''''',xWMMWXkl'       'ckXWMMMMXd;,''',,'''',cOKo''''',kWO:''''cOOc,'''',,''',:dXMMMMMMM
MMMMMMMMWNNNNNNNNNNNNWWMMWNNNNNNNNNNWMMMMMMMNOo,.,lONMMMMMMMMMMWWNNNNNNNNNWWMMWNNNNNNWMMWNNNNNWMWWNNNNNNNNNWWMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/

contract BlocksNexus is BlocksERC721Parcels {

 constructor(string memory name, string memory symbol, address proxyRegistryAddress) BlocksERC721Parcels (name, symbol, proxyRegistryAddress) {}

}