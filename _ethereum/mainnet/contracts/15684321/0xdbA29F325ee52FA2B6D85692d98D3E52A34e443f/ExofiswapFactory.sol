// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";
import "./Ownable.sol";
import "./IExofiswapFactory.sol";
import "./IExofiswapPair.sol";
import "./ExofiswapPair.sol";

contract ExofiswapFactory is IExofiswapFactory, Ownable
{
	address private _feeTo;
	IMigrator private _migrator;
	mapping(IERC20Metadata => mapping(IERC20Metadata => IExofiswapPair)) private _getPair;
	IExofiswapPair[] private _allPairs;

	constructor()
	{} // solhint-disable-line no-empty-blocks

	function createPair(IERC20Metadata tokenA, IERC20Metadata tokenB) override public returns (IExofiswapPair)
	{
		require(tokenA != tokenB, "EF: IDENTICAL_ADDRESSES");
		(IERC20Metadata token0, IERC20Metadata token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(address(token0) != address(0), "EF: ZERO_ADDRESS");
		require(address(_getPair[token0][token1]) == address(0), "EF: PAIR_EXISTS"); // single check is sufficient

		bytes32 salt = keccak256(abi.encodePacked(token0, token1));
		IExofiswapPair pair = new ExofiswapPair{salt: salt}(); // Use create2
		pair.initialize(token0, token1);

		_getPair[token0][token1] = pair;
		_getPair[token1][token0] = pair; // populate mapping in the reverse direction
		_allPairs.push(pair);
		emit PairCreated(token0, token1, pair, _allPairs.length);
		return pair;
	}

	function setFeeTo(address newFeeTo) override public onlyOwner
	{
		_feeTo = newFeeTo;
	}

	function setMigrator(IMigrator newMigrator) override public onlyOwner
	{
		_migrator = newMigrator;
	}

	function allPairs(uint256 index) override public view returns (IExofiswapPair)
	{
		return _allPairs[index];
	}

	function allPairsLength() override public view returns (uint256)
	{
		return _allPairs.length;
	}

	function feeTo() override public view returns (address)
	{
		return _feeTo;
	}

	function getPair(IERC20Metadata tokenA, IERC20Metadata tokenB) override public view returns (IExofiswapPair)
	{
		return _getPair[tokenA][tokenB];
	}

	function migrator() override public view returns (IMigrator)
	{
		return _migrator;
	}

	function pairCodeHash() override public pure returns (bytes32)
	{
		return keccak256(type(ExofiswapPair).creationCode);
	}
}
