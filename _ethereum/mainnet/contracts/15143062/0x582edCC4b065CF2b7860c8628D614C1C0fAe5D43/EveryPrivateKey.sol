//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./Strings.sol";
import "./ERC721.sol";
import "./Secp256k1.sol";


contract EveryPrivateKey is ERC721, Secp256k1 {
	using Strings for uint256;
	using Strings for address;

	constructor()
		ERC721('Every Private Key', 'PRIVATEKEY')
	{}

	/**
	 * Public functions
	 **/

	function toPublicKey(uint _tokenId) public pure returns (bytes memory) {
		(uint x, uint y) = derivePubKey(_tokenId);

		return abi.encodePacked(
			//uint8(4),
			x,
			y
		);
	}

	function toPublicAddress(uint _tokenId) public pure returns (address) {
		return address(bytes20(keccak256(toPublicKey(_tokenId)) << (256-160)));
	}

	function getBalanceString(uint256 _balance) public pure returns (string memory) {
		uint256 decimals = ((_balance * 1000) / 1 ether) % 1000;

		string memory decimalsStr;
		if (decimals >= 100) {
			decimalsStr = decimals.toString();
		} else if (decimals >= 10) {
			decimalsStr = string(abi.encodePacked('0', decimals.toString()));
		} else if (decimals >= 1) {
			decimalsStr = string(abi.encodePacked('00', decimals.toString()));
		} else {
			decimalsStr = '000';
		}

		return string(
			abi.encodePacked(
				(_balance / 1 ether).toString(),
				'.',
				decimalsStr
			)
		);
	}

	function tokenURI(
		uint256 _tokenId
	)
		public
		view
		virtual
		override
	returns (
		string memory
	) {
		// Get the public address from the private key
		string memory privateKey = _tokenId.toHexString();
		address publicAddress = toPublicAddress(_tokenId);

		return string(
			abi.encodePacked(
				abi.encodePacked(
					bytes('data:application/json;utf8,{"name":"PK = '),
					privateKey,
					bytes('","description":"The private key '),
					privateKey,
					bytes(' produces the Ethereum public address: '),
					publicAddress.toHexString()
				),
				abi.encodePacked(
					bytes('.","image_data":"'),
					getImageSvg(privateKey, publicAddress.toHexString()),
					bytes('","attributes":[{"trait_type": "Public Address", "value": "'),
					publicAddress.toHexString(),
					bytes('"},{"trait_type": "ETH Balance", "value": '),
					getBalanceString(payable(publicAddress).balance),
					bytes('}]}')
				)
			)
		);
	}

	function getImageSvg(
		string memory privateKey,
		string memory publicAddress
	)
		public
		view
	returns (
		bytes memory
	) {
		return abi.encodePacked(
			bytes('<?xml version=\\"1.0\\" encoding=\\"UTF-8\\"?><svg width=\\"330px\\" height=\\"330px\\" viewBox=\\"0 0 330 330\\" version=\\"1.1\\" xmlns=\\"http://www.w3.org/2000/svg\\" xmlns:xlink=\\"http://www.w3.org/1999/xlink\\"><title>test</title><g id=\\"Page-1\\" stroke=\\"none\\" stroke-width=\\"1\\" fill=\\"none\\" fill-rule=\\"evenodd\\"><g id=\\"test\\" transform=\\"translate(0.600000, 0.400000)\\"><path d=\\"M164.5,10 C79.3,10 10,79.3 10,164.4 C10,249.6 79.3,318.9 164.5,318.9 C249.6,318.9 318.9,249.6 318.9,164.4 C318.9,79.3 249.6,10 164.5,10 Z\\" id=\\"Path-Copy-6\\" stroke=\\"#979797\\" fill=\\"#DADADA\\" fill-rule=\\"nonzero\\"></path><path d=\\"M164.5,10 C79.3,10 10,79.3 10,164.4 C10,249.6 79.3,318.9 164.5,318.9 C249.6,318.9 318.9,249.6 318.9,164.4 C318.9,79.3 249.6,10 164.5,10 Z M164.5,328.9 C73.8,328.9 0,255.1 0,164.4 C0,73.8 73.8,0 164.5,0 C255.2,0 328.9,73.8 328.9,164.4 C328.9,255.1 255.2,328.9 164.5,328.9 L164.5,328.9 Z\\" id=\\"Fill-136\\" fill=\\"#6E6E6E\\" fill-rule=\\"nonzero\\"></path><path d=\\"M164.5,23.5 C86.8,23.5 23.5,86.7 23.5,164.4 C23.5,242.2 86.8,305.4 164.5,305.4 C242.2,305.4 305.4,242.2 305.4,164.4 C305.4,86.7 242.2,23.5 164.5,23.5 Z M164.5,312.4 C82.9,312.4 16.5,246 16.5,164.4 C16.5,82.9 82.9,16.5 164.5,16.5 C246.1,16.5 312.4,82.9 312.4,164.4 C312.4,246 246.1,312.4 164.5,312.4 L164.5,312.4 Z\\" id=\\"Fill-137\\" fill=\\"#6E6E6E\\" fill-rule=\\"nonzero\\"></path><text id=\\"Private-Key:-0xac097\\" font-family=\\"CourierNewPSMT, Courier New\\" font-size=\\"12\\" font-weight=\\"normal\\" fill=\\"#000000\\"><tspan x=\\"121.192969\\" y=\\"143.6\\">Private Key:</tspan><tspan x=\\"25.7774414\\" y=\\"157.6\\" font-size=\\"7\\">'),
			privateKey,
			bytes('</tspan><tspan x=\\"164.4\\" y=\\"165.6\\"></tspan><tspan x=\\"110.391211\\" y=\\"179.6\\">Public Address:</tspan><tspan x=\\"38.3794922\\" y=\\"193.6\\" font-size=\\"10\\">'),
			publicAddress,
			bytes('</tspan></text></g></g></svg>')
		);
	}


	/**
	 * @dev do not accept value sent directly to contract
	 */
	receive()
		external
		payable
	{
		revert();
	}

	function totalSupply() public view returns(uint256) {
		return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
	}

	function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
		// If the spender of this token is the public address of the tokenId == private key, then allow transfer
		if (toPublicAddress(tokenId) == spender) {
			return true;
		}

        return super._isApprovedOrOwner(spender, tokenId);
    }
}
