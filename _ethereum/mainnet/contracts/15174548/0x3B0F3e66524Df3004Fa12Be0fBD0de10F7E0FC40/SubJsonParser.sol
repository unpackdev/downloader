// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

contract SubJsonParser {

	function generateTokenUriPart1(uint256 _tokenId) public pure returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('data:application/json;utf8,{"name":"'),
				_getName(_tokenId),
				bytes('","description":"'),
				"NFTBox subscription that guarantees the reception of a monthly box until it expires.",
				bytes('","external_url":"'),
				_getExternalUrl()
			)
		);
	}

	function generateTokenUriPart2(uint256 _tier, uint256 _counter, uint256 _start, uint256 _length) public pure returns(string memory) {
		return string(
			abi.encodePacked(
				bytes('","attributes":['),
				_tierSub(_tier),
				_expiry(_counter - _start + _length),
				bytes(',"image":"'),
				_getImageCache(_tier),
				bytes('"}')
			)
		);
	}

	function _getImageCache(uint256 _tier) internal pure returns(string memory) {
		if (_tier == 3)
			return string(abi.encodePacked("https://ipfs.io/ipfs/QmV3GaTzqLvGSRTAuiLQGsBUDDx4Dr7G7gxqtR8eRhudLL"));
		if (_tier == 6)
			return string(abi.encodePacked("https://ipfs.io/ipfs/QmZBtFNpbrstaKwSDzsB3uFGMeN7b5VjT93Udab2EbB2tQ"));
		if (_tier == 9)
			return string(abi.encodePacked("https://ipfs.io/ipfs/QmPCv1DEWH6pTXXVVdR3nqcavT1bzNRY5QoyR6KEzVjUkb"));
		return string(abi.encodePacked(""));
	}

	function _getName(uint256 _tokenId) internal pure returns(string memory) {
		return string(abi.encodePacked("NFTBox Subs #", _uint2str(_tokenId)));
	}

	function _tierSub(uint256 _tier) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "tier","value":"'), _uint2str(_tier), bytes('"},')));
	}

	function _expiry(uint256 _expirationCount) internal pure returns(string memory) {
		return string(abi.encodePacked(bytes('{"trait_type": "box left","value":"'), _uint2str(_expirationCount), bytes('"}]')));
	}

	function _getImageCache(string memory _hash) internal pure returns(string memory) {
		return string(abi.encodePacked("https://ipfs.io/ipfs/", _hash));
	}

	function _getExternalUrl() internal pure returns(string memory) {
		return string(abi.encodePacked("https://www.nftboxes.io/"));
	}

	function _uint2str(uint _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint j = _i;
		uint len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint k = len;
		while (_i != 0) {
			k = k-1;
			uint8 temp = (48 + uint8(_i - _i / 10 * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
}