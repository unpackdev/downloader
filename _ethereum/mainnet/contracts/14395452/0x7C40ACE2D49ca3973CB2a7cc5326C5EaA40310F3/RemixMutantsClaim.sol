// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

contract RemixMutantsClaim is Pausable, Ownable, ReentrancyGuard {

  address public immutable MUTANTS_CONTRACT_ADDRESS;
  address public apedTokenAddress;
  uint256 public maxApedTokensPerToken;

  mapping(uint256 => uint256) internal apedTokensClaimedByToken;

  /* Constructor */
  constructor(address _mutantsContractAddress, address _apeDaoContract) {
    pause(); // Start with claim paused

    MUTANTS_CONTRACT_ADDRESS = _mutantsContractAddress;
    apedTokenAddress = _apeDaoContract;

    maxApedTokensPerToken =  100000000000000000000;
  }

  /* Public functions */
  function claimApedTokens(uint256[] memory _tokenIds) public nonReentrant whenNotPaused {
    require(_tokenIds.length <= 20, "Can only claim 20 per tx");

    uint256 totalClaimable = 0;
    for (uint8 i = 0; i < _tokenIds.length; i++) {
      require(_isApprovedOrOwner(_msgSender(), _tokenIds[i]), "Token not approved");

      uint256 amount = getClaimableApedTokens(_tokenIds[i]);
      totalClaimable += amount;
      apedTokensClaimedByToken[_tokenIds[i]] += amount;
    }

    require(totalClaimable > 0, "Nothing to claim");
    IERC20(apedTokenAddress).transfer(_msgSender(), totalClaimable); // Assumes enough APED in the contract
  }

  function getClaimableApedTokens(uint256 _tokenId) public view returns (uint256) {
    return max(maxApedTokensPerToken - apedTokensClaimedByToken[_tokenId], 0);
  }

  /* Admin */
  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function withdraw() public onlyOwner {
    Address.sendValue(payable(_msgSender()), address(this).balance);
  }

  function withdrawTokens(IERC20 token) public onlyOwner {
		require(address(token) != address(0));
		token.transfer(_msgSender(), token.balanceOf(address(this)));
	}

  /* Helpers */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    IERC721 mutantsContract = IERC721(MUTANTS_CONTRACT_ADDRESS);

    address owner = mutantsContract.ownerOf(tokenId);
    return (spender == owner || mutantsContract.getApproved(tokenId) == spender || mutantsContract.isApprovedForAll(owner, spender));
  }
}