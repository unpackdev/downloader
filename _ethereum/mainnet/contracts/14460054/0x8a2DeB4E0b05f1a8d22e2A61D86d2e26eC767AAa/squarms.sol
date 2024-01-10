// SPDX-License-Identifier: MIT
/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,.........................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@....................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@....................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@,...................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.................@,................@@.........@@...
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@......@.........@@..................@@......*@.....
@@@@@@@@@@@@@@@@@@@@@#..%@@@@........@@@@@@@@........................@@@........
@@@@@@@@@@@@@@@@................................................................
@@@@@@@@@@@@@@..................................................................
@@@@@@@@@@@@@...................................................................
@@@@@@@@@@@@@...................................................................
@@@@@@@@@@@@@@................................@@..............@&................
@@@@@@@@@@@@@@@@.................................@@@@@...@@@@...................
@@@@@@@@@@@@@@@@@@@@@@@@@@@.....................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@....................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@....................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...................................................
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@...................................................


 / ____|                                                         
 | (___     __ _   _   _    __ _   _ __   _ __ ___    ___ 
  \___ \   / _` | | | | |  / _` | | '__| | '_ ` _ \  / __|
  ____) | | (_| | | |_| | | (_| | | |    | | | | | | \__ \
 |_____/   \__, |  \__,_|  \__,_| |_|    |_| |_| |_| |___/
         |_| 
*/
pragma solidity >=0.8.9 <0.9.10;

import "./ERC20Burnable.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";

contract SQUARMS is ERC20Burnable, Ownable {

    uint256 public MAX_WALLET_STAKED = 5;
    uint256 public EMISSIONS_RATE =11580000000000;
    uint256 public CLAIM_END_TIME;
    uint256 public STAKE_DURATION = 0;
    address nullAddress = address(0);
    address public squarmiesAddress;
    bool public paused = false;
    bool public isLate = false;

    mapping(uint256 => uint256) internal tokenIdToTimeStamp;
    mapping(uint256 => address) internal tokenIdToStaker;
    mapping(address => uint256) internal addressToTimeStamp;
    mapping(address => uint256[]) internal stakerToTokenIds;


    constructor() ERC20("Squarms", "SQUARMS") {

        _mint( msg.sender, 15000 ether);
    }

//getters
    function getTokensStaked(address staker)
        public
        view
        returns (uint256[] memory)
    {
        return stakerToTokenIds[staker];
    }

    function getTokenTime (uint256 tokenId) public view 
    returns (uint256) {
        return tokenIdToTimeStamp[tokenId];
    }

    function getTimeStaked (address squarfam) public view returns (uint256) {
        return addressToTimeStamp[squarfam];
    }

    function getTimeLeft (address squarfam) public view returns (uint256) {
        return addressToTimeStamp[squarfam] + STAKE_DURATION;
    }

       function getStaker(uint256 tokenId) public view returns (address) {
        return tokenIdToStaker[tokenId];
    }

     function getAllRewards(address squarfam) public view returns (uint256) {
        uint256[] memory tokenIds = stakerToTokenIds[squarfam];
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
            "Squarmies is not staked!"
        );

        uint256 secondsStaked = block.timestamp - tokenIdToTimeStamp[tokenId];

        return secondsStaked * EMISSIONS_RATE;
    }



//stake now!!
    function stakeSquarmies(uint256[] memory tokenIds) public {
        require(
            stakerToTokenIds[msg.sender].length + tokenIds.length <=
                MAX_WALLET_STAKED,
            "You've reached max staked"
        );
        require(!paused);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                IERC721(squarmiesAddress).ownerOf(tokenIds[i]) == msg.sender &&
                    tokenIdToStaker[tokenIds[i]] == nullAddress, "You dont own this token");

            IERC721(squarmiesAddress).transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );

            stakerToTokenIds[msg.sender].push(tokenIds[i]);

            tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
            addressToTimeStamp[msg.sender] = block.timestamp;
            tokenIdToStaker[tokenIds[i]] = msg.sender;
        }
    }

    function unstakeAllSquarmies() public {
        require(stakerToTokenIds[msg.sender].length > 0, "Must have at least > 1 staked");
       require(addressToTimeStamp[msg.sender] >= addressToTimeStamp[msg.sender]+ STAKE_DURATION);
       require(!paused);

        uint256 totalRewards = 0;


        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

                   IERC721(squarmiesAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            totalRewards = totalRewards + ((block.timestamp - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE);
            removeTokenIdFromStaker(msg.sender, tokenId);
            addressToTimeStamp[msg.sender] = block.timestamp;

             tokenIdToStaker[tokenId] = nullAddress;
             _mint(msg.sender, totalRewards);

              }
    }

  function unstakeLateSquarmies() public {
        require(stakerToTokenIds[msg.sender].length > 0, "Must have at least > 1 staked");
       require(isLate);

        uint256 totalRewards = 0;


        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

                   IERC721(squarmiesAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            totalRewards = totalRewards + ((CLAIM_END_TIME - tokenIdToTimeStamp[tokenId]) * EMISSIONS_RATE);
            removeTokenIdFromStaker(msg.sender, tokenId);
            addressToTimeStamp[msg.sender] = block.timestamp;

             tokenIdToStaker[tokenId] = nullAddress;
             _mint(msg.sender, totalRewards);
              }
    }

    function claimAll() public {
        require(block.timestamp < CLAIM_END_TIME, "Claim cycle has ended");
       require(addressToTimeStamp[msg.sender] >= addressToTimeStamp[msg.sender]+ STAKE_DURATION);
        require(!paused);

        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;
        
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                tokenIdToStaker[tokenIds[i]] == msg.sender,
                "Squarmies is not yours to claim"
            );

              totalRewards = totalRewards + ((block.timestamp - tokenIdToTimeStamp[tokenIds[i]]) * EMISSIONS_RATE);
             tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
           addressToTimeStamp[msg.sender] = block.timestamp;
         
        } _mint(msg.sender, totalRewards);
    }

  function claimAllLate() public {
       require(isLate);

        uint256[] memory tokenIds = stakerToTokenIds[msg.sender];
        uint256 totalRewards = 0;
  
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require( tokenIdToStaker[tokenIds[i]] == msg.sender,"Squarmies is not yours to claim");
              totalRewards = totalRewards + ((CLAIM_END_TIME - tokenIdToTimeStamp[tokenIds[i]]) * EMISSIONS_RATE);
             tokenIdToTimeStamp[tokenIds[i]] = block.timestamp;
           addressToTimeStamp[msg.sender] = block.timestamp;
        }
         _mint(msg.sender, totalRewards);
    }

    // owner only
    function setMaxStaked (uint _stakeMax) public onlyOwner {
       MAX_WALLET_STAKED = _stakeMax;
    }

    function setStakeDuration (uint _stakeDuration) public onlyOwner {
        STAKE_DURATION = _stakeDuration * 1 days;
    }

 function setLateBool(bool _state) public onlyOwner {
        isLate = _state;
    }

     function setPaused(bool _state) public onlyOwner {
         paused = _state;
    }

function setClaimCycle (uint256 _claimTime) public onlyOwner {
    CLAIM_END_TIME = _claimTime;
    }

    function setEmission (uint256 _rate) public onlyOwner {
        EMISSIONS_RATE = _rate; 
        }

    function setAddress(address _squarmiesAddress) public onlyOwner
    { squarmiesAddress = _squarmiesAddress; 
    }

 // squarmergency only, no rewards
 function emergencyWithdraw() public {
        require(stakerToTokenIds[msg.sender].length > 0, "Must have at least > 1 staked");
        for (uint256 i = stakerToTokenIds[msg.sender].length; i > 0; i--) {
            uint256 tokenId = stakerToTokenIds[msg.sender][i - 1];

                   IERC721(squarmiesAddress).transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            removeTokenIdFromStaker(msg.sender, tokenId);
            addressToTimeStamp[msg.sender] = block.timestamp;
             tokenIdToStaker[tokenId] = nullAddress;

              }
              
 } 

     function removeSquarmies(address staker, uint256 index) internal {
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
                removeSquarmies(staker, i);
            }
        }
    }

}

