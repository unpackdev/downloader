// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./IFlightTickets.sol";
import "./Rocks.sol";

contract PublicMint is Ownable {
	address public signerAddress;

	Rocks public rocksContract;
	mapping(address => uint256) public mintedTokensPerWallet;

	modifier callerIsUser() {
		require(tx.origin == msg.sender, "The caller is another contract");
		_;
	}

	uint256 constant ROCK_A = 0;
	uint256 constant ROCK_B = 1;
	uint256 constant ROCK_C = 2;
	uint256 constant ROCK_D = 3;
	uint256 constant ROCK_E = 4;
	uint256 constant ROCK_F = 5;
	uint256 constant ROCK_G = 6;
	uint256 constant ROCK_H = 7;
	uint256 constant ROCK_I = 8;
	uint256 constant ROCK_J = 9;
	uint256 constant ROCK_K = 10;
	uint256 constant ROCK_L = 11;
	uint256 constant ROCK_M = 12;
	uint256 constant ROCK_N = 13;
	uint256 constant ROCK_O = 14;

	uint256 public mintPrice = 0.15 ether;

	uint256[15] public availableRocks;

	/**
	 * @dev Sets the address that generates the signatures for whitelisting
	 */
	function setSignerAddress(address _signerAddress) external onlyOwner {
		signerAddress = _signerAddress;
	}

	/**
	 * @dev Sets the tickets smart contract
	 */
	function setRocksContract(address _rocksContractAddress) external onlyOwner {
		rocksContract = Rocks(_rocksContractAddress);
	}

	/**
	 * @dev Sets the mint price
	 */
	function setMintPrice(uint256 _mintPrice) external onlyOwner {
		mintPrice = _mintPrice;
	}

	/**
	 * @dev Sets the amount of available rocks left to be claimed
	 */
	function setAvailableRocks(uint256[15] memory _availableRocks) external onlyOwner {
		availableRocks = _availableRocks;
	}

	/**
	 * @dev Allows to withdraw the Ether in the contract.
	 */
	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	// END ONLY OWNER

	/**
	 * @dev Mints rocks
	 */
	function mint(
		uint256 _amount,
		uint256 _fromTimestamp,
		uint256 _toTimestamp,
		uint256 _maxMintsPerWallet,
		bytes calldata _signature
	) external payable callerIsUser {
		require(
			ECDSA.recover(
				generateMessageHash(msg.sender, _fromTimestamp, _toTimestamp, _maxMintsPerWallet),
				_signature
			) == signerAddress,
			"Invalid signature for the caller"
		);

		require(_amount > 0, "At least one token should be minted");

		require(block.timestamp >= _fromTimestamp, "Too early to mint");
		require(block.timestamp <= _toTimestamp, "The signature has expired");

		require(mintedTokensPerWallet[msg.sender] + _amount <= _maxMintsPerWallet, "You cannot mint more tokens");

		uint256[15] memory _availableRocks = availableRocks;
		uint256[] memory _rocksToBeMinted = new uint256[](15);

		uint256 _totalAvailableRocks = totalAvailableRocks();

		require(_totalAvailableRocks > 0, "Sold out");
		if (_amount > _totalAvailableRocks) {
			_amount = _totalAvailableRocks;
		}

		uint256 totalMintPrice = mintPrice * _amount;
		require(msg.value >= totalMintPrice, "Not enough Ether to mint the tokens");
		mintedTokensPerWallet[msg.sender] += _amount;

		if (msg.value > totalMintPrice) {
			payable(msg.sender).transfer(msg.value - totalMintPrice);
		}

		for (uint256 i; i < _amount; i++) {
			uint256 _randomRock = _getRandomRock(_totalAvailableRocks);
			_totalAvailableRocks--;
			uint256 _rangeLimit;

			for (uint256 rockToMint; rockToMint < availableRocks.length; rockToMint++) {
				_rangeLimit += availableRocks[rockToMint];
				if (_randomRock < _rangeLimit) {
					availableRocks[rockToMint]--;
					_rocksToBeMinted[rockToMint]++;

					break;
				}
			}
		}

		availableRocks = _availableRocks;

		uint256[] memory _rockTypes = new uint256[](_rocksToBeMinted.length);
		uint256[] memory _rockAmounts = new uint256[](_rocksToBeMinted.length);

		uint256 index;
		for (uint256 i; i < _rocksToBeMinted.length; i++) {
			if (_rocksToBeMinted[i] > 0) {
				_rockTypes[index] = i;
				_rockAmounts[index] = _rocksToBeMinted[i];
				index++;
			}
		}

		rocksContract.mint(msg.sender, _rockTypes, _rockAmounts);
	}

	/**
	 * @dev Returns the amount of rocks left to be minted
	 */
	function totalAvailableRocks() public view returns (uint256) {
		uint256 _availableRocks;

		for (uint256 i; i < availableRocks.length; i++) {
			_availableRocks += availableRocks[i];
		}

		return _availableRocks;
	}

	/**
	 * @dev Generates the message hash for the given parameters
	 */
	function generateMessageHash(
		address _minter,
		uint256 _fromTimestamp,
		uint256 _toTimestamp,
		uint256 _maxMintsPerWallet
	) internal pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					"\x19Ethereum Signed Message:\n116",
					_minter,
					_fromTimestamp,
					_toTimestamp,
					_maxMintsPerWallet
				)
			);
	}

	/**
	 * @dev Generates a pseudo-random number.
	 */
	function _getRandomRock(uint256 _upper) private view returns (uint256) {
		uint256 random = uint256(
			keccak256(
				abi.encodePacked(_upper, blockhash(block.number - 1), block.coinbase, block.difficulty, msg.sender)
			)
		);

		return random % _upper;
	}
}
