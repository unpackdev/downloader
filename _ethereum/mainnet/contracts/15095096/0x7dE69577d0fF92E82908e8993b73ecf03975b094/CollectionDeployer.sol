//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ICollectionDeployer.sol";
import "./XNFT.sol";

contract CollectionDeployer is ICollectionDeployer {
	function deploy(
		string memory name_,
		string memory symbol_,
		address _creator,
		address _addressesStorage
	) external override returns (address) {
		XNFT newCollection = new XNFT(name_, symbol_, _creator, _addressesStorage);
		return address(newCollection);
	}
}
