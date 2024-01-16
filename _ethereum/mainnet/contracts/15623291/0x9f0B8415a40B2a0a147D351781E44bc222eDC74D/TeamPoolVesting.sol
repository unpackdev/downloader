// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
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

contract TeamPoolVesting is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public DegenIDToken;
    uint256 public TotalPeriods;
    uint256 public AmountUnlockPerPeriod;
    uint256 public InitialBlock;
    uint256[] public DaysPerPeriod;
    uint256 public MaxWithdrawAvailable;
    uint256 public nextBlockForUnlock;
    uint256 public CurrentPeriod;
    uint256 public NumBlocksPerDay;

    event OtherTokensWithdrawn(address indexed currency, uint256 amount);
    event TokensUnlocked(uint256 CurrentPeriod, uint256 nextUnlockBlock);
    event TokensWithdraw(uint256 amount);

    constructor(
        uint256[] memory _daysPerPeriod,
        uint256 _totalPeriods,
        uint256 _periodUnlock,
        uint256 _numBlocks,
        address _degenIDToken
    ) {
        DaysPerPeriod = _daysPerPeriod;
        TotalPeriods = _totalPeriods;
        AmountUnlockPerPeriod = _periodUnlock;
        NumBlocksPerDay = _numBlocks;
        DegenIDToken = IERC20(_degenIDToken);
    }

    function vestingStart() public nonReentrant onlyOwner {
        require(InitialBlock == 0);
        InitialBlock = block.number;
        nextBlockForUnlock = InitialBlock + DaysPerPeriod[0]*NumBlocksPerDay;
    }

    function setNumBlocks(uint256 numBlocks) public onlyOwner {
        require(numBlocks > 0);
        NumBlocksPerDay = numBlocks;
    }

    function unlockToken() public onlyOwner{
        require( (CurrentPeriod < TotalPeriods) && (block.number >= nextBlockForUnlock), "Cannot unlock yet!");
        MaxWithdrawAvailable = MaxWithdrawAvailable + AmountUnlockPerPeriod;
        CurrentPeriod++;
        nextBlockForUnlock = nextBlockForUnlock + DaysPerPeriod[CurrentPeriod]*NumBlocksPerDay;

        emit TokensUnlocked(CurrentPeriod, nextBlockForUnlock);
    }

    function withdrawToken(uint256 amount) external nonReentrant onlyOwner {
        require(amount <= MaxWithdrawAvailable, "Nothing to withdraw");
        DegenIDToken.safeTransfer(msg.sender, amount);

        emit TokensWithdraw(amount);
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
