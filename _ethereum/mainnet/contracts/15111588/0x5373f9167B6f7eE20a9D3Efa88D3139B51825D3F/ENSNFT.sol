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

    ENS _ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
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

    function isEnabled(uint256 token) public view returns (bool) {
        return _nodes[_namehash(getName(token))] != 0;
    }
    function _enable(uint256 token) private returns (bool) {
        string memory name = getName(token);
        bytes32 node = _namehash(name);
        if (_nodes[node] != 0) return false;
        uint256 len = _lengthBase10(token);
        assembly {
            mstore(name, len) // truncate
        }
        _ens.setSubnodeRecord(_node, _labelhash(name, 0, len), address(this), address(this), 0);
        _nodes[node] = token;
        return true;
    }

    function enable(uint256 token) public {
        if (!_enable(token)) revert AlreadyEnabled();
    }
    function batchEnable(uint256 token, uint256 tokenLast) public {
        uint256 any;
        while (token <= tokenLast) {
            if (_enable(token++)) {
                any = 1;
            }
        }
        if (any == 0) revert AlreadyEnabled();
    }

    // token -> name
    function _lengthBase10(uint256 token) private pure returns (uint256 len) {
        len = 1;
        while (token >= 10) {
            token /= 10;
            len++;
        } 
    }
    function getName(uint256 token) public view returns (string memory) {
        bytes memory name = bytes(_name);
        uint256 len = 1 + _lengthBase10(token);        
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

    // ens
    function addr(bytes32 node) public view returns (address payable ret) {
        uint256 token = _nodes[node];
        if (token != 0) {                
            return payable(_nft.ownerOf(token));
        }
    }
    function addr(bytes32 node, uint256 coinType) public view returns(bytes memory ret) {
        if (coinType == 60) {
            return abi.encodePacked(addr(node));
        }
    }

    // ens helpers
    function _namehash(string memory domain) private pure returns (bytes32 node) {
		uint256 i = bytes(domain).length;
		uint256 n = i;
		node = bytes32(0);
		for (; i > 0; i--) {
			if (bytes(domain)[i-1] == '.') {
				node = keccak256(abi.encodePacked(node, _labelhash(domain, i, n)));
				n = i - 1;
			}
		}
		node = keccak256(abi.encodePacked(node, _labelhash(domain, i, n)));
	}
	function _labelhash(string memory domain, uint start, uint end) private pure returns (bytes32 hash) {
		assembly ("memory-safe") {
			hash := keccak256(add(add(domain, 0x20), start), sub(end, start))
		}
	}

}