// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

/**                                                              
                                          .::::.                                          
                                      -+*########*+-                                      
                                   .=################=.                                   
                                 .=######*=-::-=++++++=:                                  
                      ......   .=######+.  .........................                      
                 .-+*#####+. .=######+. .=###########################*+-.                 
                =#######+. .=######+. .=#################################=                
               +*****+=. .=******+.  .-----------------------------=+*****+               
              -*****:  .=******+.                          :::::::.  :*****-              
              =*****  -******=.                            .=******=. .+***=              
              :*****-                                        .=******=. .+*:              
               =******+++++++++++==-:.              .:-==+++=. .=******=. .               
                :*********************+:          :+**********=. .=******=.               
             .=-  :-+*******************-        -**************=. .=******=.             
           .=****=:                =*****        *****=              .=******=.           
         .=******=.                .*****.      .*****.                .=******=.         
        =******=.                  .*****.      .*****.                  .=******=        
      :******=.                    .*****.      .*****.                    .=******:      
     :*****+.                      .*****.      .*****.                      .+*****:     
     +****=                        .*****.      .*****.                        =****+     
    .*****.                        .*****.      .*****.                        .*****.    
    .*****:                        .*****.      .*****.                        :*****.    
     =****+.                       .*****.      .*****.                       .+****=     
      +****+-                      .*****.      .*****.                      -+****+      
       =*****+-                    .*****.      .*****.                    -+*****=       
        .=*****+-                  .*****.      .*****.                  -+*****=.        
          .=*****+-                .*****.      .*****.                -+*****=.          
            .=++++++-              .+++++.      .+++++.              -++++++=.            
              .=++++++-            .+++++.      .+++++.            -++++++=.              
                .=++++++-          .+++++.      .+++++.          -++++++=.                
                  .=++++++-        .+++++.      .+++++.        -++++++=.                  
                    .=++++++-      .+++++.      .+++++.      -++++++=.                    
                      .=++++++-     +++++=      =+++++     -++++++=.                      
                        .=++++++-   :+++++-    -+++++:   -++++++=.                        
                          .=++++++-  .::::.  :++++++-  -++++++=.                          
                            .=++++++=-::::-=+++++++:  =+++++=.                            
                              .=+++++++++++++++++:  :+++++=.                              
                                 :=++++++++++=-.  :++++=:                                 
                                     ......      ....
 */

import "./Ownable.sol";
import "./Context.sol";
import "./IERC721.sol";

interface SoarProofInterface is IERC721 {
    function tokenToLevel(uint16 _tokenId) external returns(uint8);
}

contract SoarProofEarn is Context, Ownable {

    uint16 constant MAX_STAGE_ID = 10;
    uint256 constant public startTime = 1658577600; // 2022-07-23 12:00:00 (UTC)
    uint256 constant public stagePerPeriod = 60 * 60 * 24 * 10; // 60 (sec) * 60 (min/hr) * 24 (hr/day) * 10  = 10 Days

    uint256 constant public BaseReward = 0.65 ether;
    uint256 constant public LevelThreeReward = 0.1950 ether; // 0.65 * 30% = 0.1950
    uint256 constant public LevelTwoReward   = 0.1300 ether; // 0.65 * 20% = 0.1300
    uint256 constant public LevelOneReward   = 0.0975 ether; // 0.65 * 15% = 0.0975

    SoarProofInterface SoarProof;
    bool isOnlyCanClaimLatestStage = false;

    event Claimed(address indexed own, uint16 indexed stageId, uint8 indexed level, uint256 value);

    constructor() {
        setSoarProof(0xF2A9E0A3729cd09B6E2B23dcBB1192dBaAB06E15);
    }

    // stageToClaimedMap[%STAGE_ID%][%TOKEN_ID%] => is claimed
    mapping(uint16 => mapping(uint16 => bool)) stageToClaimedMap;

    function calculateRewardTime(uint16 _stageId) public pure returns(uint256) {
        return startTime + (_stageId * stagePerPeriod);
    }

    function latestStageId() public view returns(uint16) {
        for(uint16 stageId = MAX_STAGE_ID; stageId > 0; stageId--) {
            if(block.timestamp > calculateRewardTime(stageId)) {
                return stageId;
            }
        }
        return 0;
    }

    function claim(uint16 _stageId, uint16 _tokenId) external {
        require(_stageId > 0 && _stageId <= MAX_STAGE_ID, "Stage ID is invalid");
        
        uint256 validTime = calculateRewardTime(_stageId);
        bool isClaimed = stageToClaimedMap[_stageId][_tokenId];
        address holder = SoarProof.ownerOf(_tokenId);
        uint8 level = SoarProof.tokenToLevel(_tokenId);

        require(block.timestamp > validTime, "Claim Time not yet reached");
        require(!isClaimed, "The token have been claimed");
        require(holder == _msgSender(), "you are not the SoarProof holder");
        require(level > 0 && level < 4, "level is invalid");

        if(isOnlyCanClaimLatestStage) {
            require(latestStageId() == _stageId, "only can claim latest stage");
        }
    
        stageToClaimedMap[_stageId][_tokenId] = true;
        uint256 reward;
        if(level == 1) {
            reward = LevelOneReward;
        } else if(level == 2) {
            reward = LevelTwoReward;
        } else if(level == 3) {
            reward = LevelThreeReward;
        }
        (bool scc, ) = payable(holder).call{value: reward}("");
        require(scc, "cannot claim");
        emit Claimed(holder, _tokenId, level, reward);
    }

    function setSoarProof(address _addr) public onlyOwner {
        SoarProof = SoarProofInterface(_addr);
    }

    function setOnlyCanClaimLatestStage(bool _t) external onlyOwner {
        isOnlyCanClaimLatestStage = _t;
    }

    fallback() payable external {}
    receive() payable external {}
}
