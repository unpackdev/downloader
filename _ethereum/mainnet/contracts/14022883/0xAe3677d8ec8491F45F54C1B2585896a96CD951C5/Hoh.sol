// SPDX-License-Identifier: MIT
// HOH
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Base64.sol";

contract Hoh is ERC721, Ownable {
	bool public claimIsActive = false;
	uint256 public maxSupply = 8888;

	mapping(address => uint256) public addressClaimed;

	using Counters for Counters.Counter;
	Counters.Counter private _tokenId;

	constructor() ERC721("HOH", "HOH") {}

	function getTotalSupply() public view returns (uint256 supply) {
		return _tokenId.current();
	}

	function setClaimState(bool newState) public onlyOwner {
		claimIsActive = newState;
	}

	function claim() external {
		require(claimIsActive, "Claim is not active.");
		require(_tokenId.current() + 1 <= maxSupply, "Out of supply.");
		require(addressClaimed[msg.sender] < 1, "Max one per wallet.");
		addressClaimed[msg.sender] += 1;
		_tokenId.increment();
		_safeMint(msg.sender, _tokenId.current());
	}

	function tokenURI(uint256 tokenId)
		public
		view
		override
		returns (string memory)
	{
		string memory image = string(
			abi.encodePacked(
				'<svg width="128" height="128" xmlns="http://www.w3.org/2000/svg"><g><rect width="100%" height="100%" rx="5px" fill="#CC232A" /><text transform="matrix(1 0 0 1 0 0)" font-weight="normal" xml:space="preserve" text-anchor="start" font-family="Verdana" font-size="38" id="svg_2" y="78" x="20" stroke-width="0" stroke="#000" fill="#ffffff">HOH</text></g></svg>'
			)
		);
		string memory imageOutput = string(abi.encodePacked(image));
		string memory json = Base64.encode(
			bytes(
				string(
					abi.encodePacked(
						'{"name": "HOH #',
						Strings.toString(tokenId),
						'","attributes": [ { "trait_type": "HOH ',
						'", "value": "',
						"True",
						'" }]',
						', "description": "Heng Ong Huat, HOH ',
						" - ",
						Strings.toString(tokenId),
						"/",
						Strings.toString(maxSupply),
						'", "image": "data:image/svg+xml;base64,',
						Base64.encode(bytes(imageOutput)),
						'"}'
					)
				)
			)
		);
		string memory jsonOutput = string(
			abi.encodePacked("data:application/json;base64,", json)
		);

		return jsonOutput;
	}
}
