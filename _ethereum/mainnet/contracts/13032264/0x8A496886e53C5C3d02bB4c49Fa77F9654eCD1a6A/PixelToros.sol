// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract PixelToros is ERC721Enumerable, Ownable {
	using SafeMath for uint256;

	uint256 public constant MAX_PIXEL_TOROS = 10000;

	uint256 public constant pixelToroPrice = 50000000000000000; // 0.05 ETH

	uint public constant maxPixelTorosPurchase = 10;

	bool public isSaleActive = false;
	
	constructor() ERC721("PixelToros", "TORO") {}

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return "ipfs://Qme95kGM3Y2WTqB4ospHBCFKsWnX8Wb1Zfkq1nBmQDc22P/";
	}

	/**
	 * Set some PixelToros aside
	 */
	function reservePixelToros() public onlyOwner {
		for (uint i = 0; i < 30; i++) {
			uint256 newToroId = totalSupply();
			_safeMint(msg.sender, newToroId);
		}
	}

	/**
	 * Pause sale if active, make active if paused
	 */
	function flipSaleState() public onlyOwner {
		isSaleActive = !isSaleActive;
	}

	/**
	 * Mints PixelToros
	 */
	function mintPixelToros(uint numberOfPixelToros) public payable {
		require(isSaleActive, "Sale must be active to mint PixelToros");
		require(numberOfPixelToros <= maxPixelTorosPurchase, "Can only mint 10 PixelToros at a time");
		require(totalSupply().add(numberOfPixelToros) <= MAX_PIXEL_TOROS, "Purchase would exceed max supply of PixelToros");
		require(pixelToroPrice.mul(numberOfPixelToros) <= msg.value, "Ether value sent is not correct");
		
		for(uint i = 0; i < numberOfPixelToros; i++) {
			uint256 newToroId = totalSupply();

			if (totalSupply() < MAX_PIXEL_TOROS) {
				_safeMint(msg.sender, newToroId);
			}
		}
	}
}
