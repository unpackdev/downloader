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

contract StakingPool is Ownable, Pausable, ReentrancyGuard{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event OtherTokensWithdrawn(address indexed currency, uint256 amount);

    event TokenStaked(uint256 poolIndex, uint256 indexed amount);
    event TokenUnstaked(uint256 poolIndex, uint256 indexed amount);
    event RewardClaimed(uint256 poolIndex, uint256 round, uint256 indexed rewards);

    struct UserData {
        uint256[2] tokenStaked;
        uint256[2] actualShare;
        mapping(uint256=>bool[2]) rewardClaimed;
    }

    mapping(address=>UserData) userData;
    mapping(uint256 => bool[2]) public ifDistributed;
    mapping(uint256 => bool) public canClaim;
    uint256[2] public totalStaked; 
    uint256[2] public totalShares;
    mapping(uint256 => uint256[2]) public roundRewards;
    

    uint256 public InitialBlock;
    uint256 public currentRound;
    uint256 public NumBlocksPerRound;
    uint256 public lastRewardBlock;
    address public DistributorContract;
    address public BuyBackContract;
    IERC20 public DegenIDToken;

    constructor(
        address _tokenAddr,
        address _distributor,
        uint256 _numBlocks
    ) {
        DegenIDToken = IERC20(_tokenAddr);
        NumBlocksPerRound = _numBlocks;
        DistributorContract = _distributor;
    }

    function setNumBlock(uint256 _blocks) public onlyOwner {
        NumBlocksPerRound = _blocks;
    }

    function initalizePool(uint256 blockNum) external {
        require(msg.sender == DistributorContract || msg.sender == owner(), "Unauthorized");
        InitialBlock = blockNum;
        lastRewardBlock = blockNum;
    }

    function setBuyBackPool(address _buyback) public onlyOwner {
        BuyBackContract = _buyback;
    }

    function deliverReward(uint256 round, uint256 index, uint256 amount) external {
        require(index <= 1);
        require(msg.sender == DistributorContract || msg.sender == BuyBackContract || msg.sender == owner(), "Unauthorized");
        require(!ifDistributed[currentRound][index], "Rewards Delivered");
        ifDistributed[currentRound][index] = true;
        roundRewards[round][index] = amount;
    }

    function stake(uint256 index, uint256 amount) public {
        require(index <= 1);
        require(InitialBlock != 0, "Wait for initializing");
        require(DegenIDToken.balanceOf(msg.sender) >= amount, "Insufficient $DID");
        require(lastRewardBlock + NumBlocksPerRound >= block.number, "Wait for distribution");
        uint256 weightedShare = amount*(lastRewardBlock + NumBlocksPerRound - block.number)/NumBlocksPerRound;
        UserData storage data = userData[msg.sender];
        DegenIDToken.safeTransferFrom(msg.sender,address(this), amount);
        data.tokenStaked[index] = data.tokenStaked[index] + amount;
        data.actualShare[index] = data.actualShare[index] + weightedShare;

        totalStaked[index] = totalStaked[index] + amount;
        totalShares[index] = totalShares[index] + weightedShare;
        
        emit TokenStaked(index, amount);
    }

    function withdraw(uint256 index, uint256 amount) public {
        require(index <= 1);
        require(InitialBlock != 0, "Wait for initializing");
        UserData storage data = userData[msg.sender];
        require(data.tokenStaked[index] >= amount, "Insufficient staked $DID");
        require(lastRewardBlock + NumBlocksPerRound >= block.number, "Waiting for distribution");
        uint256 weightedShare = amount*(lastRewardBlock + NumBlocksPerRound - block.number)/NumBlocksPerRound;
        DegenIDToken.safeTransfer(msg.sender, amount);
        data.tokenStaked[index] = data.tokenStaked[index] - amount;
        data.actualShare[index] = data.actualShare[index] - weightedShare;

        totalStaked[index] = totalStaked[index] - amount;
        totalShares[index] = totalShares[index] - weightedShare;

        emit TokenUnstaked(index, amount);
    }

    function startClaim() public onlyOwner {
        require(block.number >= lastRewardBlock + NumBlocksPerRound, "Cannot claim yet");
        require(!canClaim[currentRound], "Claim started already");
        require(ifDistributed[currentRound][0] && ifDistributed[currentRound][1], "Rewards not deliver");
        canClaim[currentRound] = true;
        currentRound++;
        lastRewardBlock = lastRewardBlock + NumBlocksPerRound;
    }

    function claimRewards(uint256 round, uint256 index) public {
        require(index <= 1);
        require(canClaim[round], "Cannot claim this round");
        UserData storage data = userData[msg.sender];
        require(!data.rewardClaimed[round][index], "Claimed already");
        uint256 finalShare = _calculateShare(msg.sender, round, index);
        if(index == 0) {
            totalShares[index] = totalShares[index]+data.tokenStaked[index]-data.actualShare[index];
            data.actualShare[index] = data.tokenStaked[index];

            stake(index, finalShare);
        } else {
            totalShares[index] = totalShares[index]+data.tokenStaked[index]-data.actualShare[index];
            data.actualShare[index] = data.tokenStaked[index];
            payable(msg.sender).transfer(finalShare);
        }
        data.rewardClaimed[round][index] = true;
        emit RewardClaimed(round, index, finalShare);
    }

    function calculateShare(address user, uint256 round, uint256 index) public view returns(uint256){
        return _calculateShare(user, round, index);
    }

    function _calculateShare(address user, uint256 round, uint256 index) internal view returns(uint256){
        uint256 RewardAmount = roundRewards[round][index];
        UserData storage data = userData[user];
        if(!data.rewardClaimed[round][index]) {
            return RewardAmount*data.actualShare[index]/(totalShares[index]);
        } else {
            return 0;
        }
        
    }

    function getUserData(address user) public view returns(
        uint256 tokenStakedCompound,
        uint256 actualShareCoumpound,
        uint256 tokenStakedStandard,
        uint256 actualShareStandard
    ) {
        UserData storage data = userData[user];
        tokenStakedCompound = data.tokenStaked[0];
        actualShareCoumpound = data.actualShare[0];
        tokenStakedStandard = data.tokenStaked[1];
        actualShareStandard = data.actualShare[1];
    }

    function getIfClaimed(address user, uint256 round) public view returns(
        bool ifClaimedCompound,
        bool ifClaimedStandard
    ){
        UserData storage data = userData[user];
        ifClaimedCompound = data.rewardClaimed[round][0];
        ifClaimedStandard = data.rewardClaimed[round][1];
    }

    function getCompounderPercent() public view returns(uint256){
        return 10000*totalShares[0]/(totalShares[0]+totalShares[1]);
    }

    function getCurrentRound() external view returns(uint256) {
        return currentRound;
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
