// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract JungleParty is ERC20Burnable, Ownable {

    using SafeMath for uint256;

    uint256 public JUNGLEKING_RATE = 57870370370000000000; //5_000_000 per day
    uint256 public HELLTIGER_RATE = 115740740740000000000; //10_000_000 per day
    uint256 public OG_HELLTIGER_RATE = 231481481480000000000; //20_000_000 per day
    uint256 public CLAIM_END_TIME = 1874980800; // Jun 01 2029 04:00:00 GMT+0000

    address nullAddress = 0x0000000000000000000000000000000000000000;

    uint256 public immutable OG_LIMIT;
    address public immutable tigerAddress;
    address public immutable junglekingAddress;
    address public immutable helltigerAddress;

    //Mapping of tokenId to timestamp
    mapping(uint256 => uint256) internal jkTokenIdToTimestamp;
    mapping(uint256 => uint256) internal htTokenIdToTimestamp;

    //Mapping of tokenId to staker
    mapping(uint256 => address) internal jkTokenIdToStaker;
    mapping(uint256 => address) internal htTokenIdToStaker;

    //Mapping of staker to tokenIds
    mapping(address => uint256[]) internal stakerToJKTokenIds;
    mapping(address => uint256[]) internal stakerToHTTokenIds;

    constructor(
        uint256 _OG_LIMIT,
        address _tiger,
        address _jungleking,
        address _helltiger
    ) ERC20("JungleParty", "Jungle-Party") {
        OG_LIMIT = _OG_LIMIT;
        tigerAddress = _tiger;
        junglekingAddress = _jungleking;
        helltigerAddress = _helltiger;
    }
    
    function getJKTokensStaked(address staker) public view returns (uint256[] memory) {
        return stakerToJKTokenIds[staker];
    }

    function getHTTokensStaked(address staker) public view returns (uint256[] memory) {
        return stakerToHTTokenIds[staker];
    }

    function removeJungleKingByIndex(address staker, uint256 index) internal {
        if (index >= stakerToJKTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToJKTokenIds[staker].length - 1; i++) {
            stakerToJKTokenIds[staker][i] = stakerToJKTokenIds[staker][i + 1];
        }
        stakerToJKTokenIds[staker].pop();
    }

    function removeHellTigerByIndex(address staker, uint256 index) internal {
        if (index >= stakerToHTTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToHTTokenIds[staker].length - 1; i++) {
            stakerToHTTokenIds[staker][i] = stakerToHTTokenIds[staker][i + 1];
        }
        stakerToHTTokenIds[staker].pop();
    }

    function removeJungleKingByTokenId(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToJKTokenIds[staker].length; i++) {
            if (stakerToJKTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                removeJungleKingByIndex(staker, i);
            }
        }
    }

    function removeHellTigerByTokenId(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToHTTokenIds[staker].length; i++) {
            if (stakerToHTTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                removeHellTigerByIndex(staker, i);
            }
        }
    }

    function StakeJungleKingByTokenIds(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(junglekingAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    jkTokenIdToStaker[tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721(junglekingAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToJKTokenIds[msg.sender].push(tokenIds[i]);

            jkTokenIdToTimestamp[tokenIds[i]] = block.timestamp;
            jkTokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function StakeHellTigerByTokenIds(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(helltigerAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    htTokenIdToStaker[tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721(helltigerAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToHTTokenIds[msg.sender].push(tokenIds[i]);

            htTokenIdToTimestamp[tokenIds[i]] = block.timestamp;
            htTokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeJungleKingAll() public {
        require(stakerToJKTokenIds[msg.sender].length > 0, "Must have at least one token staked!");
        uint256 totalRewards = 0;

        for (uint256 i = stakerToJKTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToJKTokenIds[msg.sender][i - 1];
            IERC721(junglekingAddress).transferFrom(address(this), msg.sender, tokenId);
            totalRewards = totalRewards + ((block.timestamp - jkTokenIdToTimestamp[tokenId]) * JUNGLEKING_RATE);
            removeJungleKingByTokenId(msg.sender, tokenId);
            jkTokenIdToStaker[tokenId] = nullAddress;
        }

        IERC20(tigerAddress).transfer(msg.sender, totalRewards);
    }

    function unstakeHellTigerAll() public {
        require(stakerToHTTokenIds[msg.sender].length > 0, "Must have at least one token staked!");
        uint256 totalRewards = 0;

        for (uint256 i = stakerToHTTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToHTTokenIds[msg.sender][i - 1];
            IERC721(helltigerAddress).transferFrom(address(this), msg.sender, tokenId);
            if (tokenId <= OG_LIMIT) {
                totalRewards = totalRewards + ((block.timestamp - htTokenIdToTimestamp[tokenId]) * OG_HELLTIGER_RATE);
            } else {
                totalRewards = totalRewards + ((block.timestamp - htTokenIdToTimestamp[tokenId]) * HELLTIGER_RATE);
            }
            removeHellTigerByTokenId(msg.sender, tokenId);
            htTokenIdToStaker[tokenId] = nullAddress;
        }

        IERC20(tigerAddress).transfer(msg.sender, totalRewards);
    }

    function unstakeJungleKingByTokenIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(jkTokenIdToStaker[tokenIds[i]] == msg.sender, "Message Sender was not original staker!");
            IERC721(junglekingAddress).transferFrom(address(this), msg.sender, tokenIds[i]);
            totalRewards = totalRewards + ((block.timestamp - jkTokenIdToTimestamp[tokenIds[i]]) * JUNGLEKING_RATE);
            removeJungleKingByTokenId(msg.sender, tokenIds[i]);
            jkTokenIdToStaker[tokenIds[i]] = nullAddress;
        }

        IERC20(tigerAddress).transfer(msg.sender, totalRewards);
    }

    function unstakeHellTigerByTokenIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(htTokenIdToStaker[tokenIds[i]] == msg.sender, "Message Sender was not original staker!");
            IERC721(helltigerAddress).transferFrom(address(this), msg.sender, tokenIds[i]);
            if (tokenIds[i] <= OG_LIMIT) {
                totalRewards = totalRewards + ((block.timestamp - htTokenIdToTimestamp[tokenIds[i]]) * OG_HELLTIGER_RATE);
            } else {
                totalRewards = totalRewards + ((block.timestamp - htTokenIdToTimestamp[tokenIds[i]]) * HELLTIGER_RATE);
            }
            removeHellTigerByTokenId(msg.sender, tokenIds[i]);
            htTokenIdToStaker[tokenIds[i]] = nullAddress;
        }

        IERC20(tigerAddress).transfer(msg.sender, totalRewards);
    }

    function claimJungleKingByTokenId(uint256 tokenId) public {
        require(jkTokenIdToStaker[tokenId] == msg.sender, "Token is not claimable by you!");
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");

        IERC20(tigerAddress).transfer(msg.sender, ((block.timestamp - jkTokenIdToTimestamp[tokenId]) * JUNGLEKING_RATE));

        jkTokenIdToTimestamp[tokenId] = block.timestamp;
    }

    function claimHellTigerByTokenId(uint256 tokenId) public {
        require(htTokenIdToStaker[tokenId] == msg.sender, "Token is not claimable by you!");
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");

        uint256 totalRewards = 0;
        if (tokenId <= OG_LIMIT) {
            totalRewards = (block.timestamp - htTokenIdToTimestamp[tokenId]) * OG_HELLTIGER_RATE;
        } else {
            totalRewards = (block.timestamp - htTokenIdToTimestamp[tokenId]) * HELLTIGER_RATE;
        }

        IERC20(tigerAddress).transfer(msg.sender, totalRewards);

        htTokenIdToTimestamp[tokenId] = block.timestamp;
    }

    function claimJungleKingAll() public {
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");
        uint256[] memory tokenIds = stakerToJKTokenIds[msg.sender];
        uint256 totalRewards = 0;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(jkTokenIdToStaker[tokenIds[i]] == msg.sender,"Token is not claimable by you!");

            totalRewards = totalRewards + ((block.timestamp - jkTokenIdToTimestamp[tokenIds[i]]) * JUNGLEKING_RATE);

            jkTokenIdToTimestamp[tokenIds[i]] = block.timestamp;
        }

        IERC20(tigerAddress).transfer(msg.sender, totalRewards);
    }

    function claimHellTigerAll() public {
        require(block.timestamp < CLAIM_END_TIME, "Claim period is over!");
        uint256[] memory tokenIds = stakerToHTTokenIds[msg.sender];
        uint256 totalRewards = 0;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(htTokenIdToStaker[tokenIds[i]] == msg.sender,"Token is not claimable by you!");
            
            if (tokenIds[i] <= OG_LIMIT) {
                totalRewards = totalRewards + ((block.timestamp - htTokenIdToTimestamp[tokenIds[i]]) * OG_HELLTIGER_RATE);
            } else {
                totalRewards = totalRewards + ((block.timestamp - htTokenIdToTimestamp[tokenIds[i]]) * HELLTIGER_RATE);
            }

            htTokenIdToTimestamp[tokenIds[i]] = block.timestamp;
        }

        IERC20(tigerAddress).transfer(msg.sender, totalRewards);
    }
    
    function getAllJungleKingRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToJKTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards = totalRewards + ((block.timestamp - jkTokenIdToTimestamp[tokenIds[i]]) * JUNGLEKING_RATE);
        }

        return totalRewards;
    }

    function getAllHellTigerRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToHTTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] <= OG_LIMIT) {
                totalRewards = totalRewards + ((block.timestamp - htTokenIdToTimestamp[tokenIds[i]]) * OG_HELLTIGER_RATE);
            } else {
                totalRewards = totalRewards + ((block.timestamp - htTokenIdToTimestamp[tokenIds[i]]) * HELLTIGER_RATE);
            }
        }

        return totalRewards;
    }

    function getJungleKingRewardsByTokenId(uint256 tokenId) public view returns (uint256){
        require(jkTokenIdToStaker[tokenId] != nullAddress, "Token is not staked!");

        uint256 secondsStaked = block.timestamp - jkTokenIdToTimestamp[tokenId];

        return secondsStaked * JUNGLEKING_RATE;
    }

    function getHellTigerRewardsByTokenId(uint256 tokenId) public view returns (uint256){
        require(htTokenIdToStaker[tokenId] != nullAddress, "Token is not staked!");

        uint256 secondsStaked = block.timestamp - htTokenIdToTimestamp[tokenId];

        if (tokenId <= OG_LIMIT) {
            return secondsStaked * OG_HELLTIGER_RATE;
        } else {
            return secondsStaked * HELLTIGER_RATE;
        }
    }

    function getJungleKingStaker(uint256 tokenId) public view returns (address) {
        return jkTokenIdToStaker[tokenId];
    }

    function getHellTigerStaker(uint256 tokenId) public view returns (address) {
        return htTokenIdToStaker[tokenId];
    }

    function sweepTiger(address receiver, uint256 amount) external onlyOwner {
        IERC20(tigerAddress).transfer(receiver, amount);
    }
}