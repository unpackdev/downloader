// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "./IERC721.sol";

import "./ERC1155NSBase.sol";
import "./ERC1155NSBaseStorage.sol";

import "./OpenSeaProxyRegistry.sol";
import "./OpenSeaProxyStorage.sol";

import "./LandTypes.sol";
import "./LandStorage.sol";

abstract contract LandInternal is ERC1155NSBase {
	modifier claimActive() {
		MintState state = MintState(LandStorage.layout().mintState);
		require(
			state == MintState.CLAIM || state == MintState.PRESALE || state == MintState.PUBLIC,
			"claimActive: not active"
		);
		_;
	}

	modifier mintActive() {
		MintState state = MintState(LandStorage.layout().mintState);
		require(state == MintState.PRESALE || state == MintState.PUBLIC, "mintActive: not active");
		_;
	}

	modifier onlyEOA() {
		// solhint-disable-next-line avoid-tx-origin
		require(tx.origin == msg.sender, "onlyEOA: caller is contract");
		_;
	}

	function _isApprovedForAll(address _owner, address operator) public view returns (bool) {
		address proxy1155 = OpenSeaProxyStorage.layout().os1155Proxy;
		if (LibOpenSeaProxy._isApprovedForAll(proxy1155, _owner, operator)) {
			return true;
		}

		address proxy721 = OpenSeaProxyStorage.layout().os721Proxy;
		if (LibOpenSeaProxy._isApprovedForAll(proxy721, _owner, operator)) {
			return true;
		}

		if (LandStorage.layout().proxies[operator]) {
			return true;
		}
		return super.isApprovedForAll(_owner, operator);
	}

	function _claimInternal(uint256[] memory tokenIds) internal {
		address avatars = LandStorage.layout().avatars;

		for (uint256 index = 0; index < tokenIds.length; index++) {
			uint256 tokenId = tokenIds[index];
			if (LandStorage._getClaimedAvatar(tokenId) != address(0)) {
				revert("claim: already claimed");
			}
			require(IERC721(avatars).ownerOf(tokenId) == _msgSender(), "claim: sender doesnt own");
			LandStorage._setClaimedAvatar(tokenId, _msgSender());
		}

		_mintZone(uint16(tokenIds.length), LandStorage.layout().avatarClaim);
		LandStorage._addClaimCount(uint16(tokenIds.length));
	}

	function _mintInternal(MintRequest memory request) internal {
		_mintInternal(request.zoneId, request.count);
	}

	function _mintInternal(uint16 zoneId, uint16 count) internal {
		require(zoneId > 0, "canMint: cannot mint claim");
		Zone storage zone = LandStorage._getZone(zoneId);

		_mintZone(count, zone);

		LandStorage._addCount(zone, count);
	}

	function _mintManyInternal(MintManyRequest memory request) internal {
		for (uint8 i = 0; i < request.count.length; i++) {
			uint16 zoneId = i + 1;
			if (request.count[i] > 0) {
				_mintInternal(zoneId, request.count[i]);
			}
		}
	}

	function _mintZone(uint16 requested, Zone memory zone) internal {
		require(requested > 0, "invalid amount");
		require(zone.count + requested <= zone.max, "_mintZone: sold out");

		uint64 start = zone.startIndex + zone.count;
		uint64 end = start + requested;

		_mintAsERC721(start, end);
	}

	function _mintAsERC721(uint64 start, uint64 end) internal {
		unchecked {
			uint256 onlyOne = 1;
			for (start; start < end; ) {
				_unsafeMint(_msgSender(), _msgSender(), start, onlyOne);
				start++;
			}
		}
	}

	function _hashClaim(ClaimRequest memory request) internal pure returns (bytes32) {
		return
			ECDSA.toEthSignedMessageHash(
				keccak256(abi.encodePacked(request.to, request.deadline, request.tokenIds))
			);
	}

	function _hashMint(MintRequest memory request) internal pure returns (bytes32) {
		return
			ECDSA.toEthSignedMessageHash(
				keccak256(abi.encodePacked(request.to, request.deadline, request.zoneId, request.count))
			);
	}

	function _hashMintMany(MintManyRequest memory request) internal pure returns (bytes32) {
		return
			ECDSA.toEthSignedMessageHash(
				keccak256(abi.encodePacked(request.to, request.deadline, request.count))
			);
	}

	function _verify(bytes32 digest, bytes memory signature) internal view returns (bool) {
		return LandStorage.layout().signer == ECDSA.recover(digest, signature);
	}
}
