// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./ERC721.sol";
import "./NonBlockingReceiver.sol";
import "./ILayerZeroEndpoint.sol";

contract ComelyTurtles is Ownable, ERC721, NonblockingReceiver {
	string public baseTokenURI;

	uint256 private nextTokenId;
	uint256 private maxMint;

	uint256 private gasForDestinationLzReceive = 350000;

	constructor(
		string memory _baseTokenURI,
		address _layerZeroEndpoint,
		uint256 _startToken,
		uint256 _maxMint
	) ERC721("comely turtles", "turtle") {
		setBaseURI(_baseTokenURI);
		endpoint = ILayerZeroEndpoint(_layerZeroEndpoint);

		nextTokenId = _startToken;
		maxMint = _maxMint;
	}

	function spawn(uint8 numTokens) external payable {
		require(numTokens > 0 && numTokens <= 2, "Max 2 NFTs per transaction");
		require(nextTokenId + numTokens <= maxMint, "Max limit reached");

		for (uint8 i = 0; i < numTokens; i++) {
			_safeMint(msg.sender, ++nextTokenId);
		}
	}

	function traverseChains(uint16 _chainId, uint256 tokenId) public payable {
		require(msg.sender == ownerOf(tokenId), "You must own the token to traverse");
		require(
			trustedSourceLookup[_chainId].length > 0,
			"This chain is currently unavailable for travel"
		);

		// burn NFT, eliminating it from circulation on src chain
		_burn(tokenId);

		// abi.encode() the payload with the values to send
		bytes memory payload = abi.encode(msg.sender, tokenId);

		// encode adapterParams to specify more gas for the destination
		uint16 version = 1;
		bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);

		// get the fees we need to pay to LayerZero + Relayer to cover message delivery
		// you will be refunded for extra gas paid
		(uint256 messageFee, ) = endpoint.estimateFees(
			_chainId,
			address(this),
			payload,
			false,
			adapterParams
		);

		require(
			msg.value >= messageFee,
			"comely turtles: msg.value not enough to cover messageFee. Send gas for message fees"
		);

		endpoint.send{ value: msg.value }(
			_chainId, // destination chainId
			trustedSourceLookup[_chainId], // destination address of nft contract
			payload, // abi.encoded()'ed bytes
			payable(msg.sender), // refund address
			address(0x0), // 'zroPaymentAddress' unused for this
			adapterParams // txParameters
		);
	}

	function setBaseURI(string memory _baseTokenURI) public onlyOwner {
		baseTokenURI = _baseTokenURI;
	}

	function setGasForDestinationLzReceive(uint256 newVal) external onlyOwner {
		gasForDestinationLzReceive = newVal;
	}

	function _LzReceive(
		uint16 _srcChainId,
		bytes memory _srcAddress,
		uint64 _nonce,
		bytes memory _payload
	) internal override {
		(address toAddr, uint256 tokenId) = abi.decode(_payload, (address, uint256));
		_safeMint(toAddr, tokenId);
	}

	function _baseURI() internal view override returns (string memory) {
		return baseTokenURI;
	}
}
