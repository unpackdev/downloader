// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Proxy.sol";
import "./FEWLootStorage.sol";

contract FEWLootProxy is FEWLootStorage, Proxy {
	event MainContractUpdated(address indexed _oldContract, address indexed _newContract);

	constructor(address _contract, address _newSigner) {
		_baseTokenURI = "https://data.forgottenethereal.world/loot/metadata/";
		_mainContract = _contract;
		_signer = _newSigner;
	}

	function _implementation() internal view override returns (address) {
		return _mainContract;
	}

	// Needed so etherscan can verify the contract as a proxy
	function proxyType() external pure returns (uint256) {
		return 2;
	}

	// Needed so etherscan can verify the contract as a proxy
	function implementation() external view returns (address) {
		return _implementation();
	}

	function setMainContract(address _newContract) public onlyOwner {
		address _oldContract = _newContract;
		_mainContract = _newContract;

		emit MainContractUpdated(_oldContract, _newContract);
	}

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

	function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}
