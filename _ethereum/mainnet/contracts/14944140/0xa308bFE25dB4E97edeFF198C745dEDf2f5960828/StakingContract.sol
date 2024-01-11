// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./IERC721.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract StakingContract is Ownable, ReentrancyGuard {
    using Strings for uint256;

    address public rtoken;
    address public nftAddress;
    
    struct UserInfo {
        uint256 tokenId;
        uint256 rarity;
        uint256 startTime;
    }
    
    mapping(address => UserInfo[]) public userInfo;
    mapping(address => uint256) public stakingAmount;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);

    bytes32[5] public rarityMerkleRoot;
    uint256[5] public rewardTokenPerDay;

    constructor(address _rTokenAddress, address _nftTokenAddress, bytes32[] memory _rarityMerkleRoot, uint256[] memory _rewardTokenPerDay) {
        rtoken = _rTokenAddress;
        nftAddress = _nftTokenAddress;

        for(uint256 i = 0; i < _rarityMerkleRoot.length; i++) {
            rarityMerkleRoot[i] = _rarityMerkleRoot[i];
        }
        for(uint256 i = 0; i < _rewardTokenPerDay.length; i++) {
            rewardTokenPerDay[i] = _rewardTokenPerDay[i] * 1 ether;
        }
    }

    function updateRarityMerkleRoots(bytes32[] memory _rarityMerkleRoot) public onlyOwner() {
        for(uint256 i = 0; i < _rarityMerkleRoot.length; i++) {
            rarityMerkleRoot[i] = _rarityMerkleRoot[i];
        }
    }

    function changeRewardTokenAddress(address _rewardTokenAddress) public onlyOwner {
        rtoken = _rewardTokenAddress;
    }

    function changeNftTokenAddress(address _nftTokenAddress) public onlyOwner {
        nftAddress = _nftTokenAddress;
    }

    function changeRewardTokenPerDay(uint256[] memory _rewardTokenPerDay) public onlyOwner {
        for(uint256 i = 0; i < 5; i++)  
            rewardTokenPerDay[i] = _rewardTokenPerDay[i];
    }

    function approve(address tokenAddress, address spender, uint256 amount) public onlyOwner returns (bool) {
      IERC20(tokenAddress).approve(spender, amount);
      return true;
    }

    function pendingReward(address _user, uint256 _tokenId, uint256 _rarity) public view returns (uint256) {

        (bool _isStaked, uint256 _startTime) = getStakingItemInfo(_user, _tokenId);
        if(!_isStaked) return 0;

        uint256 currentTime = block.timestamp;        
        uint256 rewardAmount = rewardTokenPerDay[_rarity] * (currentTime - _startTime) / 1 days;
        return rewardAmount;
    }

    function pendingTotalReward(address _user) public view returns(uint256) {
        uint256 pending = 0;
        for (uint256 i = 0; i < userInfo[_user].length; i++) {
            uint256 temp = pendingReward(_user, userInfo[_user][i].tokenId, userInfo[_user][i].rarity);
            pending = pending + temp;
        }
        return pending;
    }

    function getRarity(bytes32[] calldata _merkleProof, uint256 _tokenId) public view returns(uint256) {
        bytes32 leaf = keccak256(abi.encodePacked(_tokenId.toString()));
        for(uint256 i = 0; i < 5; i++) {
            if(MerkleProof.verify(_merkleProof, rarityMerkleRoot[i], leaf)) {
                return i;
            }
        }
        return 5;
    }

    function stake(uint256[] memory tokenIds, bytes32[][] calldata _merkleProofs) public {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            (bool _isStaked,) = getStakingItemInfo(msg.sender, tokenIds[i]);
            if(_isStaked) continue;
            require(IERC721(nftAddress).ownerOf(tokenIds[i]) == msg.sender, "Not your NFT");

            IERC721(nftAddress).transferFrom(address(msg.sender), address(this), tokenIds[i]);

            uint256 _rarity = getRarity(_merkleProofs[i], tokenIds[i]);
            require(_rarity < 5, "Invalid in merkleproof");

            UserInfo memory info;
            info.tokenId = tokenIds[i];
            info.rarity = _rarity;
            info.startTime = block.timestamp;

            userInfo[msg.sender].push(info);
            stakingAmount[msg.sender] = stakingAmount[msg.sender] + 1;
            emit Stake(msg.sender, 1);
        }
    }

    function unstake(uint256[] memory tokenIds) public nonReentrant {
        require(tokenIds.length > 0, "Token number to unstake is zero.");
        uint256 pending = pendingTotalReward(msg.sender);
        if(pending > 0) {
            IERC20(rtoken).transfer(msg.sender, pending);
        }

        for(uint256 i = 0; i < tokenIds.length; i++) {
            (bool _isStaked,) = getStakingItemInfo(msg.sender, tokenIds[i]);
            if(!_isStaked) continue;
            if(IERC721(nftAddress).ownerOf(tokenIds[i]) != address(this)) continue;

            removeFromUserInfo(tokenIds[i]);
            if(stakingAmount[msg.sender] > 0)
                stakingAmount[msg.sender] = stakingAmount[msg.sender] - 1;
            IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenIds[i]);
            emit UnStake(msg.sender, 1);
        }
    }

    function getStakingItemInfo(address _user, uint256 _tokenId) public view returns(bool _isStaked, uint256 _startTime) {
        for(uint256 i = 0; i < userInfo[_user].length; i++) {
            if(userInfo[_user][i].tokenId == _tokenId) {
                _isStaked = true;
                _startTime = userInfo[_user][i].startTime;
                break;
            }
        }
    }

    function removeFromUserInfo(uint256 tokenId) private {        
        for (uint256 i = 0; i < userInfo[msg.sender].length; i++) {
            if (userInfo[msg.sender][i].tokenId == tokenId) {
                userInfo[msg.sender][i] = userInfo[msg.sender][userInfo[msg.sender].length - 1];
                userInfo[msg.sender].pop();
                break;
            }
        }        
    }

    function claim() public {

        uint256 reward = pendingTotalReward(msg.sender);

        for (uint256 i = 0; i < userInfo[msg.sender].length; i++)
            userInfo[msg.sender][i].startTime = block.timestamp;

        IERC20(rtoken).transfer(msg.sender, reward);
    }
}