// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./ClonesUpgradeable.sol";
import "./IERC721.sol";
import "./IHandler.sol";
import "./ERC721Base.sol";

contract Factory is Ownable {
	address immutable impl;
	
	uint minFee = 0.1 ether;
	uint feePercent = 1000; // 10%
	address feeAddress;
  uint constant PERCENT_BASE = 10000;

	event CreateNFT (
		address indexed owner,
		address nft,
		bytes32 salt
	);

	address gyve;
	bool useWhitelist = true;
	mapping (address => bool) whitelist;

	address mustOwn;

	constructor(address _gyve, address _feeAddress, uint _feePercent, uint _minFee) {
		impl = address(new ERC721Base());
		gyve = _gyve;
		minFee = _minFee;
		feePercent = _feePercent;
		feeAddress = _feeAddress;
	}

	function createNFT(bytes32 salt, string memory _desc, string memory _token, uint256 _price, uint256 _maxTotal, uint256 _maxMint) external payable returns(address) {
		require(_price >= minFee);
		require(!useWhitelist || whitelist[msg.sender], '!wl');
		require(mustOwn == address(0) || _owns(mustOwn, msg.sender), '!own');

		address clone = ClonesUpgradeable.cloneDeterministic(impl, salt);
    ERC721Base(clone).initialize(_desc, _token, _price, _maxTotal, _maxMint, feePercent, feeAddress, gyve, mustOwn);
		ERC721Base(clone).transferOwnership(msg.sender);
		IHandler(gyve).allow(clone, true);
		emit CreateNFT(msg.sender, clone, salt);
		return clone;
	}

	function createNFTOwner(bytes32 salt, string memory _desc, string memory _token, uint256 _price, uint256 _maxTotal, uint256 _maxMint) onlyOwner external returns(address) {
		address clone = ClonesUpgradeable.cloneDeterministic(impl, salt);
    ERC721Base(clone).initialize(_desc, _token, _price, _maxTotal, _maxMint, feePercent, feeAddress, gyve, mustOwn);
		ERC721Base(clone).transferOwnership(msg.sender);
		IHandler(gyve).allow(clone, true);
		emit CreateNFT(msg.sender, clone, salt);
		return clone;
	}

	function predictDeterministic(bytes32 salt) external view returns(address) {
		return ClonesUpgradeable.predictDeterministicAddress(impl, salt);
	}

  function _owns(address erc721, address _owner) internal view returns(bool) {
    return IERC721(erc721).balanceOf(_owner) > 0;
  }

	function _sendEth(uint eth) internal {
		if (eth > 0) {
    	(bool success, ) = feeAddress.call{value: eth}("");
    	require(success, '!_send');
		}
  }

	function setFees(address _feeAddress, uint _feePercent, uint _minFee) external onlyOwner {
		minFee = _minFee;
		feeAddress = _feeAddress;
		feePercent = _feePercent;
	}

	function setUseWhitelist(bool _use) external onlyOwner {
		useWhitelist = _use;
	}

	function setWhitelist(address wl, bool allow) external onlyOwner {
		require(wl != address(0), '!wl');
		whitelist[wl] = allow;
	}

	function setGyve(address _gyve) external onlyOwner {
		require(_gyve != address(0), '!gyve');
		gyve = _gyve;
	}

	function setMustOwn(address _erc) external onlyOwner {
		mustOwn = _erc;
	}

}

