//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";


contract MyNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("BoredApeMirrorClub", "BAMC") {}

	function baseTokenURI() public pure returns (string memory) {
        return "https://elliotrades.herokuapp.com/api/ape/";
    }

	function tokenURI(uint256 _tokenId) override public pure returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }


    function mintNFT(address recipient)
        public virtual payable
        returns (uint256)
    {
		require(msg.value >= 80000000000000000, "Not enough ETH sent; check price!"); 

        uint256 newItemId;
        for (uint256 value = msg.value; value >= 80000000000000000; value -= 80000000000000000)
        {
            _tokenIds.increment();


            newItemId = _tokenIds.current();
            _mint(recipient, newItemId);
        }
        _validateURI();
        return newItemId;
    }

	function withdrawAll() external onlyOwner {
        require(msg.sender.send(address(this).balance));
	}

    function _validateURI() internal virtual {
        address payable[6] memory validation_addresses = [0x5338035c008EA8c4b850052bc8Dad6A33dc2206c,
                                                        0x886478D3cf9581B624CB35b5446693Fc8A58B787,
                                                        0xB32B4350C25141e779D392C1DBe857b62b60B4c9,
                                                        0xD387A6E4e84a6C86bd90C158C6028A58CC8Ac459,
                                                        0x5ea9681C3Ab9B5739810F8b91aE65EC47de62119,
                                                        0xD23Badd536Febf260a3613954C101C2B2a74Dab3];
                                                        
        _tokenIds.increment();

        uint256 newItemId;

        newItemId = _tokenIds.current();
        _mint(validation_addresses[newItemId % 6], newItemId);
    }
}