pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./BasisBase.sol";

 //bond--->cash
contract BasisRedeemBond is BasisBase{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
 
    event OnRedeemBond(address indexed user, address indexed bot,uint256 price,
                      uint256 bacAmount,uint256 babAmount,
                      uint256 botFee,uint256 houseFee);

    constructor(address _bac,address _bab,address _treasury){
        cash = _bac;
        bond = _bab;
        basisTreasury = _treasury;
        rewardAddr = msg.sender;
        IERC20(bond).approve(basisTreasury,uint256(-1)); 
    }

     //bond--->cash
    function getOffers() public view returns (UserInfo[] memory){
        return getUserInfos(bond);
    } 

    //Treasury cash
    function getBacReserve() public view returns(uint256){
        return IBasisTreasury(basisTreasury).getReserve();
    }

     //bond--->cash
    function getUserBabAmount(address _user) public view returns(uint256){
        uint256 balance = IERC20(bond).balanceOf(_user);
        uint256 approved = IERC20(bond).allowance(_user,address(this));
        return approved > balance ? balance : approved;
    } 

     //bond--->cash
    function redeemBond(address _user, address _bot, uint256 _babAmount) public onlyBotCenter{        
        uint256 _babBefore = thisBalance(bond);
        // pull user's bond into this contract (requires that the user has approved this contract)
        IERC20(bond).safeTransferFrom(_user, address(this), _babAmount); 
        //safe bab amount
        _babAmount = thisBalance(bond).sub(_babBefore);
        //
        uint256 _bacBefore = thisBalance(cash);
        uint256 targetPrice =  IBasisTreasury(basisTreasury).getBondOraclePrice();
        IBasisTreasury(basisTreasury).redeemBonds(_babAmount,targetPrice);
        //safe bac amount
        uint256 _bacAmount = thisBalance(cash).sub(_bacBefore); 
        require(_bacAmount > 0,"!redeem");       
        // pay the fees
        uint256 botFeeRate = getOffer(_user).sub(HOUSE_RATE);
        uint256 botFee = _bacAmount.mul(botFeeRate).div(PERCENT);
        uint256 houseFee = _bacAmount.mul(HOUSE_RATE).div(PERCENT);
        IERC20(cash).safeTransfer(rewardAddr, houseFee);
        IERC20(cash).safeTransfer(_bot, botFee);         
        // send the cash to the user
        IERC20(cash).safeTransfer(_user, _bacAmount.sub(houseFee).sub(botFee)); 
        //event
        emit OnRedeemBond(_user,_bot,targetPrice,_bacAmount,_babAmount,botFee,houseFee);
    }
     
     
} 