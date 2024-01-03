// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
import "./Ownable.sol";
import "./UniswapV2Library.sol";
import "./IUnitradeOrderbook.sol";
import "./IChi.sol";
import "./IKeep3rV1Mini.sol";
contract UnitradeExecutorRLRV7 is Ownable{

    UnitradeInterface public iUniTrade = UnitradeInterface(
        0xC1bF1B4929DA9303773eCEa5E251fDEc22cC6828
    );

    //change this to relay3r on deploy
    IKeep3rV1Mini public RLR;
    uint public minKeep = 100e18;

    bool TryDeflationaryOrders = false;
    bool public payoutETH = true;
    bool public payoutRLR = true;

    iCHI public CHI = iCHI(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    mapping(address => bool) public tokenOutSkip;
    mapping(address => bool) public tokenInSkip;
    mapping(uint => bool) public orderSkip;


    constructor(address keepertoken) public {
        RLR = IKeep3rV1Mini(keepertoken);
        require(CHI.approve(address(this), uint256(-1)));
    }

    //Custom upkeep modifer with CHI support
    modifier upkeep() {
        uint256 gasStart = gasleft();
        require(RLR.isMinKeeper(msg.sender, minKeep, 0, 0),"!relayer");
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        CHI.freeFromUpTo(address(this), (gasSpent + 14154) / 41947);
        if(payoutRLR) {
            //Payout RLR
            RLR.worked(msg.sender);
        }
    }

    function togglePayETH() public onlyOwner {
        payoutETH = !payoutETH;
    }

    function togglePayRLR() public onlyOwner {
        payoutRLR = !payoutRLR;
    }

    function toggleTokenOutSkip(address token) public onlyOwner {
        tokenOutSkip[token] = !tokenOutSkip[token];
    }

    function toggleTokenInSkip(address token) public onlyOwner {
        tokenInSkip[token] = !tokenInSkip[token];
    }
    function toggleOrder(uint orderid) public onlyOwner {
        orderSkip[orderid] = !orderSkip[orderid];
    }

    function setMinKeep(uint _keep) public onlyOwner {
        minKeep = _keep;
    }

    //Use this to depricate this job to move rlr to another job later
    function destructJob() public onlyOwner {
        //Get the credits for this job first
        uint256 currRLRCreds = RLR.credits(address(this),address(RLR));
        uint256 currETHCreds = RLR.credits(address(this),RLR.ETH());
        //Send out RLR Credits if any
        if(currRLRCreds > 0) {
            //Invoke receipt to send all the credits of job to owner
            RLR.receipt(address(RLR),owner(),currRLRCreds);
        }
        //Send out ETH credits if any
        if (currETHCreds > 0) {
            RLR.receiptETH(owner(),currETHCreds);
        }
        //Finally self destruct the contract after sending the credits
        selfdestruct(payable(owner()));
    }

    function setTryBurnabletokens(bool fTry) public onlyOwner{
        TryDeflationaryOrders = fTry;
    }


    function getIfExecuteable(uint256 i) public view returns (bool) {
        (
            ,
            ,
            address tokenIn,
            address tokenOut,
            uint256 amountInOffered,
            uint256 amountOutExpected,
            uint256 executorFee,
            ,
            OrderState orderState,
            bool deflationary
        ) = iUniTrade.getOrder(i);

        if(executorFee <= 0) return false;//Dont execute unprofitable orders
        if(deflationary && !TryDeflationaryOrders) return false;//Skip deflationary token orders as it is not supported atm
        if(tokenInSkip[tokenIn]) return false;//Skip tokens that are set in mapping
        if(tokenOutSkip[tokenOut]) return false;//Skip tokens that are set in mapping

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            iUniTrade.uniswapV2Factory(),
            amountInOffered,
            path
        );

        if (amounts[1] >= amountOutExpected && orderState == OrderState.Placed)
            return true;

        return false;
    }

    function hasExecutableOrdersPending() public view returns (bool) {
        for (uint256 i = 0; i < iUniTrade.getActiveOrdersLength() - 1; i++) {
            if (getIfExecuteable(iUniTrade.getActiveOrderId(i))) {
                return true;
            }
        }
        return false;
    }

    //Get count of executable orders
    function getExectuableOrdersCount() public view returns (uint count){
        for (uint256 i = 0; i < iUniTrade.getActiveOrdersLength() - 1; i++) {
            if (getIfExecuteable(iUniTrade.getActiveOrderId(i))) {
                count++;
            }
        }
    }

    function getExecutableOrdersList() public view returns (uint[] memory) {
        uint[] memory orderArr = new uint[](getExectuableOrdersCount());
        uint index = 0;
        for (uint256 i = 0; i < iUniTrade.getActiveOrdersLength() - 1; i++) {
            if (getIfExecuteable(iUniTrade.getActiveOrderId(i))) {
                orderArr[index] = iUniTrade.getActiveOrderId(i);
                index++;
            }
        }
        return orderArr;
    }

    receive() external payable {}

    function sendETHRewards() internal {
        if(!payoutETH) {
            //Transfer received eth to treasury
            (bool success,  ) = payable(owner()).call{value : address(this).balance}("");
            require(success,"!treasurysend");
        }
        else {
            (bool success,  ) = payable(msg.sender).call{value : address(this).balance}("");
            require(success,"!sendETHRewards");
        }
    }

    function workable() public view returns (bool) {
        return hasExecutableOrdersPending();
    }

    //Use this to save on gas
    function workBatch(uint[] memory orderList) public upkeep {
        for (uint256 i = 0; i < orderList.length; i++) {
            iUniTrade.executeOrder(orderList[i]);
        }
        //After order executions send all the eth to relayer
        sendETHRewards();
    }

    function workSolo(uint order) public upkeep {
        iUniTrade.executeOrder(order);
        //After order executions send all the eth to relayer
        sendETHRewards();
    }

    function recoverERC20(address token) public onlyOwner {
        sendERC20(token,owner());
    }

    //Helper functions for handling sending of reward token
    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function sendERC20(address tokenAddress,address receiver) internal {
        IERC20(tokenAddress).transfer(receiver, getTokenBalance(tokenAddress));
    }
}
