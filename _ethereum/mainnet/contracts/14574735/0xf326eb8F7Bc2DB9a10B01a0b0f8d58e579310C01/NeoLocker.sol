// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./NeoAnunnaki.sol";

/// @title NeoLocker
/// @author aceplxx (https://twitter.com/aceplxx)

contract NeoLocker is ReentrancyGuard, Ownable {

    bool public rewardPaused = true;
    address public genetix;

    NeoAnunnaki private neoAnunnaki;

    uint256 public baseReward;

    // Mapping from token ID to locker address
    mapping(uint256 => address) private _lockedBy;
    mapping(address => uint256) public lockedAmount;
    mapping(address => uint256) public lastClaimed;

    /* ========== MODIFIERS ========== */

    modifier onlyNFTContract() {
        require(msg.sender == address(neoAnunnaki), "Only NFT Contract");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _genetix, address payable _neoAnunnaki, uint256 _baseReward){
        genetix = _genetix;
        neoAnunnaki = NeoAnunnaki(_neoAnunnaki);
        baseReward = _baseReward;
    }

    /* ========== OWNER FUNCTIONS ========== */

    function toggleRewardPaused() external onlyOwner{
        rewardPaused = !rewardPaused;
    }

    function setToken(address _token) external onlyOwner{
        genetix = _token;
    }

    function setNeoNFT(address payable _neoAnunnaki) external onlyOwner{
        neoAnunnaki = NeoAnunnaki(_neoAnunnaki);
    }

    function clearLock(uint256 _tokenId) external onlyNFTContract{
        delete _lockedBy[_tokenId];
    }

    /* ========== PUBLIC READ ========== */

    function neoAnunnakiContract() external view returns (address){
        return address(neoAnunnaki);
    } 

    /// @notice get pending reward of a user (if any)
    /// @param _user wallet address of a user
    function getPendingReward(address _user)
        external
        view
        returns (uint256 rewards)
    {
        rewards = _getPendingReward(_user);
    }

    /// @notice check whether an NFT is locked by an address
    /// @param tokenId NFT token id
    function lockedBy(uint256 tokenId) external view returns (address) {
        return _lockedBy[tokenId];
    }

    /* ========== PUBLIC MUTATIVE ========== */

    /// @notice lock an NFT to earn $GENETIX, locked NFT is not transferable
    /// @param tokenId NFT token id to be locked
    function lock(uint256 tokenId) external nonReentrant {
        require(
            neoAnunnaki.ownerOf(tokenId) == msg.sender,
            "Not owner nor approved"
        );
        require(_lockedBy[tokenId] == address(0), "already locked");

        _lockedBy[tokenId] = msg.sender;

        uint256 reward = _getPendingReward(msg.sender);

        lastClaimed[msg.sender] = block.timestamp;
        lockedAmount[msg.sender]++;

        if (reward > 0 && !rewardPaused) {
            _harvestReward(reward);
        }

    }

    /// @notice unlock an NFT
    /// @param tokenId NFT token id to be unlocked
    function unlock(uint256 tokenId) external nonReentrant {
        require(
            neoAnunnaki.exists(tokenId),
            "Nonexistent token"
        );
        require(_lockedBy[tokenId] == msg.sender, "caller is not locker");

        delete _lockedBy[tokenId];

        uint256 reward = _getPendingReward(msg.sender);

        lastClaimed[msg.sender] = block.timestamp;
        lockedAmount[msg.sender]--;

        if (reward > 0 && !rewardPaused) {
            _harvestReward(reward);
        }
    }

    function harvestReward() external {
        uint256 reward = _getPendingReward(msg.sender);
        _harvestReward(reward);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _getPendingReward(address _user) internal view returns (uint256) {
        return
            (lockedAmount[_user] *
                baseReward *
                (block.timestamp - lastClaimed[_user])) / 86400;
    }

    function _harvestReward(uint256 _reward) internal {
        require(!rewardPaused, "Claiming reward has been paused");
        lastClaimed[msg.sender] = block.timestamp;
        IERC20(genetix).transfer(msg.sender, _reward);
    }
}