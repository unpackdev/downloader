// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC1155.sol";
import "./Ownable.sol";

//  ___ ___ ___  __  __ ___ ___
// | _ )_ _/ _ \|  \/  | __/ __|
// | _ \| | (_) | |\/| | _|\__ \
// |___/___\___/|_|  |_|___|___/
//

contract Biomes is ERC721, ERC721Enumerable, Ownable {

    string public baseURI;
    IERC1155 public constant OPENSEA_STORE = IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e);
    address public constant burn = address(0x000000000000000000000000000000000000dEaD);

    constructor() ERC721("Biomes", "BIOMES") {
        baseURI = 'https://nftribe-biomes.s3.eu-west-2.amazonaws.com/t/';
    }

    // Inspired from CyberKongz! Thanks for everything you are doing.
    function isValidBiome(uint256 _id) public pure returns(bool) {
        if (_id >> 96 != 0x000000000000000000000000547e4f8fcE41fE8e46dbe7554B9153Ea087311d7)
			return false;
		if (_id & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1)
			return false;
		uint256 id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		if (id > 207 || id < 2 || id == 80 || id == 102 || id == 159 || id == 195 || id == 196 || id == 197)
			return false;
		return true;
    }

    // Translation between OpenSea IDs to Biomes IDs
    function returnCorrectId(uint256 _id) internal pure returns(uint256) {
        uint256 id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;

        // Specific cases:
        if (id == 5)
            return 5;
        else if (id == 20)
            return 19;
        else if (id == 21)
            return 18;
        else if (id == 72)
            return 42;
        else if (id == 73)
            return 76;
        else if (id == 75)
            return 77;
        else if (id == 76)
            return 72;
        else if (id == 77 || id == 78)
            return id + 1;
        else if (id == 79)
            return 74;
        else if (id == 81)
            return 75;
        else if (id == 82)
            return 73;
        else if (id == 103)
            return 96;
        else if (id == 6 || id == 7)
            return id - 3;
        // Other cases:
		else if (id > 197)
			return id - 8;
        else if (id > 159)
			return id - 5;
        else if (id > 103)
			return id - 4;
        else if (id > 98)
            return id - 2;
        else if (id > 73)
            return id - 3;
        else if (id > 43)
            return id - 1;
		else
			return id - 2;
	}

    function swapBiome(uint256 _tokenId) external {
        require(isValidBiome(_tokenId), "Not a valid Biome");
        uint256 id = returnCorrectId(_tokenId);

		_safeMint(msg.sender, id);
		OPENSEA_STORE.safeTransferFrom(msg.sender, burn, _tokenId, 1, "");
    }

    // Should not be called. Just in case.
    function emergencyMint(uint256 _newTokenId, address owner) external onlyOwner {
        require(totalSupply() < 201, "Already 200 Biomes minted.");

        _safeMint(owner, _newTokenId);
    }

    // Helper to list all the Biomes of a wallet
    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function setBaseURI(string memory _URI) external onlyOwner {
        baseURI = _URI;
    }

    function _baseURI() internal view override(ERC721) returns(string memory) {
        return baseURI;
    }

    // If anyone is sending money to this contract? You never know.
    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;
        require(payable(msg.sender).send(_balance));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}