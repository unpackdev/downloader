// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";

contract Carrotz is ERC20Burnable, Ownable {

    using SafeMath for uint256;


    uint256 public EMISSIONS_RATE = 11574070000000;
                                    
                                    
    uint256 public MAX_SUPPLY = 1000000000000000000000000;
    address nullAddress = 0x0000000000000000000000000000000000000000;

    address public bunzAddress;

    
    mapping(uint256 => uint256) internal tokenIdToTimeStamp;

    
    mapping(uint256 => address) internal tokenIdToStaker;

    
    mapping(address => uint256[]) internal stakerToTokenIds;

    constructor() ERC20("Carrotz", "CARROTZ") {}

    function setBunzAddress(address _bunzAddress) public onlyOwner {
        bunzAddress = _bunzAddress;
        return;
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
    
    function setMaxSupply(uint256 newMaxSupply) public onlyOwner {
        MAX_SUPPLY = newMaxSupply;
        return;
    }

    function stakeByIds(uint256[] memory tokenIds) public {


        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(bunzAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress,
                "Token must be stakable by you!"
            );

            IERC721(bunzAddress).transferFrom(
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

            IERC721(bunzAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenId]) *
                    EMISSIONS_RATE);

            removeTokenIdFromStaker(msg.sender, tokenId);

            tokenIdToStaker[tokenId] = nullAddress;
        }
        if (totalSupply() + totalRewards <= MAX_SUPPLY){
            _mint(msg.sender, totalRewards);    
        }
        else if (totalSupply() < MAX_SUPPLY){
            _mint(msg.sender, MAX_SUPPLY-totalSupply());   
        }
        
    }

    function unstakeByIds(uint256[] memory tokenIds) public {
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Message Sender was not original staker!"
            );

            IERC721(bunzAddress).transferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);

            removeTokenIdFromStaker(msg.sender, tokenIds[i]);

            tokenIdToStaker[tokenIds[i]] = nullAddress;
        }

        if (totalSupply() + totalRewards <= MAX_SUPPLY){
            _mint(msg.sender, totalRewards);    
        }
        else if (totalSupply() < MAX_SUPPLY){
            _mint(msg.sender, MAX_SUPPLY-totalSupply());   
        }
    }

    function claimByTokenId(uint256 tokenId) public {
        require(
            tokenIdToStaker[tokenId] == msg.sender,
            "Token is not claimable by you!"
        );
        uint256 totalRewards;
        totalRewards = (block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE;
        if (totalSupply() + totalRewards <= MAX_SUPPLY){
                
            tokenIdToTimeStamp[tokenId] = block.timestamp;
            _mint(msg.sender, totalRewards);   
        }
        else if (totalSupply() < MAX_SUPPLY){
            _mint(msg.sender, MAX_SUPPLY-totalSupply());   
        }

        
    }
    
    function emergencyMint(uint count) public onlyOwner {
        _mint(msg.sender, count);
    }

    function claimAll() public {
        
        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Token is not claimable by you!"
            );

            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
        }

        if (totalSupply() + totalRewards <= MAX_SUPPLY){
                
            _mint(msg.sender, totalRewards);   
        }
        else if (totalSupply() < MAX_SUPPLY){
            _mint(msg.sender, MAX_SUPPLY-totalSupply());   
        }
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[staker];
        uint256 totalRewards = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            totalRewards =
                totalRewards +
                ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) *
                    EMISSIONS_RATE);
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

        return secondsStaked * EMISSIONS_RATE;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }
}