// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;
import "./ReentrancyGuard.sol";
import "./CommonImports.sol";
import "./SafeERC20.sol";

contract RefundContract is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public ETHperTokens = 0.00248 ether;
    uint256 public totalETHRefunded = 0;
    uint256 public totalTokens = 0;

    address burnAddr = 0x000000000000000000000000000000000000dEaD;
    IERC20 public token = IERC20(0xA6D84dce85c457d28A971f858967002BFDe74c1c);

    receive() external payable {}

    event Refunded(uint256 indexed tokensGotten,uint256 indexed ethSent);
    event RateChanged(uint256 indexed newRate);
    event ETHRetrived();

    function refund(uint256 tokenAmount) public nonReentrant {
        //Get tokens from user
        require(token.transferFrom(msg.sender,address(this),tokenAmount),"Get Tokens fail");
        //send eth
        uint256 ethSend  = tokenAmount.mul(ETHperTokens).div(1e18);
        (bool refundT,) = payable(msg.sender).call{ value: ethSend }("");
        require(refundT,"Eth refund failed");
        //send gotten tokens to burn address
        require(token.transfer(burnAddr,tokenAmount),"Burning swapped tokens fail");
        //Update total eth refund stat and emit event
        totalETHRefunded = totalETHRefunded.add(ethSend);
        totalTokens = totalTokens.add(tokenAmount);
        emit Refunded(tokenAmount,ethSend);
    }

    function setExchangeRate(uint256 newRate) public onlyOwner {
        ETHperTokens = newRate;
        emit RateChanged(newRate);
    }

    function setToken(address tokenAddr) public onlyOwner {
        token = IERC20(tokenAddr);
    }

    //Use this only in emergency cases to retreive eth from contract
    function retriveETH() public onlyOwner {
        (bool success,) = payable(owner()).call{value : address(this).balance }("");
        require(success);
        emit ETHRetrived();
    }

}