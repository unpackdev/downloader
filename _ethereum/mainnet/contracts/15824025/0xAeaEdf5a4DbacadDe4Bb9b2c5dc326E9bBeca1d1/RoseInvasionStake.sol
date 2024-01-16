// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./ReentrancyGuard.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./Ownable.sol";

contract RoseInvasionStake is Ownable, ReentrancyGuard, IERC721Receiver {

    event Staking(address indexed account, uint256 tokenId);
    event Unstaking(address indexed account, uint256 tokenId);

    mapping(uint256 => StakingInfo[]) public allStakeInfos;

    IERC721 public immutable roseInvasionNFT;
    uint256 public minStakingDuration;

    mapping(address => uint256) public balances; // users staking token balance
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;

    struct StakingInfo {
        address owner;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
    }

    constructor (address roseInvasionNFT_) {
        roseInvasionNFT = IERC721(roseInvasionNFT_);
        minStakingDuration = 1 days;
    }

    function batchStaking(uint256[] memory tokenIds) external nonReentrant {
        for (uint i = 0; i < tokenIds.length; i++) {
            staking(tokenIds[i]);
        }
    }

    function batchUnstaking(uint256[] memory tokenIds) external nonReentrant {
        for (uint i = 0; i < tokenIds.length; i++) {
            unstaking(tokenIds[i]);
        }
    }

    function batchGetLastTokenStakeInfo(uint256[] calldata tokenIds) public view returns(StakingInfo[] memory) {
        StakingInfo[] memory infos = new StakingInfo[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            infos[i] = getLastTokenStakeInfo(tokenIds[i]);
        }
        return infos;
    }

    function getLastTokenStakeInfo(uint256 tokenId) public view returns(StakingInfo memory) {
        StakingInfo[] memory stakedInfos = allStakeInfos[tokenId];
        require(stakedInfos.length > 0, "no history");
        return stakedInfos[stakedInfos.length - 1];
    }

    function getAllTokenStakeInfo(uint256 tokenId) public view returns(StakingInfo[] memory) {
        return allStakeInfos[tokenId];
    }

    function staking(uint256 tokenId) internal  {
        require(roseInvasionNFT.ownerOf(tokenId) == msg.sender, "only owner");
        _staking(msg.sender, tokenId);
    }

    function unstaking(uint256 tokenId) internal  {
        require(roseInvasionNFT.ownerOf(tokenId) == address(this), "already unstaked");
        StakingInfo storage info = allStakeInfos[tokenId][allStakeInfos[tokenId].length - 1];
        require(info.owner == msg.sender && info.owner != address(0) , "only owner");
        require(info.endTime == 0, "already unstaked");
        require(info.startTime + minStakingDuration < block.timestamp, "min duration");
        info.endTime = block.timestamp;
        _unstaking(msg.sender, tokenId);
    }

    function _staking(address account, uint256 tokenId) internal {
        roseInvasionNFT.safeTransferFrom(account, address(this), tokenId);
        StakingInfo memory info;
        info.owner = account;
        info.tokenId = tokenId;
        info.startTime = block.timestamp;
        allStakeInfos[tokenId].push(info);
        _addTokenToOwner(account, tokenId);
        emit Staking(account, tokenId);
    }

    function _unstaking(address account, uint256 tokenId) internal {
        roseInvasionNFT.safeTransferFrom(address(this), account, tokenId);
        _removeTokenFromOwner(account, tokenId);
        emit Unstaking(account, tokenId);
    }

    function setMinStakingDuration(uint256 duration) external onlyOwner {
        minStakingDuration = duration;
    }

    function tokensOfOwner(address account, uint _from, uint _to) public view returns(uint256[] memory) {
        require(_to < balances[account], "Wrong max array value");
        require((_to - _from) <= balances[account], "Wrong array range");
        uint256[] memory tokens = new uint256[](_to - _from + 1);
        uint index = 0;
        for (uint i = _from; i <= _to; i++) {
            tokens[index] = _ownedTokens[account][i];
            index++;
        }
        return (tokens);
    }

    function _removeTokenFromOwner(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = balances[from] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
        balances[from]--;
    }

    function _addTokenToOwner(address to, uint256 tokenId) private {
        uint256 length = balances[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
        balances[to]++;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}