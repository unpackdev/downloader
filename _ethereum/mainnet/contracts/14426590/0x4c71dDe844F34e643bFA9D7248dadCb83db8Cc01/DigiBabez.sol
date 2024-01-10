// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "Pausable.sol";
import "Ownable.sol";
import "ERC721Burnable.sol";
import "Counters.sol";

contract DigiBabez is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

		uint256 public tokenPrice;
		uint256 public normalPrice;
		uint256 public whitelistedPrice;
    uint256 public maximumPerWallet; 
    uint256 public maxNumberTokens;
    bool public whiteListIsOn;
    address salesWallet;

		mapping(address => bool) public whitelisted;

    constructor() ERC721("Digibabez", "DGB") {
        whitelistedPrice = 25000000000000000;
        normalPrice = 30000000000000000;

        maximumPerWallet = 6;
        maxNumberTokens = 1000;

        whiteListIsOn = true;
		}

    function _baseURI() internal pure override returns (string memory) {
        return "https://digibabez.com/api/";
    }

    function getContractValue() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

		function turnWhiteListOff() external onlyOwner {
			whiteListIsOn = false;
		}

		function batchWhitelist(address[] memory _users) external onlyOwner {
				 for(uint256 i=0; i< _users.length; i++){
						address user = _users[i];
						whitelisted[user] = true;
				 }
		 }

    function safeMint(address to, uint qtt) public payable {
				if (whiteListIsOn) {
					require(whitelisted[msg.sender], "Only whitelist can mint right now.");
				}
        tokenPrice = normalPrice;
        if (whitelisted[msg.sender]) {
          tokenPrice = whitelistedPrice;
        }

				require ((_tokenIdCounter.current() + qtt) < maxNumberTokens, "Sold out.");
				require ((balanceOf(to) + qtt) <= maximumPerWallet , "Maximum quantity per wallet exceeded");
				require (msg.value >= tokenPrice * qtt, "Insuficcient amount.");

				for(uint i = 0;i < qtt;i++) {
					uint256 tokenId = _tokenIdCounter.current();
					_tokenIdCounter.increment();
					_safeMint(to, tokenId);
				}
    }

    function distributeMint(address[] memory _to) external onlyOwner {
				require ((_tokenIdCounter.current() + _to.length) < maxNumberTokens, "");
        for(uint i = 0;i< _to.length;i++) {
					uint256 tokenId = _tokenIdCounter.current();
					_tokenIdCounter.increment();
					_safeMint(_to[i], tokenId);
				}
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

