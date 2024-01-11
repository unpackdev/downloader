// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity 0.7.4;

import "./TokensRecoverable.sol";
import "./Owned.sol";
import "./IERC1155Pi.sol";
import "./ReentrancyGuard.sol";
 
contract CircleVault is Owned, TokensRecoverable, ReentrancyGuard
{
    using SafeMath for uint256;
    
    uint256 public rateECirclePerSmallCircle;
    uint256 divisor;

    uint256 public immutable tokenIdsCircle;
    uint256 public immutable tokenIdeCircle;

    uint256 totaleCircleMints;

    IERC1155 public immutable CircleNFT;
    // percentAfterDrop should be less than -> 100% - (burn + treasury)%    
    mapping(address=> uint256) public percentAfterDrop;  //pBNB - Pi LP => percentage


    constructor(IERC1155 _nftContract, address _LpToken, uint256 _percentAfterDrop, uint256 _rateECirclePerSmallCircle)
    {
        CircleNFT = _nftContract;
        percentAfterDrop[_LpToken] = _percentAfterDrop;
        rateECirclePerSmallCircle = _rateECirclePerSmallCircle;
        tokenIdsCircle = 1;
        tokenIdeCircle = 2;
        totaleCircleMints = 0;

        divisor = 1e18;
    }


    function setParameters(address _LPToken, uint256 _percentAfterDrop, uint256 _rateECirclePerSmallCircle, uint256 _divisor) external ownerOnly{
        require(_percentAfterDrop<100000,"Percent after drop should be below 100%");
        percentAfterDrop[_LPToken] = _percentAfterDrop;
        rateECirclePerSmallCircle = _rateECirclePerSmallCircle;
        divisor = _divisor;
    }

    // sender to approve NFT on this contract..
    function depositSmallCircle(uint256 amount) external nonReentrant returns (uint256){
        require(amount.mod(rateECirclePerSmallCircle)==0,"Deposit not in correct multiple");
        IERC1155(CircleNFT).burn(msg.sender, tokenIdsCircle, amount);
        uint256 mintsForECircle = amount.div(rateECirclePerSmallCircle);
        IERC1155(CircleNFT).mint(msg.sender, tokenIdeCircle, mintsForECircle, "0x");

        totaleCircleMints = totaleCircleMints.add(mintsForECircle);
        return mintsForECircle;
    }

    function sellSmallCircle(address _LPToken, uint256 amount) external nonReentrant returns (uint256){
        require(percentAfterDrop[_LPToken]>0,"This LP token not allowed");
        IERC1155(CircleNFT).burn(msg.sender, tokenIdsCircle, amount);
        uint256 claimedBackAmount = amount.mul(divisor).mul(percentAfterDrop[_LPToken]).div(100000);
        IERC20(_LPToken).transfer(msg.sender, claimedBackAmount);
        return claimedBackAmount;
    }

    function recoverLPs(IERC20 _LPToken, uint256 _amount) public ownerOnly {       
        _LPToken.transfer(msg.sender, _amount);
    }

    function amountLPsForRecover(address _LPToken) external view returns(uint256){
        return totaleCircleMints.mul(rateECirclePerSmallCircle).mul(divisor).mul(percentAfterDrop[_LPToken]).div(100000);
    }

}