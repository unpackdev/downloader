// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./Math.sol";
import "./IERC721Enumerable.sol";


contract AngelRewards is Ownable, ReentrancyGuard, Pausable {
  
    IERC721Enumerable public erc721Token;
    IERC20 public erc20Token;
    uint256 public expiration; 
    uint256 public rate;
    uint256 public start; 
  
    mapping(uint256 => uint256) public _lastTokenClaimBlock;

    constructor() {
        start = block.timestamp;
        _pause();
    }

    modifier requireContractsSet() {
        require(address(erc20Token) != address(0) 
          && address(erc721Token) != address(0), "Contracts not set");
        _;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Set a multiplier for how many tokens to earn each time a block passes.
    function setRate(uint256 _rate) external onlyOwner {
      rate = _rate;
    }

    // Set this to a block to disable the ability to continue accruing tokens past that block number.
    function setExpiration(uint256 _expiration) external onlyOwner {
      expiration = block.number + _expiration;
    }

    function setContracts(address erc721Address, address erc20Address) external onlyOwner {
      erc721Token = IERC721Enumerable(erc721Address);
      erc20Token = IERC20(erc20Address);
    }

    function calculateRewards(address account)
      public view requireContractsSet
      returns (uint256 rewards) 
    {
      uint256 numTokens = erc721Token.balanceOf(account);
      rewards = 0;

      for (uint256 i; i < numTokens; i++) {
        uint256 tokenId = erc721Token.tokenOfOwnerByIndex(account, i);
        if(tokenId > 1000) {
          // Angels are token ids 1 - 1000 and are the only ones that can accrue tokens
          continue;
        }
        rewards += 
          rate * (Math.min(block.number, expiration) - 
            Math.max(_lastTokenClaimBlock[tokenId], start));
      }
      return rewards;
    }

    //reward claim function 
    function claimRewards() public requireContractsSet whenNotPaused {
      uint256 reward; 
      uint256 blockCur = Math.min(block.number, expiration);
      uint256 numTokens = erc721Token.balanceOf(_msgSender());

      for (uint256 i; i < numTokens; i++) {
        uint256 tokenId = erc721Token.tokenOfOwnerByIndex(_msgSender(), i);
        if(tokenId > 1000) {
          // Angels are token ids 1 - 1000 and are the only ones that can accrue tokens
          continue;
        }
        reward += rate * (Math.min(block.number, expiration) - 
            Math.max(_lastTokenClaimBlock[tokenId], start));
        _lastTokenClaimBlock[tokenId] = blockCur;
      }

      require(reward > 0, "No tokens to claim");
      erc20Token.transfer(msg.sender, reward);
    }

    //withdrawal function.
    function withdrawTokens() external requireContractsSet onlyOwner {
        uint256 tokenSupply = erc20Token.balanceOf(address(this));
        erc20Token.transfer(msg.sender, tokenSupply);
    }
}