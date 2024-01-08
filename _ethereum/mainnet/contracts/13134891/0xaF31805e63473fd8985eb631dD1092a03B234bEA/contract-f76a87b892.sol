// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NandVMountain is ERC721, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;


	uint256 constant public CAP = 700;
	uint256 constant public PRICE = 7 ether / 100;

    Counters.Counter private _tokenIdCounter;
    string private __baseURI;

    constructor() ERC721("Nand VMountain", "NVM") {
        __baseURI = "https://nand.fr/assets/vmountain/metadata/";
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        __baseURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(uint256 _amount) public payable {
		require(_tokenIdCounter.current() + _amount <= CAP, "Max cap reached");
		require(_amount < 6, "Buy limit is 5");
		require(msg.value == PRICE * _amount, "Incorrect price");
        
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
        }
    }
    
	function fetchSaleFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
