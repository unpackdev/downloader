//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Address.sol";
import "./IERC20.sol";
import "./IELONphantStaking.sol";

/**
 * Hat tip to --
 * ELONphant Funding Receiver
 * Will Allocate Funding To Different Sources
 * Contract Developed By DeFi Mark (MoonMark)
 * Thanks for sharing great code!
 */
contract ELONphantFundingReceiver {
    
    using Address for address;
    
    // Farming Manager
    address public farm;
    address public stake;
    address public multisig;
    address public foundation;
    // ELONphant
    address public constant ELONphant = 0xB7E29bD8A0D34d9eb41FC654eA1C6633ed59DD64;
    
    // allocation to farm + stake + multisig
    uint256 public farmFee;
    uint256 public stakeFee;
    uint256 public multisigFee;
    uint256 public foundationFee;
    
    // ownership
    address public _master;
    modifier onlyMaster(){require(_master == msg.sender, 'Sender Not Master'); _;}
    
    constructor() {
    
        _master = 0x156fb36ffD41fCBb76DaEfbFC0b1fF263E944AC8;
        multisig = 0x156fb36ffD41fCBb76DaEfbFC0b1fF263E944AC8;
        farm = 0x156fb36ffD41fCBb76DaEfbFC0b1fF263E944AC8;
        stake = 0x3Bc217cbBB234F5fe0D04A94C9dEf13bED1E423D;
        foundation = 0x156fb36ffD41fCBb76DaEfbFC0b1fF263E944AC8;
        stakeFee = 15;
        farmFee = 50;
        foundationFee = 30;
        multisigFee = 5;

    }
    
    event SetFarm(address farm);
    event SetStaker(address staker);
    event SetMultisig(address multisig);
    event SetFoundation(address foundation);
    event SetFundPercents(uint256 farmPercentage, uint256 stakePercent, uint256 multisigPercent, uint256 foundationPercent);
    event Withdrawal(uint256 amount);
    event OwnershipTransferred(address newOwner);
    
    // MASTER 
    
    function setFarm(address _farm) external onlyMaster {
        farm = _farm;
        emit SetFarm(_farm);
    }
    
    function setStake(address _stake) external onlyMaster {
        stake = _stake;
        emit SetStaker(_stake);
    }
     function setFoundation(address _foundation) external onlyMaster {
        foundation = _foundation;

        emit SetFoundation(_foundation);
    }
    function setMultisig(address _multisig) external onlyMaster {
        multisig = _multisig;
        emit SetMultisig(_multisig);
    }
    
    function setFundPercents(uint256 farmPercentage, uint256 stakePercent, uint256 multisigPercent, uint256 foundationPercent) external onlyMaster {
        farmFee = farmPercentage;
        stakeFee = stakePercent;
        multisigFee = multisigPercent;
        foundationFee = foundationPercent;
        emit SetFundPercents(farmPercentage, stakePercent, multisigPercent,foundationPercent);
    }
    
    function manualWithdraw(address token) external onlyMaster {
        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal > 0);
        IERC20(token).transfer(_master, bal);
        emit Withdrawal(bal);
    }
    
    function ETHWithdrawal() external onlyMaster returns (bool s){
        uint256 bal = address(this).balance;
        require(bal > 0);
        (s,) = payable(_master).call{value: bal}("");
        emit Withdrawal(bal);
    }
    
    function transferMaster(address newMaster) external onlyMaster {
        _master = newMaster;
        emit OwnershipTransferred(newMaster);
    }
    
    
    // ONLY APPROVED
    
    function distribute() external {
        _distributeYield();
    }

    // PRIVATE
    
    function _distributeYield() private {
        
        uint256 ELONphantBal = IERC20(ELONphant).balanceOf(address(this));
        
        uint256 farmBal = (ELONphantBal * farmFee) / 10**2;
        uint256 sigBal = (ELONphantBal * multisigFee) / 10**2;
        uint256 stakeBal = ELONphantBal - (farmBal + sigBal);
        uint256 foundationBal = (ELONphantBal * foundationFee) / 10**2;

        if (farmBal > 0 && farm != address(0)) {
            IERC20(ELONphant).approve(farm, farmBal);
            IELONphantStaking(farm).deposit(farmBal);
        }
        
        if (stakeBal > 0 && stake != address(0)) {
            IERC20(ELONphant).approve(stake, stakeBal);
            IELONphantStaking(stake).deposit(stakeBal);
        }
        
        if (sigBal > 0 && multisig != address(0)) {
            IERC20(ELONphant).transfer(multisig, sigBal);
        }

        if (foundationBal > 0 && foundation != address(0)) {
            IERC20(ELONphant).approve(foundation, foundationBal);
            IELONphantStaking(foundation).deposit(foundationBal);
            
        }
    }
    
    receive() external payable {
        (bool s,) = payable(ELONphant).call{value: msg.value}("");
        require(s, 'Failure on Token Purchase');
        _distributeYield();
    }
    
}