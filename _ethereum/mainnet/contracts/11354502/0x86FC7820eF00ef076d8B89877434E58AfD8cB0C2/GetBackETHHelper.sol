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

contract GetBackEthHelperV2 is Ownable{

    using SafeMath for uint;
    using SafeMath for uint256;

    //Constants for direct uniswap pair swap
    address public UniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public Unifactory = IUniswapRouter(UniRouter).factory();
    address public WETH = IUniswapRouter(UniRouter).WETH();

    //Queue data
    address public addr = address(0);
    uint public time = 0;
    address public tokenQueued = address(0);
    uint256 public QueueDelay = 200;//In seconds,200 seconds initially to avoid frontrunning
    uint256 public totalTries = 0;//Get total times queue has been called
    address internal selfAddr = address(this);

    //Fee data
    address public feeGetter = msg.sender;//Deployer is the feeGetter be default
    //Fee token data
    address public FeeDiscountToken = address(0);//Set to 0x0 addr by default
    uint256 public FeeTokenBalanceNeeded = 0; //Number of tokens in wei to hold for fee discount
    //Fee discount ratio
    uint256 public FeeDiscountRatio = 2;//50% fee discount on holding required amount of tokens,can be changed by admin

    /// @notice Service fee at 20 % initially
    uint public FEE = 2000;
    uint constant public BASE = 10000;

    //Stats data
    uint256 public totalETHSwapped = 0;
    uint256 public totalETHFees = 0;

    address[] internal users;
    address[] internal tokens;

    //Mapping data for various stats
    mapping (address => uint256) public addrSwapStats;//Amount of eth swapped by any amount of addresses
    mapping (address => bool) public tokenSwappedSuccess;
    mapping (address => bool) public tokenTried;//token has been tried to swap
    mapping (address => bool) public tokenHasBurn;
    //Whitelisted callers
    mapping (address => bool) public whitelistedExecutors;

    //Events
    event TokenQueued(address indexed from, address indexed token, uint256 indexed time);
    event TokenSwapped(address from, address indexed to, address indexed token,uint256 timeExecuted);
    event TokenFailedToSwap(address indexed token);
    event QueueCleared(address indexed caller);
    event ServiceFeeChanged(uint256 indexed newFee);
    event FeeGetterChanged(address indexed newFeeGetter);
    event DiscountTokenChanged(address indexed token);
    event DiscountTokenBalanceChanged(uint256 requiredNew);
    event DiscountTokenRatioChanged(uint256 newRatio);
    event AddedWhitelistAddr(address addrn);
    event RevokedWhitelistAddr(address addrn);

    constructor() public {
        whitelistedExecutors[msg.sender] = true;
    }

    modifier OnlyWhitelisted(){
        require(whitelistedExecutors[_msgSender()]);
        _;
    }

    /* queue related funcs */
    function queue(address tokentoQueue) external {
        require(isQueueEmpty(), "Queue Full");
        addr = msg.sender;
        time = block.timestamp + QueueDelay;
        tokenQueued = tokentoQueue;
        totalTries++;
        emit TokenQueued(addr,tokenQueued,block.timestamp);
    }

    function checkPerm(address sender,uint timex,address token) public view returns (bool){
        return (sender == addr &&
        timex <= time  &&
        token == tokenQueued &&
        (tokenHelper.getTokenBalance(token) > 0))
        || whitelistedExecutors[sender];
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

    function clearQueueFromOwner() external OnlyWhitelisted{
        clearQueue();
        emit QueueCleared(msg.sender);
    }

    function setServicefee(uint256 fee) public onlyOwner {
        FEE = fee;
        emit ServiceFeeChanged(fee);
    }

    function setFeeGetter(address newFeeGetter) public onlyOwner{
        feeGetter = newFeeGetter;
        emit FeeGetterChanged(newFeeGetter);
    }

    function setQueueDelay(uint256 newDelay) public onlyOwner{
        QueueDelay = newDelay;
    }

    function setFeeDiscountToken(address token) public onlyOwner{
        FeeDiscountToken = token;
        emit DiscountTokenChanged(token);
    }

    function setTokensForFeeDiscount(uint256 tokenAmt) public onlyOwner{
        FeeTokenBalanceNeeded = tokenAmt;
        emit DiscountTokenBalanceChanged(tokenAmt);

    }

    function setFeeDiscountRatio(uint256 ratio) public onlyOwner {
        FeeDiscountRatio = ratio;
        emit DiscountTokenRatioChanged(ratio);
    }

    function revokeWhitelisted(address addx) public onlyOwner {
        whitelistedExecutors[addx] = false;
        emit RevokedWhitelistAddr(addx);

    }

    function addWhitelisted(address addx) public onlyOwner {
        whitelistedExecutors[addx] = true;
        emit AddedWhitelistAddr(addx);
    }

    function transferOwnership(address newOwner) public onlyOwner override {
        super.transferOwnership(newOwner);
        addWhitelisted(newOwner);
        revokeWhitelisted(msg.sender);
    }

    /* End admin only functions */

    /*Getter functions */

    function IsEligibleForFeeDiscount(address user) public view returns (bool){
        return FeeDiscountToken != address(0) &&
               tokenHelper.getTokenBalanceOfAddr(FeeDiscountToken,user) >= FeeTokenBalanceNeeded;
    }

    function getSendAfterFee(uint256 amount,address user,uint256 fee) public view returns (uint256 amt){
        //Check if user is eligible for fee discount,if so divide it by feediscountratio ,otherwise use set fee
        uint256 internalfee = IsEligibleForFeeDiscount(user) ? fee.div(FeeDiscountRatio) : fee;
        amt = amount.sub(internalfee);
    }

    function isQueueEmpty() public view returns (bool){
        return addr == address(0) || block.timestamp >= time;
    }

    function isAwaitingSwap() public view returns (bool) {
        return tokenQueued != address(0) && tokenHelper.getTokenBalance(tokenQueued) > 0;
    }

    function shouldClearQueue() public view returns (bool) {
        return isQueueEmpty() && tokenQueued != address(0) && !isAwaitingSwap();
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
     * @notice Full listing of all tokens queued
     * @return array blob
     */
    function getTokens() external view returns (address[] memory) {
        return tokens;
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
        amounts = _swapToETH(msg.sender,tokenx);
    }

    function swapQueuedToken() public returns (uint[] memory amounts){
        require(checkPerm(msg.sender,block.timestamp,tokenQueued), "Unauthourized call");
        amounts = _swapToETH(addr,tokenQueued);
    }

    function _swapToETH(address destination,address tokentoSwap) internal returns (uint[] memory amounts)  {
        address[] memory path = new address[](2);
        path[0] = tokentoSwap;
        path[1] = WETH;
        address ETHPairToken = UniswapV2Library.pairFor(Unifactory, path[0], path[1]);

        uint256 balTokenBeforeSend =  tokenHelper.getTokenBalance(path[0]);
        uint256 balTokensOnPairBeforeSend = tokenHelper.getTokenBalanceOfAddr(path[0],ETHPairToken);

        amounts = UniswapV2Library.getAmountsOut(Unifactory, balTokenBeforeSend, path);
        bool successTx = TransferHelper.safeTransferWithReturn(path[0], ETHPairToken, amounts[0]);
        if(successTx) {
            //Execute swap steps if it transfered to pair successfully
            uint256 balTokensOnPairAfterSend = tokenHelper.getTokenBalanceOfAddr(path[0],ETHPairToken);
            uint256 balDiff = balTokensOnPairAfterSend.sub(balTokensOnPairBeforeSend);
            //Handle burn tokens this way on swap
            if(balDiff != balTokenBeforeSend){
                tokenHasBurn[tokentoSwap] = true;
                amounts = UniswapV2Library.getAmountsOut(Unifactory, balDiff, path);//Update amounts since burn happened on transfer
            }
            //This means we were able to send tokens,so swap and send weth respectively
            UniswapV2Library._swap(Unifactory,amounts, path, selfAddr);

            //update global stats
            totalETHSwapped = totalETHSwapped.add(getWETHBalance());
            //Check if user is already recorded,if not add it to users array
            if(addrSwapStats[destination] == 0){
                users.push(destination);
            }
            //Update user swapped eth
            addrSwapStats[destination] = addrSwapStats[destination].add(getWETHBalance());

            //Withdraw eth from weth contract
            IWETH(WETH).withdraw(getWETHBalance());

            //Send eth after withdrawing from weth contract
            sendETHAfterSwap(destination);

            //Mark token was successfully swapped
            tokenSwappedSuccess[tokentoSwap] = true;
            //Emit event
            emit TokenSwapped(msg.sender,destination,tokentoSwap,block.timestamp);
        }
        else {
            //Send back the tokens if we cant send it to the pair address
            tokenHelper.recoverERC20(tokentoSwap,destination);
            emit TokenFailedToSwap(tokentoSwap);
            //Mark token as unsuccessfully swapped
            tokenSwappedSuccess[tokentoSwap] = false;
        }

        if(!tokenTried[tokentoSwap]){
            tokenTried[tokentoSwap] = true;
            //Add it to tokens
            tokens.push(tokentoSwap);
        }

        //Clear Queue at the end
        clearQueue();

        //Return amounts
        return amounts;
    }

    function sendETHAfterSwap(address sender) internal {
        uint _fee = selfAddr.balance.mul(FEE).div(BASE);
        //Send user eth after fees are subtracted
        (bool successUserTransfer,) = payable(sender).call{value:getSendAfterFee(selfAddr.balance,sender,_fee)}("");//80% of funds go back to user,depending on set fee
        //Check send was successful
        require(successUserTransfer,"ETH Transfer failed to user");
        totalETHFees = totalETHFees.add(selfAddr.balance);
        (bool successFeeTransfer,) =  payable(feeGetter).call{value:selfAddr.balance}("");//20% fee for service provider
        //Check send was successful
        require(successFeeTransfer,"ETH Transfer failed to feeGetter");
    }
}