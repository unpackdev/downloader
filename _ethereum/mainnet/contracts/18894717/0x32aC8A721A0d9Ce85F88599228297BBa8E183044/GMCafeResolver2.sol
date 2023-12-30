/// @author raffy.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Ownable.sol";
import "./IERC165.sol";
import "./ECDSA.sol";
import "./ENS.sol";
import "./IExtendedResolver.sol";
import "./IAddressResolver.sol";
import "./IAddrResolver.sol";

contract GMCafeResolver2 is Ownable, IERC165, IExtendedResolver, IAddressResolver, IAddrResolver {

	function supportsInterface(bytes4 x) external pure returns (bool) {
		return x == type(IERC165).interfaceId           // 0x01ffc9a7 
		    || x == type(IExtendedResolver).interfaceId // 0x9061b923
            || x == type(IAddressResolver).interfaceId  // 0xf1cb7e06
            || x == type(IAddrResolver).interfaceId;    // 0x3b3b57de
	}

    address constant ENS_REGISTRY = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    uint256 constant COIN_TYPE_ETH = 60;

	string public ccipURL = "https://api.gmcafe.io/ccip";
	address public ccipSigner = 0x33333A1416A4c2D1a982948C0Bbd8f01aAAb080F;
  
    function addr(bytes32 node, uint256 coinType) external view returns (bytes memory v) {
        if (coinType == COIN_TYPE_ETH) {
            v = abi.encodePacked(_getAddress(node));
        }
    }
    function addr(bytes32 node) external view returns (address payable) {
        return payable(_getAddress(node));
    }
    function _getAddress(bytes32 node) internal view returns (address) {
        return ENS(ENS_REGISTRY).owner(node);
    }

	function setURL(string calldata url) onlyOwner external {
		ccipURL = url;
	}  
	function setSigner(address signer) onlyOwner external {
		ccipSigner = signer;
	}

	error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);
	function resolve(bytes calldata name, bytes calldata data) external view returns (bytes memory) {
		bytes memory encoded = abi.encodeWithSelector(IExtendedResolver.resolve.selector, name, data);
		string[] memory urls = new string[](1); 
		urls[0] = ccipURL;
		revert OffchainLookup(address(this), urls, encoded, this.resolveCallback.selector, encoded);
	} 
    function resolveCallback(bytes calldata response, bytes calldata extraData) external view returns(bytes memory) {
        (bytes memory result, uint64 expires, bytes memory sig) = abi.decode(response, (bytes, uint64, bytes));
        require(expires > block.timestamp, "expired");
        bytes32 hash = keccak256(abi.encodePacked(address(this), expires, keccak256(extraData), keccak256(result)));
        address signer = ECDSA.recover(hash, sig);
        require(signer == ccipSigner, "untrusted");
        return result;
    }

}