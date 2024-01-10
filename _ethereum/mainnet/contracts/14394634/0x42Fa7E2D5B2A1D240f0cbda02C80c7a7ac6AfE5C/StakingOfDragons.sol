// SPDX-License-Identifier: MIT


pragma solidity ^0.8.2;

import "./ERC721Holder.sol";
import "./EggToken.sol";
import "./DenOfDragons.sol";

contract StakingOfDragons is ERC721Holder {

    address public developer;
    address public stakingContract = address(this);
    mapping(address => bool) internal contractManager;
    mapping(address => bool) internal burnerAddress;

    mapping(uint256 => address) public originalOwner;  //remebers who's nft this is
    mapping(address => uint256) public stakedNFTCount;  //stake counter
    mapping(address => uint256[]) internal stakedNFTs;

    string public _name = "StakingOfDragons";  //beautiful branding built right in
    string public _symbol = "SOD";

    DenOfDragons public denOfDragons;
    EggToken public eggToken;

    //events
    event Stake(address indexed from, uint256 amount);
    event Unstake(address indexed from, uint256 amount);

    constructor(DenOfDragons _denOfDragons, EggToken _eggToken) {
        
        denOfDragons = _denOfDragons;
        eggToken = _eggToken;

        developer = msg.sender;
    }


    //function burnTokenAfterNftTransfer(uint256 _nftId) public {
    //    require(burnerAddress[msg.sender] == true);
    //    uint256 token = eggToken.linkedNft(_nftId);
    //    eggToken.burn(token);
    //}

    //function setAutoBurnerAddress(address _address) public {
    //    require(contractManager[msg.sender] == true || msg.sender == developer);
    //    burnerAddress[_address] = true;
    //}

    /// Core functions
    function stake(uint256 _nftId) public {
        require(!isStaked[_nftId], "Token is already staked"); //cant double stake silly ;)
        address nftOwner = denOfDragons.ownerOf(_nftId); //calls the club for owner
        require(nftOwner == msg.sender); 
        denOfDragons.safeTransferFrom(msg.sender, address(this), _nftId);  //transfers token from user to stake contract                                                                                  
        originalOwner[_nftId] = msg.sender; //makes sure it knows who to give back to
        stakedNFTCount[msg.sender] ++; //adds 1 to the tally
        emit Stake(msg.sender, _nftId); //WOOO you did it!
        stakedNFTs[msg.sender].push(_nftId);
        startTimer(_nftId);
    }

    function unstake(uint256 _nftId) public {
        require(isStaked[_nftId], "Token is not staked");  //uh oh, you forgot to stake :O
        require(originalOwner[_nftId] == msg.sender, "You dont own this NFT");  //...nice try
        endTimer(_nftId);
        denOfDragons.safeTransferFrom(address(this), msg.sender, _nftId); //heres your NFT back homie!
        stakedNFTCount[msg.sender] --;
        mintTokenInternal((stakedTime[_nftId] * (10 ** 18)) / 86400);
        for (uint256 i = 0; i < stakedNFTs[msg.sender].length; i++) {
            uint256 id = stakedNFTs[msg.sender][i];
            if (id == _nftId) {
                stakedNFTs[msg.sender][i] = stakedNFTs[msg.sender][stakedNFTs[msg.sender].length - 1];
                stakedNFTs[msg.sender].pop();
                break;
            }
        }
        emit Unstake(msg.sender, _nftId);
    }

    function mintTokenInternal(uint256 _reward) internal {
        eggToken.mint(msg.sender, _reward); 
    }
    
    function getStakedNFTs(address _address) public view returns(uint256[] memory) {
        return(stakedNFTs[_address]);
    }

    function viewTrueTokenBalance(address _address) public view returns (uint256) {
        uint256 tokenBal = rewardOwned(_address);
        uint combinedSecsStaked = 0;
        for (uint256 i = 0; i < stakedNFTs[_address].length; i++) {
            uint256 id = stakedNFTs[_address][i];
            combinedSecsStaked = combinedSecsStaked + viewStakedTime(id);
        }
        uint256 combinedReward = (combinedSecsStaked * (10 ** 18)) / 86400;
        return(tokenBal + combinedReward);
    }

    //Timer
    mapping(address => bool) internal timerManager;

    mapping(uint256 => uint) public startTime;   //for calculating rewards
    mapping(uint256 => uint) public endTime;
    mapping(uint256 => uint) internal stakedTime;
    mapping(uint256 => bool) public isStaked;
    mapping(uint256 => bool) public hasBeenStaked;

    function startTimer (uint256 _tokenId) internal {
        require(isStaked[_tokenId] == false, "Token is already staked");
        startTime[_tokenId] = block.timestamp;
        isStaked[_tokenId] = true;
        hasBeenStaked[_tokenId] = true;
    }

    function endTimer (uint256 _tokenId) internal {
        require(isStaked[_tokenId] == true, "Token is not staked");
        endTime[_tokenId] = block.timestamp;
        isStaked[_tokenId] = false;
        math(_tokenId);
    }

    function math (uint256 _tokenId) internal {
        stakedTime[_tokenId] = (endTime[_tokenId] - startTime[_tokenId]);
    }


    function viewStakedTime (uint256 _tokenId) public view returns (uint) {
        if (isStaked[_tokenId] == false){
            if (hasBeenStaked[_tokenId] == false){
                return(0);
            }
            else {
                return(stakedTime[_tokenId]);
            }
        }
        else {
            uint stakedTimeV = (block.timestamp - startTime[_tokenId]);
            return(stakedTimeV);
        }
    }
    //End of timer

    function supplyOfReward () public view returns (uint256) {
        uint256 tokens = eggToken.totalSupply();
        return(tokens);
    }

    function rewardOwned(address _address) public view returns (uint256) {
        uint256 tokens = eggToken.balanceOf(_address);
        return(tokens);
    }


    function resetTokenStats (uint256 _tokenId) public {
        require(msg.sender == stakingContract || timerManager[msg.sender] == true , "You are not Contract Manager");
        startTime[_tokenId] = 0;
        endTime[_tokenId] = 0;
        stakedTime[_tokenId] = 0;
        isStaked[_tokenId] = false;
        hasBeenStaked[_tokenId] = false;
    }


    function addContractManager (address _address) public {
        require(msg.sender == developer);
        timerManager[_address] = true;
    }

    function removeContractManager (address _address) public {
        require(msg.sender == developer);
        timerManager[_address] = false;
    }


    function transferControl (address _newDeveloper) public {
        require(msg.sender == developer);
        developer = _newDeveloper;
    }

}