// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SpecialEtherealWorlds is Ownable, ERC721Enumerable {
    using Strings for uint256;
    string public baseURI = "https://data.forgottenethereal.world/metadata/";

    constructor() ERC721("Forgotten Ethereal Worlds Specials", "FEWS") {}

	function airdropWorld(address _recipient) external onlyOwner {
		require(totalSupply() < 5, "All 1/1's minted");
		_safeMint(_recipient, 345 + totalSupply());
	}

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	    require(_exists(tokenId), "ERC721Metadata: Unknown token");
	    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
	}
}