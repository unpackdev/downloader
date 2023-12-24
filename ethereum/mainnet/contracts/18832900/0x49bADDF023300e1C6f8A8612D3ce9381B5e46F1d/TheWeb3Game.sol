// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author wizrd0x

import "./ERC721APassiveStaking.sol";
import "./Treasury.sol";

/////////////////////////////////////////////////////////////////////////////////////////////
//  _______  _            __          __    _     ____     _____                           //
// |__   __|| |           \ \        / /   | |   |___ \   / ____|                          //
//    | |   | |__    ___   \ \  /\  / /___ | |__   __) | | |  __   __ _  _ __ ___    ___   //
//    | |   | '_ \  / _ \   \ \/  \/ // _ \| '_ \ |__ <  | | |_ | / _` || '_ ` _ \  / _ \  //
//    | |   | | | ||  __/    \  /\  /|  __/| |_) |___) | | |__| || (_| || | | | | ||  __/  //
//    |_|   |_| |_| \___|     \/  \/  \___||_.__/|____/   \_____| \__,_||_| |_| |_| \___|  //
//                                                                                         //
/////////////////////////////////////////////////////////////////////////////////////////////

contract TheWeb3Game is ERC721APassiveStaking {
    constructor(
        string memory _name,
        string memory _symbol,
        address _recipient,
        uint256 _royalty,
        address _owner
    ) ERC721APassiveStaking(_name, _symbol, _recipient, _royalty, _owner) {}

    bool public isAirdropActive = true;

    function refreshMetadata() public {
        emit BatchMetadataUpdate(_startTokenId(), _totalMinted());
    }

    function reveal(string memory baseURI) public isAdmin {
        _setRevealed();
        _setBaseURI(baseURI);
    }

    function airdrop(address[] memory accounts, uint256[] memory amounts) public isAdmin {
        require(isAirdropActive, "Web3GamePass: Airdrop is over");
        require(accounts.length == amounts.length, "TheWeb3Game: accounts and amounts length mismatch");
        for (uint256 i = 0; i < accounts.length; i++) {
            _safeMint(accounts[i], amounts[i]);
        }
    }

    function disableAirdrop() public isAdmin {
        isAirdropActive = false;
    }
}
