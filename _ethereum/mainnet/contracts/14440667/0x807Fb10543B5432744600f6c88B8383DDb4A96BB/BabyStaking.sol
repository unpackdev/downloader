// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";

contract BabyStaking is Ownable {
    
    uint256 public constant MAX_WALLET_STAKED = 10;
    uint256 public constant EMISSION_RATE = uint256(5 * 1e18) / 86400;
    uint256 public endTime = 2000000000; // Wednesday, 18 May 2033 03:33:20
    address public constant NULL_ADDRESS = 0x0000000000000000000000000000000000000000;
     
    address public babyDraco;
    address public essence;
    bool public stakingStart = false;
   
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    mapping(uint256 => address) internal tokenIdToStaker;

    mapping(address => uint256[]) internal stakerToTokenIds;

    function setBabyDraco(address _babyDraco) public onlyOwner {
        babyDraco = _babyDraco;
    }

    function setEssence(address _essence) public onlyOwner {
        essence = _essence;
    }

    function setStakingStart(bool _stakingStart) public onlyOwner {
        stakingStart = _stakingStart;
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

    function withdraw() public onlyOwner {
        IERC20 iEssence = IERC20(essence);
        iEssence.transfer(
            msg.sender,
            iEssence.balanceOf(address(this))
        );
    }

    function getTokensStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function getTokensUnstaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        IERC721Enumerable iBabyDraco = IERC721Enumerable(babyDraco);
        uint256 tokenCount = iBabyDraco.balanceOf(staker);

        uint256[] memory tokensId = new uint256[](tokenCount);
        
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = iBabyDraco.tokenOfOwnerByIndex(staker, i);
        }

        return tokensId;
    }

    function remove(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                remove(staker, i);
            }
        }
    }

    function stakeByIds(uint256[] memory tokenIds) public {
        require(
            stakerToTokenIds[msg.sender].length + tokenIds.length <=
                MAX_WALLET_STAKED,
            "Max 10 staked boner"
        );

        require(stakingStart, "Stake not started");
        require(block.timestamp <= endTime , "Stake ended");
        IERC721 iBabyDraco = IERC721(babyDraco);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                iBabyDraco.ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == NULL_ADDRESS,
                "Token must be stakable by you!"
            );

            iBabyDraco.transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;
        IERC721 iBabyDraco = IERC721(babyDraco);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            iBabyDraco.transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards = totalRewards + getRewardsByTokenId(tokenIds[i]);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = NULL_ADDRESS;
        }

        IERC20(essence).transfer(msg.sender, totalRewards);
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );

        IERC20(essence).transfer(
            msg.sender,
            getRewardsByTokenId(tokenId)
        );

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    function claimAll() public {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards = totalRewards + getRewardsByTokenId(tokenIds[i]);
            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        IERC20(essence).transfer(msg.sender, totalRewards);
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards = totalRewards + getRewardsByTokenId(tokenIds[i]);
        }

        return totalRewards;
    }

    function getRewardsByTokenId(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        require(
            tokenIdToStaker[tokenId] != NULL_ADDRESS,
            "Token is not staked!"
        );
        
        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[tokenId];
        if(block.timestamp > endTime){
            secondsStaked = endTime - tokenIdToTimeStamp[tokenId];
        }
        return secondsStaked * EMISSION_RATE;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        IERC721Enumerable iBabyDraco = IERC721Enumerable(babyDraco);
        uint256 tokenCount = iBabyDraco.balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = iBabyDraco.tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
}