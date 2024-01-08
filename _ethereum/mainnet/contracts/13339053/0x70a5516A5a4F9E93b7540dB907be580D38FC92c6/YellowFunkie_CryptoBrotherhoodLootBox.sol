// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./YellowFunkie_CryptoBrotherhoodFactory.sol";


/**
 * @title CreatureLootBox
 *
 * CreatureLootBox - a tradeable loot box of Creatures.
 */
contract YellowFunkie_CryptoBrotherhoodLootBox is ERC721Tradable {

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("YellowFunkie_CryptoBrotherhoodLootBox", "YFCB-LOOTBOX", _proxyRegistryAddress, 1000, "api/box/")
    {
    }

    function unbox(uint256 _tokenId) public {
        require((ownerOf(_tokenId) == _msgSender()), "Can't unbox the token of someone else");

                
		// Mint the ERC721 item(s).
		YellowFunkie_CryptoBrotherhoodFactory factory = YellowFunkie_CryptoBrotherhoodFactory(getSpecialMintAddress());
		factory.mint_unbox(_msgSender());
        
        // Burn the presale item.
        _burn(_tokenId);
    }
	
    function itemsPerLootbox() public pure returns (uint256) {
        return 3;
    }
}
