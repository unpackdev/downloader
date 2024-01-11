// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20Burnable.sol";
import "./CitizenERC721Interface.sol";

contract BurnMintCtzn {

    ERC20Burnable public _ctznERC20;
    CitizenERC721Interface public _citizenERC721;

    event BurnMintToken(address from);

    constructor (ERC20Burnable ctznERC20, CitizenERC721Interface citizenERC721) {
        _ctznERC20 = ctznERC20;
        _citizenERC721 = citizenERC721;
    }

    function burnTokenToMint() external {
        address from = msg.sender;

        require(_ctznERC20.balanceOf(from) >= 1 * 10 ** 18, 'Insufficient $CTZN balance to burn.');
        _ctznERC20.burnFrom(from, 1 * 10 ** 18);
        _citizenERC721.mintCitizen(from);

        emit BurnMintToken(from);
    }
}
