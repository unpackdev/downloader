// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IERC721.sol";

contract RewardNft is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public rewards;
    uint256 public rewardPerToken;
    mapping(address => bool) public nftTokenEnabled;
    mapping(address => mapping(uint256 => bool)) public tokenClaimed;
    mapping(address => mapping(uint256 => bool)) internal blockListByTokenAndTokenId;
    mapping(address => bool) internal blockListByTokenHolder;

    event EnableNftToken(address indexed token, bool indexed enabled);
    event ClaimReward(address indexed user, address indexed token, uint256 tokenId, uint256 rewardAmount);
    event ClaimRewardBatch(address indexed user, address indexed token, uint256[] tokenIds, uint256 rewardAmount);
    event AllowNftTokenId(address indexed token, uint256 tokenId, bool indexed allow);
    event AllowNftTokenIds(address indexed token, bool indexed allow);
    event AllowTokenHolder(address indexed holder, bool indexed allow);
    event AllowTokenHolders(bool indexed allow);

    modifier onlyEnabledNft(address _token) {
        require(nftTokenEnabled[_token] == true, "token not enabled");
        _;
    }

    modifier onlyAllowTokenId(address _token, uint256 _tokenId) {
        require(blockListByTokenAndTokenId[_token][_tokenId] == false, "tokenId is blocked");
        _;
    }

    modifier onlyAllowTokenHolder() {
        require(blockListByTokenHolder[msg.sender] == false, "token holder is blocked");
        _;
    }

    constructor(IERC20 _rewards, uint256 _rewardPerToken) {
        rewards = _rewards;
        rewardPerToken = _rewardPerToken;
    }

    function enableNftToken(address _token, bool _enabled) external onlyOwner {
        nftTokenEnabled[_token] = _enabled;
        emit EnableNftToken(_token, _enabled);
    }

    function allowNftTokenId(
        address _token,
        uint256 _tokenId,
        bool _allow
    ) external onlyOwner {
        blockListByTokenAndTokenId[_token][_tokenId] = !_allow;
        emit AllowNftTokenId(_token, _tokenId, _allow);
    }

    function allowNftTokenIdBatch(
        address _token,
        uint256[] calldata _tokenIds,
        bool _allow
    ) external onlyOwner {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            blockListByTokenAndTokenId[_token][_tokenIds[i]] = !_allow;
        }
        emit AllowNftTokenIds(_token, _allow);
    }

    function isTokenIdBlocked(address _token, uint256 _tokenId) external view returns (bool) {
        return blockListByTokenAndTokenId[_token][_tokenId];
    }

    function allowTokenHolder(address _holder, bool _allow) external onlyOwner {
        blockListByTokenHolder[_holder] = !_allow;
        emit AllowTokenHolder(_holder, _allow);
    }

    function allowTokenHolderBatch(address[] calldata _holders, bool _allow) external onlyOwner {
        for (uint256 i = 0; i < _holders.length; i++) {
            blockListByTokenHolder[_holders[i]] = !_allow;
        }
        emit AllowTokenHolders(_allow);
    }

    function isHolderBlocked(address _holder) external view returns (bool) {
        return blockListByTokenHolder[_holder];
    }

    function claimReward(address _token, uint256 _tokenId)
        external
        onlyEnabledNft(_token)
        onlyAllowTokenHolder
        nonReentrant
    {
        _claimReward(_token, _tokenId);
        emit ClaimReward(msg.sender, _token, _tokenId, rewardPerToken);
    }

    function claimRewardBatch(address _token, uint256[] calldata _tokenIds)
        external
        onlyEnabledNft(_token)
        onlyAllowTokenHolder
        nonReentrant
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _claimReward(_token, _tokenIds[i]);
        }
        emit ClaimRewardBatch(msg.sender, _token, _tokenIds, rewardPerToken);
    }

    function _claimReward(address _token, uint256 _tokenId) internal onlyAllowTokenId(_token, _tokenId) {
        require(tokenClaimed[_token][_tokenId] == false, "token already claimed");
        require(IERC721(_token).ownerOf(_tokenId) == msg.sender, "wrong tokenId owner");
        tokenClaimed[_token][_tokenId] = true;
        rewards.safeTransfer(msg.sender, rewardPerToken);
    }
}
