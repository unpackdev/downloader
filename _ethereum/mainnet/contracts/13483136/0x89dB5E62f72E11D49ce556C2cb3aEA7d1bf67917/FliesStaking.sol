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


contract FliesStaking is Ownable, IERC721Receiver, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;

    address public stakingDestinationAddress = 0xAf6041F80a76ED59705EfC835Ed94d62927108a1;
    address public erc20Address = 0x4675b41aF96bca0a2feBbf204FA55cA01913a683;

    uint256 public expiration = 0;
    uint256 public rate = 0;

    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;

    function depositsOf(address account)
      external
      view
      returns (uint256[] memory)
    {
      EnumerableSet.UintSet storage depositSet = _deposits[account];
      uint256[] memory tokenIds = new uint256[] (depositSet.length());

      for (uint256 i; i < depositSet.length(); i++) {
        tokenIds[i] = depositSet.at(i);
      }

      return tokenIds;
    }

    function calculateRewards(address account, uint256[] memory tokenIds)
      public
      view
      returns (uint256[] memory rewards)
    {
      rewards = new uint256[](tokenIds.length);

      for (uint256 i; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];

        rewards[i] =
          rate *
          (_deposits[account].contains(tokenId) ? 1 : 0) *
          (Math.min(block.number, expiration) -
            _depositBlocks[account][tokenId]);
      }

      return rewards;
    }

    function calculateReward(address account, uint256 tokenId)
      public
      view
      returns (uint256)
    {
      require(Math.min(block.number, expiration) > _depositBlocks[account][tokenId], "Invalid blocks");
      return rate *
        (_deposits[account].contains(tokenId) ? 1 : 0) *
        (Math.min(block.number, expiration) -
          _depositBlocks[account][tokenId]);
    }

    function claimRewards(uint256[] calldata tokenIds) public whenNotPaused {
      uint256 reward;
      uint256 blockCur = Math.min(block.number, expiration);

      for (uint256 i; i < tokenIds.length; i++) {
        reward += calculateReward(msg.sender, tokenIds[i]);
        _depositBlocks[msg.sender][tokenIds[i]] = blockCur;
      }

      if (reward > 0) {
        IERC20(erc20Address).transfer(msg.sender, reward);
      }
    }

    function deposit(uint256[] calldata tokenIds) external whenNotPaused {
      require(msg.sender != stakingDestinationAddress, "Invalid address");
      claimRewards(tokenIds);

      for (uint256 i; i < tokenIds.length; i++) {
        IERC721(stakingDestinationAddress).safeTransferFrom(
          msg.sender,
          address(this),
          tokenIds[i],
          ""
        );

        _deposits[msg.sender].add(tokenIds[i]);
      }
    }

    function withdraw(uint256[] calldata tokenIds) external whenNotPaused nonReentrant() {
      claimRewards(tokenIds);

      for (uint256 i; i < tokenIds.length; i++) {
        require(
          _deposits[msg.sender].contains(tokenIds[i]),
          "Staking: Flies token not deposited"
        );

        _deposits[msg.sender].remove(tokenIds[i]);

        IERC721(stakingDestinationAddress).safeTransferFrom(
          address(this),
          msg.sender,
          tokenIds[i],
          ""
        );
      }
    }

    function pause() public onlyOwner {
      _pause();
    }

    function unpause() public onlyOwner {
      _unpause();
    }

    function setRate(uint256 _rate) public onlyOwner() {
      rate = _rate;
    }

    function setExpiration(uint256 _expiration) public onlyOwner() {
      expiration = block.number + _expiration;
    }

    function withdrawTokens() external onlyOwner {
      uint256 tokenSupply = IERC20(erc20Address).balanceOf(address(this));
      IERC20(erc20Address).transfer(msg.sender, tokenSupply);
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
