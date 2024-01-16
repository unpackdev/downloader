// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IDegenIDToken.sol";
import "./IStakingPool.sol";
import "./IRegistrationPool.sol";
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

contract TokenDistributor is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    event OtherTokensWithdrawn(address indexed currency, uint256 amount);
    event RewardReleased(uint256 indexed round, uint256 passiveShare, uint256 buyBackShare, uint256 stakeShare);
    event DistributorInitial(uint256 InitialBlock, uint256 endOfPeriod);

    uint256 public constant PRECISION = 10**12;

    struct RegisterPeriod{
        uint256 rewardPerRound;
        uint256 periodLength;
    }

     mapping(uint256 =>RegisterPeriod) public registerPeriods;
    
    uint256 public InitialBlock;
    uint256 public currentPeriodEnd;
    uint256 public currentPhase;
    uint256 public currentRound;
    uint256 public NumBlocksPerRound;
    uint256 public lastRewardBlock;
    uint256 public TotalPeriods;
    IERC20 public DegenIDToken;
    IDegenIDToken public DegenIDInterface;
    IStakingPool public StakingInterface;
    IRegistrationPool public RegistrationInterface;
    address public AirdropContract;
    address TeamContract;
    address public RewardContract;
    address public StakingContract;
    address public BuyBackContract;
    address public DIDRegister;

    mapping(uint256=>uint256) public roundProfit;

    uint256[3] rewardShares;
    uint256 totalShares;

    constructor(
        address _tokenAddr,
        address _airdropAddr,
        address _teamAddr,
        uint256[] memory _rewards,
        uint256[] memory _lengths,
        uint256 _numBlocks,
        uint256 _totalPeriods
    ){
        DegenIDToken = IERC20(_tokenAddr);
        DegenIDInterface = IDegenIDToken(_tokenAddr);
        for (uint256 i = 0; i < _totalPeriods; i++) {
            registerPeriods[i] = RegisterPeriod({
                rewardPerRound: _rewards[i],
                periodLength: _lengths[i]
            });
        }
        AirdropContract = _airdropAddr;
        TeamContract = _teamAddr;
        NumBlocksPerRound = _numBlocks;
        TotalPeriods = _totalPeriods;
    }

    function setNumBlock(uint256 _blocks) public onlyOwner {
        NumBlocksPerRound = _blocks;
    }

    function setPoolContracts(
        address _rewardPool,
        address _stakePool,
        address _buyback
    ) public onlyOwner {
        RewardContract = _rewardPool;
        StakingContract = _stakePool;
        BuyBackContract = _buyback;

        StakingInterface = IStakingPool(_stakePool);
        RegistrationInterface = IRegistrationPool(_rewardPool);
    }

    function initalizeDistributor() public onlyOwner {
        InitialBlock = block.number;
        currentPeriodEnd = InitialBlock + registerPeriods[0].periodLength;
        lastRewardBlock = InitialBlock;
        StakingInterface.initalizePool(InitialBlock);
        RegistrationInterface.initalizePool(InitialBlock, registerPeriods[0].rewardPerRound);
        emit DistributorInitial(InitialBlock, currentPeriodEnd);
    }

    function initalizeShares() public onlyOwner{
        uint256 percent = getCompounderPercent();
        require(percent <= 10000);
        rewardShares[0] = DegenIDToken.balanceOf(TeamContract)/PRECISION*PRECISION;
        rewardShares[1] = DegenIDToken.balanceOf(StakingContract)/PRECISION*percent/10000*PRECISION;
        rewardShares[2] = DegenIDToken.balanceOf(StakingContract)/PRECISION*(10000-percent)/10000*PRECISION;
        totalShares = DegenIDToken.balanceOf(TeamContract) + DegenIDToken.balanceOf(StakingContract);
    }

    function updateAddress(uint256 index, address newAddr) public onlyOwner {
        if(index == 0){
            DegenIDToken = IERC20(newAddr);
            DegenIDInterface = IDegenIDToken(newAddr);
        } else if(index == 1){
            AirdropContract = newAddr;
        } else if(index == 2){
            RewardContract = newAddr;
            RegistrationInterface = IRegistrationPool(newAddr);
        } else if(index == 3){
            StakingContract = newAddr;
            StakingInterface = IStakingPool(newAddr);
        } else if(index == 4){
            TeamContract = newAddr;
        }
    }

    function releaseAirdrop(uint256 amount) public onlyOwner {
        require(amount != 0);
        DegenIDInterface.mint(AirdropContract, amount);
    }

    function getCompounderPercent() public view returns(uint256) {
        return StakingInterface.getCompounderPercent();
    }

    function setDIDRegister(address _register) public onlyOwner {
        DIDRegister = _register;
    }

    function closeRoundProfit() external {
        require(msg.sender == DIDRegister || msg.sender == owner(), "Unauthorized");
        if(block.number >= lastRewardBlock + NumBlocksPerRound) {
            if(roundProfit[currentRound] == 0){
                roundProfit[currentRound] = address(this).balance;
            }
        }
    }

    function _validation() internal returns(uint256) {
        require(block.number >= lastRewardBlock + NumBlocksPerRound);
        if(block.number > currentPeriodEnd){
            currentPhase++;
            currentPeriodEnd = currentPeriodEnd + registerPeriods[currentPhase].periodLength;
        }
        if(roundProfit[currentRound] == 0) {
            roundProfit[currentRound] = address(this).balance;
        }
        lastRewardBlock = lastRewardBlock + NumBlocksPerRound;
        return lastRewardBlock;
    }

    function _updateShares() internal {
        uint256 percent = getCompounderPercent();
        require(percent <= 10000);
        rewardShares[0] = DegenIDToken.balanceOf(TeamContract);
        rewardShares[1] = DegenIDToken.balanceOf(StakingContract)*percent/10000;
        rewardShares[2] = DegenIDToken.balanceOf(StakingContract)*(10000-percent)/10000;
        totalShares = DegenIDToken.balanceOf(TeamContract) + DegenIDToken.balanceOf(StakingContract);
    }

    function releaseRewards() external onlyOwner returns(
        bool ifTeamSend,
        bool ifBuybackSend,
        bool ifStakeSend
    ){
        _validation();
        DegenIDInterface.mint(RewardContract, registerPeriods[currentPhase].rewardPerRound);
        uint256 totalReward = roundProfit[currentRound];
        uint256 passiveShare = totalReward*rewardShares[0]/totalShares/PRECISION;
        uint256 buyBackShare = totalReward*rewardShares[1]/totalShares/PRECISION;
        uint256 stakeShare = totalReward/PRECISION - passiveShare - buyBackShare;
        ifTeamSend = payable(TeamContract).send(passiveShare*PRECISION);
        ifBuybackSend = payable(BuyBackContract).send(buyBackShare*PRECISION);
        ifStakeSend = payable(StakingContract).send(stakeShare*PRECISION);
        RegistrationInterface.deliverReward(currentRound, registerPeriods[currentPhase].rewardPerRound);
        StakingInterface.deliverReward(currentRound,1, stakeShare*PRECISION);
        currentRound++;
        _updateShares();
        emit RewardReleased(currentRound-1, passiveShare, buyBackShare, stakeShare);
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