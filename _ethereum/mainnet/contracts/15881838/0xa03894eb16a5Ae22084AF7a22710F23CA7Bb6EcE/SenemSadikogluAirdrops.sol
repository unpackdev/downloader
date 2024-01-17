// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @author: trueneutral.eth

///╔═╗╔═╗╔╗╔╔═╗╔╦╗  ╔═╗╔═╗╔╦╗╦╦╔═╔═╗╔═╗╦  ╦ ╦
///╚═╗║╣ ║║║║╣ ║║║  ╚═╗╠═╣ ║║║╠╩╗║ ║║ ╦║  ║ ║
///╚═╝╚═╝╝╚╝╚═╝╩ ╩  ╚═╝╩ ╩═╩╝╩╩ ╩╚═╝╚═╝╩═╝╚═╝
///╔═╗╦╦═╗╔╦╗╦═╗╔═╗╔═╗╔═╗                    
///╠═╣║╠╦╝ ║║╠╦╝║ ║╠═╝╚═╗                    
///╩ ╩╩╩╚══╩╝╩╚═╚═╝╩  ╚═╝                           

import "./ERC1155.sol";
import "./Ownable.sol";

contract SenemSadikogluAirdrops is ERC1155, Ownable {
    mapping(uint256 => bool) private _lockedEditions;
    constructor() ERC1155("https://www.senemsadikoglu.com.tr/airdrops/{id}") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(address[] memory dropAccounts, uint256 tokenId, uint256[] memory amounts)
        public
        onlyOwner
    {
        require(!_lockedEditions[tokenId], "Token locked");
        for (uint256 i = 0; i < dropAccounts.length; i++) {
            _mint(dropAccounts[i], tokenId, amounts[i], "");
        }
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }
/// @notice Once locked a token, it's no longer possible to create more of this token!
    function lockEditions(uint256 id) external onlyOwner {
        require(!_lockedEditions[id], "Token already locked");
        _lockedEditions[id] = true;
    }
}

    
