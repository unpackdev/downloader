// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./IERC165.sol";
import "./IERC721.sol";
import "./ENS.sol";
import "./IAddrResolver.sol";
import "./IAddressResolver.sol";

contract ENSNFT is Ownable, IAddrResolver, IAddressResolver {

	function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
		return interfaceId == type(IERC165).interfaceId 
			|| interfaceId == type(IAddrResolver).interfaceId
			|| interfaceId == type(IAddressResolver).interfaceId;
	}

	error AlreadyEnabled();

	ENS constant _ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
	IERC721 public _nft; 
	string public _name;
	bytes32 public _node;
	mapping (bytes32 => uint256) _nodes;

	constructor(string memory name, address nft) {
		_name = name;
		_node = _namehash(name);
		_nft = IERC721(nft);
	}
	function destroy() public onlyOwner {
		selfdestruct(payable(msg.sender));
	}

	function isENSApproved() public view returns (bool) {
		return _ens.isApprovedForAll(_ens.owner(_node), address(this));
	}

	// note: it's impossible to enable token = 0xFF...FF = ~0
	function isEnabled(uint256 token) public view returns (bool) {
		return _isSubnodeSetup(_namehash(nameFromToken(token)));
	}
	function enable(uint256 token) public {
		if (!_setupSubnodeForToken(token)) revert AlreadyEnabled();
	}
	function batchEnable(uint256[] calldata tokens) public {
		 unchecked {
			uint256 any;
			for (uint256 i; i < tokens.length; i++) {
				if (_setupSubnodeForToken(tokens[i])) {
					any = 1;
				}
			}
			if (any == 0) revert AlreadyEnabled();
		}		
	}

	// subnodes
	function _isSubnodeSetup(bytes32 node) private view returns (bool) {
		return _nodes[node] != 0 
			&& _ens.owner(node) == address(this) 
			&& _ens.resolver(node) == address(this);
	}
	function _setupSubnodeForToken(uint256 token) private returns (bool) {
		string memory name = nameFromToken(token);
		bytes32 node = _namehash(name);
		if (_isSubnodeSetup(node)) return false;
		uint256 len = _lengthBase10(token);
		assembly {
			mstore(name, len) // truncate
		}
		_ens.setSubnodeRecord(_node, _labelhash(name, 0, len), address(this), address(this), 0);
		_nodes[node] = ~token;
		return true;
	}
	function _lengthBase10(uint256 token) private pure returns (uint256 len) {
		unchecked {
			len = 1;
			while (token >= 10) {
				token /= 10;
				len++;
			} 
		}
	}
	function nameFromToken(uint256 token) public view returns (string memory) {
		unchecked {
			bytes memory name = bytes(_name);
			uint256 len = _lengthBase10(token) + 1; // "123" + "."
			bytes memory buf = new bytes(len + name.length);
			assembly {
				for {
					let src := name
					let end := add(src, mload(src))
					let dst := add(buf, len)
				} lt(src, end) {} {
					src := add(src, 32)
					dst := add(dst, 32)
					mstore(dst, mload(src))
				}
				mstore(buf, add(len, mload(name)))
			}
			buf[--len] = '.';
			while (len > 0) {
				buf[--len] = bytes1(uint8(48 + (token % 10)));
				token /= 10;
			}
			return string(buf);
		}
	}
	function nodeFromToken(uint256 token) public view returns (bytes32) {
		return _namehash(nameFromToken(token));
	}

	// ens resolver
	function addr(bytes32 node) public view returns (address payable ret) {
		uint256 token = _nodes[node];
		if (token != 0) {
			return payable(_nft.ownerOf(~token));
		}
	}
	function addr(bytes32 node, uint256 coinType) public view returns(bytes memory ret) {
		if (coinType == 60) { // ETH
			return abi.encodePacked(addr(node));
		}
	}

	// ens helpers
	function _namehash(string memory domain) private pure returns (bytes32 node) {
		unchecked {
			uint256 i = bytes(domain).length;
			uint256 e = i;
			node = bytes32(0);
			while (i > 0) {
				if (bytes(domain)[--i] == '.') {
					node = keccak256(abi.encodePacked(node, _labelhash(domain, i + 1, e)));
					e = i;
				}
			}
			node = keccak256(abi.encodePacked(node, _labelhash(domain, i, e)));
		}
	}
	function _labelhash(string memory domain, uint start, uint end) private pure returns (bytes32 hash) {
		assembly ("memory-safe") {
			hash := keccak256(add(add(domain, 0x20), start), sub(end, start))
		}
	}

}