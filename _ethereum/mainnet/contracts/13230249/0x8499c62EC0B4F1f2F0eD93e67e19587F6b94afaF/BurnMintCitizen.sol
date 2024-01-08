// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Burnable.sol";
import "./CitizenERC721Interface.sol";

contract BurnMintCitizen {

    ERC20Burnable public _citizenERC20;
    CitizenERC721Interface public _citizenERC721;

    event BurnMintToken(address from);

    constructor (ERC20Burnable citizenERC20, CitizenERC721Interface citizenERC721) public {
        _citizenERC20 = citizenERC20;
        _citizenERC721 = citizenERC721;
    }

    function burnTokenToMint() external {
        address from = msg.sender;

        require(_citizenERC20.balanceOf(from) >= 1 * 10 ** 18, 'Insufficient $CITIZEN balance to burn.');
        _citizenERC20.burnFrom(from, 1 * 10 ** 18);
        _citizenERC721.mint(from);

        emit BurnMintToken(from);
    }
}