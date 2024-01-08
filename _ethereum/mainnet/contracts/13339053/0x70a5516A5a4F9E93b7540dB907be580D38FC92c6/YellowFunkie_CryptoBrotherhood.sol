// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title YellowFunkie_CryptoBrotherhood
 * YellowFunkie_CryptoBrotherhood - a contract for my non-fungible creatures.
 */
contract YellowFunkie_CryptoBrotherhood is ERC721Tradable {
	
	constructor(address _proxyRegistryAddress)
        ERC721Tradable("YellowFunkie_CryptoBrotherhood", "YFCB", _proxyRegistryAddress, 40000, "api/creature/")
    {
	}

}
