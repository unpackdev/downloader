// SPDX-License-Identifier: AGPL-1.0-only

pragma solidity ^0.8.4;

// Welcome to Supremacy!
//
// Artwork by Herman K. Lau, 1993 from https://www.eyrie.org/~sw/btech/btechasc.htm
// Battletech Madcat
//       ____          ____
//       |oooo|        |oooo|
//       |oooo| .----. |oooo|
//       |Oooo|/\_||_/\|oooO|
//       `----' / __ \ `----'
//       ,/ |#|/\/__\/\|#| \,
//      /  \|#|| |/\| ||#|/  \
//     / \_/|_|| |/\| ||_|\_/ \
//    |_\/    o\=----=/o    \/_|
//    <_>      |=\__/=|      <_>
//    <_>      |------|      <_>
//    | |   ___|======|___   | |
//   //\\  / |O|======|O| \  //\\
//   |  |  | |O+------+O| |  |  |
//   |\/|  \_+/        \+_/  |\/|
//   \__/  _|||        |||_  \__/
//         | ||        || |
//        [==|]        [|==]
//        [===]        [===]
//         >_<          >_<
//        || ||        || ||
//        || ||        || ||
//        || ||        || ||  -JT
//      __|\_/|__    __|\_/|__
//     /___n_n___\  /___n_n___\

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Crypto_SignatureVerifier.sol";

/// @custom:security-contact privacy-admin@supremacy.game
contract NFT is ERC721, SignatureVerifier, Ownable {
	mapping(address => uint256) public nonces;

	string baseURI = "https://nft.supremacy.game/api/metadata/";

	constructor(address signer)
		ERC721("Supremacy NFTs", "SUPNFT")
		SignatureVerifier(signer)
	{}

	function _baseURI() internal view override returns (string memory) {
		return baseURI;
	}

	function devSetBaseURI(string calldata newURI) public onlyOwner {
		baseURI = newURI;
	}

	// devMint mints an NFT
	function devMint(address to, uint256 id) public onlyOwner {
		_safeMint(to, id);
	}

	// devSetSigner updates the signer
	function devSetSigner(address _signer) public onlyOwner {
		setSigner(_signer);
	}

	// devBatchMint mints multiple NFTs
	function devBatchMint(
		address to,
		uint256 fromID,
		uint256 amount
	) public onlyOwner {
		for (uint256 id = fromID; id < fromID + amount; id++) {
			_safeMint(to, id);
		}
	}

	// signedMint mints an NFT to msg.sender if signature is valid
	function signedMint(uint256 tokenID, bytes calldata signature) public {
		bytes32 messageHash = getMessageHash(
			msg.sender,
			tokenID,
			nonces[msg.sender]++
		);

		require(verify(messageHash, signature), "Invalid Signature");
		_safeMint(msg.sender, tokenID);
	}

	// getMessageHash builds the hash for signature verification
	function getMessageHash(
		address account,
		uint256 tokenID,
		uint256 nonce
	) internal pure returns (bytes32) {
		return keccak256(abi.encode(account, tokenID, nonce));
	}
}
