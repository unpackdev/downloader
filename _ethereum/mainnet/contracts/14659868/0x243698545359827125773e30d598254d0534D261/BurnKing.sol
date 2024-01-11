// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721AOptimized.sol";
import "./IERC20Burnable.sol";

contract BurnKing is ERC721AOptimized, Ownable {
	address public publicKey;

	uint256 maxSupply = 10000;

	// Mapping from owner to list of owned token IDs
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

	event BurnedEther(address indexed user, uint256 indexed amount, uint256 indexed totalMinted);

	event tokenMintedFor(address mintedFor, uint256 tokenId);

	constructor(address _publicKey) ERC721AOptimized('Burn King', 'BK') {
		publicKey = _publicKey;
	}

	function burnEther(
		bytes calldata _signature,
		uint256 _tokenCount,
		uint256 _expiredDateInSeconds,
		uint256 _usdCost
	) external payable {
		// Burn delay is now calculated on backend
		require(_expiredDateInSeconds >= block.timestamp, 'Transaction expired');
		require(msg.value >= _tokenCount, 'You do not have enough ethers');

		checkParamsVerification(_signature, concatParamsEth(_tokenCount, _expiredDateInSeconds, _usdCost));

		(bool sent, ) = address(0).call{value: _tokenCount}('');
		require(sent, 'Failed to burn Tokens');

		if (_usdCost >= 10) {
			mint();
		}

		emit BurnedEther(msg.sender, _usdCost, _totalMinted());
	}

	function burnERC20(
		bytes calldata _signature,
		uint256 _tokenCount,
		uint256 _expiredDateInSeconds,
		uint256 _usdCost,
		address _tokenContractAddress
	) external {
		require(_expiredDateInSeconds >= block.timestamp, 'Transaction expired');

		checkParamsVerification(
			_signature,
			concatParamsERC(_tokenCount, _expiredDateInSeconds, _usdCost, _tokenContractAddress)
		);

		IERC20Burnable(_tokenContractAddress).transferFrom(msg.sender, address(this), _tokenCount);
		IERC20Burnable(_tokenContractAddress).burn(_tokenCount);

		if (_usdCost >= 10) {
			mint();
		}

		emit BurnedEther(msg.sender, _usdCost, _totalMinted());
	}

	function mint() internal {
		require(_totalMinted() + 1 <= maxSupply, 'No more available NFTs');

		_ownedTokens[msg.sender][balanceOf(msg.sender)] = _currentIndex;
		_mint(msg.sender, 1, '', true);

		emit tokenMintedFor(msg.sender, _currentIndex - 1);
	}

	function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
		require(index < balanceOf(owner), 'Owner index out of bounds');
		return _ownedTokens[owner][index];
	}

	function _baseURI() internal pure override returns (string memory) {
		return 'https://burnking.io/api/meta/';
	}

	function checkParamsVerification(bytes memory _signature, string memory _concatenatedParams) public view {
		(bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
		require(verifyMessage(_concatenatedParams, v, r, s) == publicKey, 'Your signature is not valid');
	}

	function splitSignature(bytes memory _signature)
		public
		pure
		returns (
			bytes32 r,
			bytes32 s,
			uint8 v
		)
	{
		require(_signature.length == 65, 'invalid signature length');
		assembly {
			r := mload(add(_signature, 32))
			s := mload(add(_signature, 64))
			v := byte(0, mload(add(_signature, 96)))
		}
	}

	function verifyMessage(
		string memory _concatenatedParams,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
	) public pure returns (address) {
		return
			ecrecover(
				keccak256(
					abi.encodePacked(
						'\x19Ethereum Signed Message:\n',
						Strings.toString(bytes(_concatenatedParams).length),
						_concatenatedParams
					)
				),
				_v,
				_r,
				_s
			);
	}

	function concatParamsEth(
		uint256 _tokenCount,
		uint256 _timestamp,
		uint256 _usdCost
	) public pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					Strings.toString(_tokenCount),
					Strings.toString(_timestamp),
					Strings.toString(_usdCost)
				)
			);
	}

	function concatParamsERC(
		uint256 _tokenCount,
		uint256 _timestamp,
		uint256 _usdCost,
		address _contractAddress
	) public pure returns (string memory) {
		return
			string(
				abi.encodePacked(
					Strings.toString(_tokenCount),
					Strings.toString(_timestamp),
					Strings.toString(_usdCost),
					_addressToString(_contractAddress)
				)
			);
	}

	function _addressToString(address _addr) internal pure returns (string memory) {
		bytes memory addressBytes = abi.encodePacked(_addr);

		bytes memory stringBytes = new bytes(42);

		stringBytes[0] = '0';
		stringBytes[1] = 'x';

		for (uint256 i = 0; i < 20; i++) {
			uint8 leftValue = uint8(addressBytes[i]) / 16;
			uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

			bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
			bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

			stringBytes[2 * i + 3] = rightChar;
			stringBytes[2 * i + 2] = leftChar;
		}

		return string(stringBytes);
	}
}
