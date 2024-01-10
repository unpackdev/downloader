// SPDX-License-Identifier: UNLICENSED
// AmiAvatar.com
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";

contract AmiAvatarToken is ERC721, Ownable {
	uint public _price = 0.005 ether;
	uint public _lastId = 250;
	uint _currentId = 87;

	string private constant BAD_QTY = "BadQty";
	string private constant LOW_ETH = "LowEth";
	string private constant NO_STOCK = "NoStock";
	string private constant BASE_URL = "ipfs://QmeHDgnUKi8LM29x5UGnFTvbxaaWpqa3xCy1FuXeFHvvad/";

	constructor() ERC721("Ami Avatar", "AMI") {
	}

	function _baseURI() internal pure override returns (string memory) {
		return BASE_URL;
	}

	function setPrice(uint newPrice) public onlyOwner {
		_price = newPrice;
	}

	function setCurrentId(uint newCurrent) public onlyOwner {
		_currentId = newCurrent;
	}

	function setLastId(uint newLast) public onlyOwner {
		_lastId = newLast;
	}

	function ownerMint(uint id, address recipient) public onlyOwner {
		_safeMint(recipient, id);
	}

	function mintNFTBulk(uint qty) public payable {
		require(qty > 0 && qty <= 10, BAD_QTY);
		require(msg.value >= (_price * qty), LOW_ETH);
		require(_currentId + qty - 1 <= _lastId, NO_STOCK);
		for (uint i=0; i<qty; i++) {
			_safeMint(msg.sender, _currentId++);
		}
	}

	function totalSupply() public view returns (uint) {
		return _currentId - 1;
	}

	function withdraw() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}
}
