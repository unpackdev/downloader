pragma solidity >=0.6.0;

import "./ERC20.sol";
import "./IERC20.sol";

contract MockKyberProxy {
    address ethAddress;
    address aaveAddress;

    constructor(address _ethAddress, address _aaveAddress) public {
        ethAddress = _ethAddress;
        aaveAddress = _aaveAddress;
    }

    uint ethAave = 6; // eth $300, aave $50

    function swapEtherToToken(ERC20 token, uint minConversionRate) external payable returns(uint amountToSend) {
        if(token == ERC20(aaveAddress)){
            amountToSend = msg.value * ethAave;
            IERC20(aaveAddress).transfer(msg.sender, amountToSend);
        }
    }
    function swapTokenToEther(ERC20 token, uint tokenQty, uint minRate) external payable returns(uint returnAmount) {
        if(token == ERC20(aaveAddress)){
            IERC20(aaveAddress).transferFrom(msg.sender, address(this), tokenQty);
            returnAmount = tokenQty/ ethAave;
            msg.sender.transfer(returnAmount);
        }
    }

    function swapTokenToToken(ERC20 src, uint srcAmount, ERC20 dest, uint minConversionRate) public returns(uint){

    }

    receive() external payable {

    }
}