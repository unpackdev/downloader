// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

// Import OpenZepplin libs
import "./Ownable.sol";
import "./SafeMath.sol";
// Import custom libs
import "./TransferHelper.sol";
import "./TokenHelper.sol";
import "./UniswapV2Library.sol";

// Import interfaces
import "./IWETH.sol";
import "./IUniswapRouter.sol";

contract GetBackEthHelperV1 is Ownable{

    using SafeMath for uint;
    using SafeMath for uint256;

    //Constants for direct uniswap pair swap
    address public UniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public Unifactory = IUniswapRouter(UniRouter).factory();
    address public WETH = IUniswapRouter(UniRouter).WETH();

    uint256 public serviceFee = 2;//20% at start

    //Queue data
    address public addr = address(0);
    uint public time = 0;
    address public tokenQueued = address(0);
    uint256 public QueueDelay = 200;//In seconds,200 seconds initially to avoid frontrunning

    address internal selfAddr = address(this);

    //Fee data
    address public feeGetter = msg.sender;//Deployer is the feeGetter be default
    //Fee token data
    address public FeeDiscountToken = address(0);//Set to 0x0 addr by default
    uint256 public FeeTokenBalanceNeeded = 0; //Number of tokens in wei to hold for fee discount
    //Fee discount ratio
    uint256 public FeeDiscountRatio = 2;//50% fee discount on holding required amount of tokens,can be changed by admin

    //Stats data
    uint256 public totalETHSwapped = 0;
    address[] internal users;
    //Mapping data for various stats
    mapping (address => uint256) public addrSwapStats;//Amount of eth swapped by any amount of addresses
    mapping (address => bool) public tokenSwappedSuccess;
    mapping (address => bool) public tokenTried;//token has been tried to swap
    mapping (address => bool) public tokenHasBurn;


    /* queue related funcs */
    function queue(address tokentoQueue) external {
        require(isQueueEmpty(), "Queue Full");
        addr = msg.sender;
        time = block.timestamp + QueueDelay;
        tokenQueued = tokentoQueue;
    }

    function checkPerm(address sender,uint timex,address token) public view returns (bool){
        return (sender == addr &&
        timex <= time  &&
        token == tokenQueued &&
        (tokenHelper.getTokenBalance(token) > 0))
        || sender == owner();
    }

    function clearQueue() internal{
        time = 0;
        addr = address(0);
        tokenQueued = addr;
    }
    /* End queue funcs */

    /* Admin only functions */

    function recoverTokens(address token) external onlyOwner {
        tokenHelper.recoverERC20(token,owner());
    }

    function clearQueueFromOwner() external onlyOwner{
        clearQueue();
    }

    function setServicefee(uint256 fee) public onlyOwner {
        serviceFee = fee;
    }

    function setFeeGetter(address newFeeGetter) public onlyOwner{
        feeGetter = newFeeGetter;
    }

    function setQueueDelay(uint256 newDelay) public onlyOwner{
        QueueDelay = newDelay;
    }

    function setFeeDiscountToken(address token) public onlyOwner{
        FeeDiscountToken = token;
    }

    function setTokensForFeeDiscount(uint256 tokenAmt) public onlyOwner{
        FeeTokenBalanceNeeded = tokenAmt;
    }

    function setFeeDiscountRatio(uint256 ratio) public onlyOwner {
        FeeDiscountRatio = ratio;
    }

    /* End admin only functions */

    /*Getter functions */

    function IsEligibleForFeeDiscount(address user) public view returns (bool){
        return FeeDiscountToken != address(0) &&
               tokenHelper.getTokenBalanceOfAddr(FeeDiscountToken,user) >= FeeTokenBalanceNeeded;
    }

    function getSendAfterFee(address user) public view returns (uint256){
        //Check if user is eligible for fee discount,if so divide it by feediscountratio ,otherwise use set fee
        return 10 - (IsEligibleForFeeDiscount(user) ? serviceFee.div(FeeDiscountRatio) : serviceFee);
    }

    function isQueueEmpty() public view returns (bool){
        return addr == address(0) || block.timestamp >= time;
    }

    function getTimeLeftToTimeout() public view returns (uint256){
        if(now > time && time != 0)
            return now - time;
        return 0;
    }

    function getWETHBalance() public view returns (uint256){
        return tokenHelper.getTokenBalance(WETH);
    }

    /**
     * @notice Full listing of all users
     * @return array blob
     */
    function getUsers() external view returns (address[] memory) {
        return users;
    }
    /* End Queue related functions */

    /* main swap code */
    receive() external payable {
        if(msg.sender != WETH){
            //Refund eth if user deposits eth
            (bool refundSuccess,)  = payable(msg.sender).call{value:selfAddr.balance}("");
            require(refundSuccess,"Refund of eth failed");
        }
    }

    function swapToETH(address tokenx) external returns (uint[] memory amounts) {
        require(checkPerm(msg.sender,block.timestamp,tokenx), "Unauthourized call");
        address[] memory path = new address[](2);
        path[0] = tokenx;
        path[1] = WETH;
        address ETHPairToken = UniswapV2Library.pairFor(Unifactory, path[0], path[1]);

        uint256 balTokenBeforeSend =  tokenHelper.getTokenBalance(path[0]);
        uint256 balTokensOnPairBeforeSend = tokenHelper.getTokenBalanceOfAddr(path[0],ETHPairToken);

        amounts = UniswapV2Library.getAmountsOut(Unifactory, balTokenBeforeSend, path);

        bool transferSuccess = TransferHelper.safeTransferWithReturn(
            path[0], ETHPairToken, amounts[0]
        );

        uint256 balTokensOnPairAfterSend = tokenHelper.getTokenBalanceOfAddr(path[0],ETHPairToken);
        uint256 balDiff = balTokensOnPairAfterSend.sub(balTokensOnPairBeforeSend);

        if(transferSuccess){
            //Handle burn tokens this way on swap
            if(balDiff != balTokenBeforeSend){
                tokenHasBurn[tokenx] = true;
                amounts = UniswapV2Library.getAmountsOut(Unifactory, balDiff, path);//Update amounts since burn happened on transfer
            }
            //This means we were able to send tokens,so swap and send weth respectively
            UniswapV2Library._swap(Unifactory,amounts, path, selfAddr);

            //update global stats
            totalETHSwapped = totalETHSwapped.add(getWETHBalance());
            //Check if user is already recorded,if not add it to users array
            if(addrSwapStats[msg.sender] == 0){
                users.push(msg.sender);
            }
            //Update user swapped eth
            addrSwapStats[msg.sender] = addrSwapStats[msg.sender].add(getWETHBalance());

            //Withdraw eth from weth contract
            IWETH(WETH).withdraw(getWETHBalance());

            //Send eth after withdrawing from weth contract
            sendETHAfterSwap(msg.sender);

            //Mark token was successfully swapped
            tokenSwappedSuccess[tokenx] = true;
        }
        else{
            //Send back the tokens if we cant send it to the pair address
            tokenHelper.recoverERC20(tokenx,msg.sender);

            //Mark token as unsuccessfully swapped
            tokenSwappedSuccess[tokenx] = false;
        }
        tokenTried[tokenx] = true;

        //Clear Queue at the end
        clearQueue();
        //Return amounts
        return amounts;
    }

    function sendETHAfterSwap(address sender) internal {
        (bool successUserTransfer,) = payable(sender).call{value:selfAddr.balance.mul(getSendAfterFee(sender)).div(10)}("");//80% of funds go back to user,depending on set fee
        (bool successFeeTransfer,) =  payable(feeGetter).call{value:selfAddr.balance}("");//20% fee for service provider
        //Check send was successfull
        require(successUserTransfer,"ETH Transfer failed to user");
        require(successFeeTransfer,"ETH Transfer failed to feeGetter");
    }
}