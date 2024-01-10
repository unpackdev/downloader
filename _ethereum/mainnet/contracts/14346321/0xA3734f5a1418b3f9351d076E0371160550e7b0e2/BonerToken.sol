// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";

contract BonerToken is ERC20, Ownable {
    
    uint256 public constant MAX_WALLET_STAKED = 10;
    uint256 public constant EMISSION_RATE = uint256(2 * 1e18) / 86400;
    // 2 BONER / TASM / 86400

    uint256 public constant TOTAL_SUPPLY = 1000000 * 1e18;
    uint256 public constant TREASURY_SUPPLY = 200000 * 1e18;
    uint256 public endTime = 2000000000; // Wednesday, 18 May 2033 03:33:20
    address public constant NULL_ADDRESS = 0x0000000000000000000000000000000000000000;
     
    address public tasmAddress;
    bool public stakingStart = false;
   
    //Mapping of TASM to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    //Mapping of TASM to staker
    mapping(uint256 => address) internal tokenIdToStaker;

    //Mapping of staker to TASM
    mapping(address => uint256[]) internal stakerToTokenIds;
    
    constructor() ERC20("Boner", "BONER") {
        _mint(msg.sender, TREASURY_SUPPLY);
    }

    function setTasmAddress(address _tasmAddress) public onlyOwner {
        tasmAddress = _tasmAddress;
    }

    function setStakingStart(bool _stakingStart) public onlyOwner {
        stakingStart = _stakingStart;
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
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
        uint256 tokenCount = IERC721(tasmAddress).balanceOf(staker);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = IERC721Enumerable(tasmAddress).tokenOfOwnerByIndex(staker, i);
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

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(tasmAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == NULL_ADDRESS,
                "Token must be stakable by you!"
            );

            IERC721(tasmAddress).transferFrom(
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

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(tasmAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards = totalRewards + getRewardsByTokenId(tokenIds[i]);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = NULL_ADDRESS;
        }

        _mint(msg.sender, calcRemaining(totalRewards));
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );

        _mint(
            msg.sender,
            calcRemaining(getRewardsByTokenId(tokenId))
        );

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    function calcRemaining(uint256 rewards) private view returns (uint256) {
        if(rewards + totalSupply() > TOTAL_SUPPLY){
            return TOTAL_SUPPLY - totalSupply();
        } else {
            return rewards;
        }
    }

    function claimAll() public {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards = totalRewards + getRewardsByTokenId(tokenIds[i]);
            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, calcRemaining(totalRewards));
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards = totalRewards + getRewardsByTokenId(tokenIds[i]);
        }

        return calcRemaining(totalRewards);
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
}