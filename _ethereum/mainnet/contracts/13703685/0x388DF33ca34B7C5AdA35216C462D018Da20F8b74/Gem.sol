// contracts/Cheeth.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";

contract Gem is ERC20Burnable, Ownable {

    uint256 public constant MAX_WALLET_STAKED = 10;
    uint256 public constant EMISSION_RATE = uint256(40 * 1e18) / 86400;
    // 40 GEM / Draco / 86400

    uint256 public constant TREASURY_SUPPLY = 1000000 * 1e18;
    uint256 public endTime = 2000000000; // Wednesday, 18 May 2033 03:33:20
    uint256 public constant STAKING_START = 1638248400; // Tuesday, 30 November 2021 05:00:00 GMT
    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public cocoDracoAddress;

    //Mapping of draco to timestamp
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    //Mapping of draco to staker
    mapping(uint256 => address) internal tokenIdToStaker;

    //Mapping of staker to draco
    mapping(address => uint256[]) internal stakerToTokenIds;

    modifier onlyDracoAddress() {
        require(msg.sender == cocoDracoAddress, "Not draco address");
        _;
    }
    
    constructor() ERC20("Gem", "GEM") {
        _mint(msg.sender, TREASURY_SUPPLY);
    }

    function setCocoDracoAddress(address _cocoDracoAddress) public onlyOwner {
        cocoDracoAddress = _cocoDracoAddress;
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
            "Max 10 staked draco"
        );

        require(block.timestamp >= STAKING_START, "Stake not started");
        require(block.timestamp <= endTime , "Stake ended");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(cocoDracoAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721(cocoDracoAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeAll() public {
        require(
            stakerToTokenIds[msg.sender].length > 0,
            "Must have at least one token staked!"
        );
        uint256 totalRewards = 0;

        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

            IERC721(cocoDracoAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            totalRewards = totalRewards + getRewardsByTokenId(tokenId);

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(cocoDracoAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards = totalRewards + getRewardsByTokenId(tokenIds[i]);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = nullAddress;
        }

        _mint(msg.sender, totalRewards);
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );
        
        _mint(
            msg.sender,
            getRewardsByTokenId(tokenId)
        );

        tokenIdToTimeStamp[tokenId] = block.timestamp;
    }

    function claimAll() public {
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            totalRewards = totalRewards + getRewardsByTokenId(tokenIds[i]);
            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        _mint(msg.sender, totalRewards);
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
            tokenIdToStaker[tokenId] != nullAddress,
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

    function burn(address _user, uint256 _amount) public onlyDracoAddress {
        _burn(_user, _amount);
    }
}