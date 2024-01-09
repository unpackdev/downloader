// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract BUNSLANDElfree is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address private bank = 0x74CaD1e8e7a81215857ce194540dA21d29Ae22a2;
    bool public hasSaleStarted = false;

    constructor() ERC721("BUNS.LAND Elfree", "BLE") {}

    function safeMint(address to, uint256 numBuns) public payable {
    	require(hasSaleStarted, "Freemint has not started.");

        for (uint i = 0; i < numBuns; i++) {
            _tokenIdCounter.increment();
            _safeMint(to, _tokenIdCounter.current());
        }
    }

    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function stopSale() public onlyOwner {
        hasSaleStarted = false;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://nfts.buns.land/ble/";
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function withdraw() public onlyOwner {
        uint256 _balance = address(this).balance;

        require(payable(bank).send(_balance));
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


