//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

:::       :::     :::     :::::::::       :::::::::   ::::::::   ::::::::   ::::::::  
:+:       :+:   :+: :+:   :+:    :+:      :+:    :+: :+:    :+: :+:    :+: :+:    :+: 
+:+       +:+  +:+   +:+  +:+    +:+      +:+    +:+ +:+    +:+ +:+        +:+        
+#+  +:+  +#+ +#++:++#++: +#++:++#:       +#+    +:+ +#+    +:+ :#:        +#++:++#++ 
+#+ +#+#+ +#+ +#+     +#+ +#+    +#+      +#+    +#+ +#+    +#+ +#+   +#+#        +#+ 
 #+#+# #+#+#  #+#     #+# #+#    #+#      #+#    #+# #+#    #+# #+#    #+# #+#    #+# 
  ###   ###   ###     ### ###    ###      #########   ########   ########   ########  

*/

import "./ERC721.sol";
import "./Ownable.sol";

contract WarDogs is ERC721, Ownable {
	using Strings for uint256;

    // Initial 14 dogs were minted at https://foundation.app/@MindOfOsh
	uint256 public totalSupply = 14;
	string private notRevealedURI;
    string private baseURI;
	uint256 public price = 0.4 ether;
	uint256 public maxSupply = 497;
	uint256 public maxDogsPerWallet = 2;
	bool public paused = true;
	bool public revealed = false;

	constructor() ERC721("War Dogs", "WD") {
		notRevealedURI = "ipfs://QmUyMPm2ncHJ1yknj5k6KjdsYwZ5SW68mQrnxtXeNf98SK";

		for (uint256 i; i < 10; i++) {
			totalSupply++;
			_safeMint(msg.sender, totalSupply);
		}
	}

	function mintDogs(uint256 _amount) external payable {
		require(!paused, "Sale is inactive");
		require(msg.value == _amount * price, "Insufficient ETH sent");
		require(balanceOf(msg.sender) + _amount <= maxDogsPerWallet, "Only 2 dogs per wallet");
		require(totalSupply + _amount <= maxSupply, "Exceeds max supply");

		for (uint256 i; i < _amount; i++) {
			totalSupply++;
			_safeMint(msg.sender, totalSupply);
		}
	}

	function setPrice(uint256 _price) public onlyOwner {
		price = _price;
	}

	function pause(bool _paused) public onlyOwner {
		paused = _paused;
	}

	function reveal() public onlyOwner {
		revealed = true;
	}

	function setMaxDogsPerWallet(uint256 _amount) public onlyOwner {
		maxDogsPerWallet = _amount;
	}

	function giftDogs(uint256 _amount, address _receiver) public onlyOwner {
		require(totalSupply + _amount <= maxSupply, "Exceeds max supply");

		for (uint256 i; i < _amount; i++) {
			totalSupply++;
			_safeMint(_receiver, totalSupply);
		}
	} 

	function setBaseURI(string memory newbaseURI) public onlyOwner {
		baseURI = newbaseURI;
	}

	function withdraw() public onlyOwner {
		(bool success, ) = msg.sender.call{value: address(this).balance}("");
		require(success, "Failed to transfer Ether");
	}

	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(_exists(tokenId), "Nonexistent token");

		if(!revealed) {
			return string(abi.encodePacked(notRevealedURI, "/", tokenId.toString(), ".json"));
		}

		return string(abi.encodePacked(baseURI, "/", tokenId.toString(), ".json"));
	}
}