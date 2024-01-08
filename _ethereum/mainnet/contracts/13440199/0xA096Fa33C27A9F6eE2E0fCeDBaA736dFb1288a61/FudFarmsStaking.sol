// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./Pausable.sol";
import "./IERC20.sol";
import "./console.sol";

interface ICropToken is IERC20 {
    function depositsOf(address account) external view returns (uint256[] memory);
    function _depositBlocks(address addr, uint256 id) external view returns (uint256);
    function claimRewards(uint256[] calldata tokenIds) external;
}

contract FudFarmsStaking is Ownable, IERC721Receiver, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.UintSet; 
    
    //addresses 
    IERC721 public fudFarmToken;
    ICropToken public cropToken;

    address public contractAddress;

    //uint256's 
    uint256 public expiration;
    //rate governs how often you receive your token
    uint256 public rate;
  
    // mappings 
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;

    constructor() {
        contractAddress = address(this);
        _pause();
    }

    modifier requireCropToken() {
        require(address(cropToken) != address(0), "cropToken not set");
        _;
    }

    modifier requireFudFarmToken() {
        require(address(fudFarmToken) != address(0), "fudFarmToken not set");
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function arrayContains(uint256[] memory arr, uint256 value) private pure returns(bool) {
      for (uint256 i = 0; i < arr.length; i++) {
        if(arr[i] == value) {
          return true;
        }
      }
      return false;
    }

/* STAKING MECHANICS */

    // Set a multiplier for how many tokens to earn each time a block passes.
    function setRate(uint256 _rate) public onlyOwner() {
      rate = _rate;
    }

    // Set this to a block to disable the ability to continue accruing tokens past that block number.
    function setExpiration(uint256 _expiration) public onlyOwner() {
      expiration = block.number + _expiration;
    }

    function setCropTokenAddress(address cropTokenAddr) public onlyOwner() {
      cropToken = ICropToken(cropTokenAddr);
    }

    function setFudFarmTokenAddress(address fudFarmAddr) public onlyOwner() {
      fudFarmToken = IERC721(fudFarmAddr);
    }

    //check deposit amount. 
    function depositsOf(address account)
      external 
      view 
      requireCropToken
      returns (uint256[] memory)
    {
      EnumerableSet.UintSet storage depositSet = _deposits[account];
      uint256[] memory depositSetOtherContract = cropToken.depositsOf(account);
      uint256[] memory tokenIds = new uint256[] (depositSet.length() + depositSetOtherContract.length);

      for (uint256 i; i < depositSet.length(); i++) {
        tokenIds[i] = depositSet.at(i);
      }
      // Check deposits from the other contract
      for (uint256 i = depositSet.length(); i < depositSet.length() + depositSetOtherContract.length; i++) {
        tokenIds[i] = depositSetOtherContract[i - depositSet.length()];
      }

      return tokenIds;
    }

    function calculateRewards(address account, uint256[] memory tokenIds) 
      public 
      view 
      requireCropToken
      returns (uint256[] memory rewards) 
    {
      uint256[] memory tokensInOldContract = cropToken.depositsOf(account);
      return calculateRewards(account, tokenIds, tokensInOldContract);
    }

    function calculateRewards(address account, uint256[] memory tokenIds, uint256[] memory tokensInOldContract) 
      private 
      view 
      requireCropToken
      returns (uint256[] memory rewards) 
    {
      rewards = new uint256[](tokenIds.length);

      for (uint256 i; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];
        uint256 lastBlock = arrayContains(tokensInOldContract, tokenId) ? 
          cropToken._depositBlocks(account, tokenId) 
          : _depositBlocks[account][tokenId];
        if(lastBlock < _depositBlocks[account][tokenId]) {
          lastBlock = _depositBlocks[account][tokenId]; 
        }

        rewards[i] = 
          rate * 
          (_deposits[account].contains(tokenId) || arrayContains(tokensInOldContract, tokenId) ? 1 : 0) * 
          (Math.min(block.number, expiration) - lastBlock);
      }

      return rewards;
    }

    //reward amount by address/tokenIds[]
    function calculateReward(address account, uint256 tokenId, uint256[] memory tokensInOldContract) 
      private 
      view 
      requireCropToken
      returns (uint256) 
    {
      require(Math.min(block.number, expiration) > _depositBlocks[account][tokenId], "Invalid blocks");
      uint256 lastBlock = arrayContains(tokensInOldContract, tokenId) ? 
        cropToken._depositBlocks(account, tokenId) 
        : _depositBlocks[account][tokenId];
      if(lastBlock < _depositBlocks[account][tokenId]) {
        lastBlock = _depositBlocks[account][tokenId]; 
      }
      return rate * 
          (_deposits[account].contains(tokenId) || arrayContains(tokensInOldContract, tokenId) ? 1 : 0) * 
          (Math.min(block.number, expiration) - lastBlock);
    }

    //reward claim function 
    function claimRewards(uint256[] calldata tokenIds) public whenNotPaused requireCropToken {
      uint256 reward; 
      uint256 blockCur = Math.min(block.number, expiration);
      uint256[] memory tokensInOldContract = cropToken.depositsOf(msg.sender);

      for (uint256 i; i < tokenIds.length; i++) {
        reward += calculateReward(msg.sender, tokenIds[i], tokensInOldContract);
        _depositBlocks[msg.sender][tokenIds[i]] = blockCur;
      }
      // Reset the block from the old contract. They do not receive rewards from there, but will from here
      cropToken.claimRewards(tokensInOldContract);

      if (reward > 0) {
        cropToken.transfer(msg.sender, reward);
      }
    }

    //deposit function. 
    function deposit(uint256[] calldata tokenIds) external whenNotPaused requireFudFarmToken requireCropToken {
        require(msg.sender != address(cropToken), "Invalid address");
        claimRewards(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            fudFarmToken.safeTransferFrom(
                msg.sender,
                address(this),
                tokenIds[i],
                ""
            );

            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    //withdrawal function.
    function withdraw(uint256[] calldata tokenIds) external whenNotPaused requireFudFarmToken requireCropToken nonReentrant() {
        claimRewards(tokenIds);

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                _deposits[msg.sender].contains(tokenIds[i]),
                "Staking: token not deposited"
            );

            _deposits[msg.sender].remove(tokenIds[i]);

            fudFarmToken.safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i],
                ""
            );
        }
    }

    //withdrawal function.
    function withdrawTokens() external onlyOwner {
        uint256 tokenSupply = cropToken.balanceOf(address(this));
        cropToken.transfer(msg.sender, tokenSupply);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}