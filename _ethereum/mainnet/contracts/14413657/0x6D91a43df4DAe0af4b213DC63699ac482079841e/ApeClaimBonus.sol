// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "Ownable.sol";
import "IERC721Enumerable.sol";
import "IERC20.sol";

interface IGrape {
	function claimTokens() external;
	function alphaClaimed(uint256) external view returns(bool);
	function betaClaimed(uint256) external view returns(bool);
	function gammaClaimed(uint256) external view returns(bool);
}

contract ApeClaimBonus is Ownable {

	IGrape public constant GRAPE = IGrape(0x025C6da5BD0e6A5dd1350fda9e3B6a614B205a1F);
	IERC20 public constant APE = IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381);
	IERC721Enumerable public constant ALPHA = IERC721Enumerable(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
	IERC721Enumerable public constant BETA = IERC721Enumerable(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
	IERC721Enumerable public constant GAMMA = IERC721Enumerable(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623);

	address public manager;

	constructor(address _manager) {
		manager = _manager;
		ALPHA.setApprovalForAll(_manager, true);
		BETA.setApprovalForAll(_manager, true);
		GAMMA.setApprovalForAll(_manager, true);
	}

    // In the case a user sends an asset directly to the contract...
	function rescueAsset(address _asset, uint256 _tokenId, address _recipient) external onlyOwner {
		IERC721Enumerable(_asset).transferFrom(address(this), _recipient, _tokenId);
	}

	function claim() external {
		require(msg.sender == manager);
		GRAPE.claimTokens();
		APE.transfer(msg.sender, APE.balanceOf(address(this)));
	}
}