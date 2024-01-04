pragma solidity 0.7.0;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
import "./Math.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./RobotLimit.sol"; 
import "./UserInfo.sol";
import "./UseChiToken.sol";
import "./IBasisTreasury.sol";

interface IBasisRedeemBond{
    function basisTreasury() external returns(address);
    function getBacReserve() external returns(uint256);
    function getBondOraclePrice() external  returns(uint256);
    function getUserBabAmount(address _user) external returns(uint256);
    function redeemBond(address _user, address _bot, uint256 _babAmount) external;
}
 //bond--->cash
contract BasisRedeemBondBot is RobotLimit,UseChiToken{
    using SafeMath for uint256;
    address public redeemBond;
    address public treasury;
    address public chiToken;
    uint256 public MIN_BALANCE = 1e18;
    constructor(address _redeemBond,address _chiToken){  
        chiToken = _chiToken;
        redeemBond = _redeemBond;
        treasury = IBasisRedeemBond(redeemBond).basisTreasury(); 
    }

    function updateTreasury() public onlyOwner{
       treasury = IBasisRedeemBond(redeemBond).basisTreasury();
    }

    //for bot
    function getTreasuryStatus() public view returns(
        uint256 bacReserve,
        uint256 bondPrice,
        uint256 rebasePrice,
        uint256 cashCeiling,
        uint256 nextEpochTime,
        uint256 blocktime
    ){ 
        bacReserve    = IBasisTreasury(treasury).getReserve();
        bondPrice     = IBasisTreasury(treasury).getBondOraclePrice();         
        rebasePrice   = IBasisTreasury(treasury).getSeigniorageOraclePrice(); 
        cashCeiling   = IBasisTreasury(treasury).cashPriceCeiling();
        nextEpochTime = IBasisTreasury(treasury).nextEpochPoint();
        blocktime     = block.timestamp;
    } 

    function getRedeemBabAmount(address _user,uint256 totalBacAmount) private returns(uint256){
        uint256 _babAmount = IBasisRedeemBond(redeemBond).getUserBabAmount(_user);
        return _babAmount < totalBacAmount ? _babAmount : totalBacAmount;
    }
    
     //bond--->cash
    function redeemBondFor(address  _user) public useCHI(chiToken) onlyRobot {   
        address _bot = msg.sender;      
        uint256 totalBacAmount = IBasisRedeemBond(redeemBond).getBacReserve(); 
        uint256 _babAmount = getRedeemBabAmount(_user,totalBacAmount);
        require(_babAmount > MIN_BALANCE,"!bab");
        IBasisRedeemBond(redeemBond).redeemBond(_user,_bot,_babAmount);
    } 
     
 
} 