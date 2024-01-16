// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
              :~7J5PGGGGGGGGGGGGGGG^  JGGGGGGG^ :GGGGPPY?!^.                            
          .!5B&DIDDIDDIDDIDDIDDIDID~  PDIDDIDD^ ^DIDDIDDIDD#GJ^                         
        :Y#DIDDIDDIDDIDDIDDIDDIDDID~  PDIDDIDD^ ^DIDDIDDIDDIDIDG7                       
       ?&DIDDIDID&BPYJJJJJJBDIDDIDD~  !JJJJJJJ: .JJJY5G#DIDDIDDIDG^                     
      YDIDDIDIDP!:         PDIDDIDD~                   .^J#DIDDIDD&~                    
     ?DIDDIDD&!            PDIDDIDD~  JGPPPPGG^           .5DIDDIDD#.                   
    .BDIDDIDD!             PDIDDIDD~  PDIDDIDD~             PDIDDIDD?                   
    ^&DIDDIDB.             PDIDDIDD~  PDIDDIDD~             7DIDDIDD5                   
    :&DIDDID#.             PDIDDIDD~  PDIDDIDD~             ?DIDDIDD5                   
     GDIDDIDDJ             PDIDDIDD~  PDIDDIDD~            .BDIDDIDD7                   
     ~DIDDIDIDY.           !???????:  PDIDDIDD~           ~BDIDDIDDP                    
      7DIDDIDID&5!^.                  PDIDDIDD~      .:~?GDIDDIDIDG.                    
       ^GDIDDIDDIDD#BGGGGGGGGGGGGGG^  PDIDDIDDBGGGGGB#&DIDDIDDID&J.                     
         !P&DIDDIDDIDDIDDIDDIDDIDID~  PDIDDIDDIDDIDDIDDIDDIDID#J:                       
           :7YG#DIDDIDDIDDIDDIDDIDD~  PDIDDIDDIDDIDDIDDID&#PJ~.                         
               .^~!??JJJJJJJJJJJJJJ:  !JJJJJJJJJJJJJJ?7!^:.                             
                                                                                                   
**/

contract RegistrationPool is Ownable, Pausable, ReentrancyGuard{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event OtherTokensWithdrawn(address indexed currency, uint256 amount);

    event RewardClaimed(address indexed receiver, uint256 indexed amount);

    struct UserReward{
        mapping(uint256=>uint256) rewardPoints;
        mapping(uint256=>bool) rewardClaimed;
    }

    mapping(address => UserReward) userToRewardData;
    mapping(uint256 => bool) public ifRewardDistributed;
    mapping(uint256 => bool) public canClaim;
    mapping(uint256 => uint256) public totalPoints;
    mapping(uint256 => uint256) public roundRewards;
    

    uint256 public InitialBlock;
    uint256 public currentRound;
    uint256 public NumBlocksPerRound;
    uint256 public lastRewardBlock;
    address public DistributorContract;
    address public DIDRegister;
    IERC20 public DegenIDToken;

    constructor(
        address _tokenAddr,
        address _distributor,
        uint256 _numBlocks
    ){
        DegenIDToken = IERC20(_tokenAddr);
        NumBlocksPerRound = _numBlocks;
        DistributorContract = _distributor;
    }

    function setNumBlock(uint256 _blocks) public onlyOwner {
        NumBlocksPerRound = _blocks;
    }

    function initalizePool(uint256 blockNum, uint256 reward) external {
        require(msg.sender == DistributorContract || msg.sender == owner(), "Unauthorized");
        InitialBlock = blockNum;
        lastRewardBlock = blockNum;
        roundRewards[0] = reward;
    }

    function setDIDRegister(address _register) public onlyOwner {
		DIDRegister = _register;
	}

    function deliverReward(uint256 round, uint256 amount) external {
        require(msg.sender == DistributorContract || msg.sender == owner(), "Unauthorized");
        require(!ifRewardDistributed[currentRound], "Rewards Delivered");
        ifRewardDistributed[currentRound] = true;
        roundRewards[round] = amount;
    }

    function gainPonts(address receiver, uint256 point) external returns(uint256) {
        require(msg.sender == DIDRegister || msg.sender == owner(), "Unauthorized");
        UserReward storage user = userToRewardData[receiver];
        if(block.number <= lastRewardBlock + NumBlocksPerRound) {
            user.rewardPoints[currentRound] = user.rewardPoints[currentRound] + point;
            totalPoints[currentRound] = totalPoints[currentRound] + point; 
        } else{
            user.rewardPoints[currentRound+1] = user.rewardPoints[currentRound+1] + point;
            totalPoints[currentRound+1] = totalPoints[currentRound+1] + point; 
        }
        
        return totalPoints[currentRound];
    }

    function startClaim() public onlyOwner {
        require(block.number >= lastRewardBlock + NumBlocksPerRound, "Cannot claim yet");
        require(!canClaim[currentRound], "Claim started already");
        require(ifRewardDistributed[currentRound], "Rewards not deliver");
        canClaim[currentRound] = true;
        currentRound++;
        lastRewardBlock = lastRewardBlock + NumBlocksPerRound;
    }

    function claimRewards(uint256 round) public {
        require(canClaim[round], "Cannot claim this round");
        UserReward storage user = userToRewardData[msg.sender];
        require(!user.rewardClaimed[round], "Claimed already");
        uint256 shares = _calculateShare(msg.sender, round);
        DegenIDToken.safeTransfer(msg.sender, shares);

        user.rewardClaimed[round] = true;
        emit RewardClaimed(msg.sender, shares);
    }

    function calculateShare(address user, uint256 round) public view returns(uint256){
        return _calculateShare(user, round);
    }

    function _calculateShare(address addr, uint256 round) internal view returns(uint256){
        uint256 DIDTokenAmount = roundRewards[round];
        UserReward storage user = userToRewardData[addr];
        if(!user.rewardClaimed[round]) {
            return DIDTokenAmount*user.rewardPoints[round]/totalPoints[round];
        }else {
            return 0;
        }
        
    }

    function getUserReward(address addr, uint256 round) public view returns(
        uint256 points,
        bool ifClaimed
    ){
        UserReward storage user = userToRewardData[addr];
        points = user.rewardPoints[round];
        ifClaimed = user.rewardClaimed[round];
    }

    receive() external payable {}

    fallback() external payable {}

    function mutipleSendETH(
        address[] memory receivers,
        uint256[] memory ethValues
    ) public nonReentrant onlyOwner {
        require(receivers.length == ethValues.length);
        for (uint256 i = 0; i < receivers.length; i++) {
            bool sent = payable(receivers[i]).send(ethValues[i]);
            require(sent, "Failed to send Ether");
        }
    }

    function withdrawOtherCurrency(address _currency)
        external
        nonReentrant
        onlyOwner
    {
        require(
            _currency != address(DegenIDToken),
            "Owner: Cannot withdraw $DID"
        );

        uint256 balanceToWithdraw = IERC20(_currency).balanceOf(address(this));

        // Transfer token to owner if not null
        require(balanceToWithdraw != 0, "Owner: Nothing to withdraw");
        IERC20(_currency).safeTransfer(msg.sender, balanceToWithdraw);

        emit OtherTokensWithdrawn(_currency, balanceToWithdraw);
    }
}