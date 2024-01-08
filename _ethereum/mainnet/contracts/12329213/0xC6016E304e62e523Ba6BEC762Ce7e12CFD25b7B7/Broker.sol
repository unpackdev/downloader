// contracts/Broker.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract Broker is Ownable{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event Buy(address wallet, uint256 amount);
    event Sell(address wallet, uint256 amount);

    IERC20 public dirham;
    IERC20 public dai;
    IERC20 public usdt;   

    uint256 public usd2dhsRate = 3672500000000000000;
    uint256 scale = 1e18;

    uint256 step0 = 1e21;
    uint256 step1 = 1e22;
    uint256 step2 = 1e23;

    uint256 prc0 = 0.97 * 1e18;
    uint256 prc1 = 0.98 * 1e18;
    uint256 prc2 = 0.995 * 1e18;
    uint256 prc3 = 0.9985 * 1e18;
    
    constructor(address _dirham, address _dai, address _usdt) public {
        dirham = IERC20(_dirham);
        dai = IERC20(_dai);
        usdt = IERC20(_usdt);
    }

    function calculatePercent(uint256 amount) internal view returns(uint256){
        if (amount <= step0) return prc0;
        else if (amount <= step1) return prc1;
        else if (amount <= step2) return prc2;
        else return prc3;
    } 

    function withdraw(address token, address dst, uint256 amount) onlyOwner external{
        IERC20(token).safeTransfer(dst, amount);
    }

    function buyWithDAI(uint256 amount) external{
        uint256 returnAmount = amount.mul(usd2dhsRate).div(scale);
        uint256 prc = calculatePercent(returnAmount);

        dai.transferFrom(msg.sender, address(this), amount);
        dirham.transfer(msg.sender, returnAmount.mul(prc).div(scale));
        
        emit Buy(msg.sender, returnAmount);
    }

    function sellToDAI(uint256 amount) external{
        uint256 returnAmount = amount.mul(scale).div(usd2dhsRate);
        uint256 prc = calculatePercent(amount); 

        dirham.transferFrom(msg.sender, address(this), amount);
        dai.transfer(msg.sender, returnAmount.mul(prc).div(scale));

        emit Sell(msg.sender, amount);
    }    
    
    function buyWithUSDT(uint256 amount) external{
        uint256 returnAmount = amount.mul(usd2dhsRate).div(scale).mul(1e12);
        uint256 prc = calculatePercent(returnAmount);

        usdt.safeTransferFrom(msg.sender, address(this), amount);
        dirham.transfer(msg.sender, returnAmount.mul(prc).div(scale));
        
        emit Buy(msg.sender, returnAmount);
    }

    function sellToUSDT(uint256 amount) external{
        uint256 returnAmount = amount.mul(scale).div(usd2dhsRate);
        uint256 prc = calculatePercent(amount); 

        dirham.transferFrom(msg.sender, address(this), amount);
        usdt.safeTransfer(msg.sender, returnAmount.mul(prc).div(scale).div(1e12));

        emit Sell(msg.sender, amount);
    }
}