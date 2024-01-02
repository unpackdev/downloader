// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface ISwapV2Pair {

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract BasicOrder is Ownable {
    using SafeMath for uint;

    address internal immutable factory;
    address internal immutable WETH;

    uint public constant divicision = 10000;
    uint public feeRate = 0;                    // 0%
    mapping(address => uint256) public feeAmount;
    

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'SwapRouter: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SwapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? SwapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            ISwapV2Pair(SwapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }
    function swapExactTokensForTokens(
        bool isFrom,
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) internal ensure(deadline) returns (uint[] memory amounts) {
        if(isFrom){
            amounts = _swapExactTokensForTokensForFrom(amountIn, amountOutMin, path, to);
        }else{
            amounts = _swapExactTokensForTokensForTo(amountIn, amountOutMin, path, to);
        }
    }
    
    function _swapExactTokensForTokensForFrom(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to
    ) private returns (uint[] memory amounts){

        uint256 amountForIn = amountIn.mul(divicision-feeRate).div(divicision);

        amounts = SwapV2Library.getAmountsOut(factory, amountForIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], to, SwapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        // fee
        uint256 amountReceive = amountIn.mul(feeRate).div(divicision);
        feeAmount[path[0]] += amountReceive;
        TransferHelper.safeTransferFrom(
            path[0], to, address(this), amountReceive
        );
        _swap(amounts, path, to);
    }

    function _swapExactTokensForTokensForTo(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to
    ) private returns (uint[] memory amounts){
        
        amounts = SwapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], to, SwapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        // fee
        feeAmount[path[path.length-1]] += amounts[amounts.length - 1].mul(feeRate).div(divicision);
        // send
        uint256 amount = amounts[amounts.length - 1].mul(divicision-feeRate).div(divicision);
        TransferHelper.safeTransfer(path[path.length-1], to, amount);
    }
    
    function swapExactETHForTokens(uint amountIn,uint amountOutMin, address[] memory path, address to, uint deadline)
        internal
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[0] == WETH, 'SwapRouter: INVALID_PATH');
        // fee
        feeAmount[WETH] += amountIn.mul(feeRate).div(divicision);

        uint256 amount = amountIn.mul(divicision-feeRate).div(divicision);
        amounts = SwapV2Library.getAmountsOut(factory, amount, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(SwapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));
        _swap(amounts, path, to);
    }
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] memory path, address to, uint deadline)
        internal
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(path[path.length - 1] == WETH, 'SwapRouter: INVALID_PATH');
        amounts = SwapV2Library.getAmountsOut(factory, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            path[0], to, SwapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );
        _swap(amounts, path, address(this));
        // fee
        feeAmount[WETH] += amounts[amounts.length - 1].mul(feeRate).div(divicision);
        // 
        uint256 amountOut = amounts[amounts.length - 1].mul(divicision-feeRate).div(divicision);
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // requires the initial amount to have already been sent to the first pair
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) private {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SwapV2Library.sortTokens(input, output);
            ISwapV2Pair pair = ISwapV2Pair(SwapV2Library.pairFor(factory, input, output));
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
            (uint reserve0, uint reserve1,) = pair.getReserves();
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
            amountOutput = SwapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? SwapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        bool isFrom,
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    ) internal ensure(deadline) {
       if(isFrom){
           _swapExactTokensForTokensSupportingFeeOnTransferTokensForFrom(amountIn, amountOutMin, path, to);
       }else{
           _swapExactTokensForTokensSupportingFeeOnTransferTokensForTo(amountIn, amountOutMin, path, to);
       }
    }

    function _swapExactTokensForTokensSupportingFeeOnTransferTokensForFrom(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to
    ) private  {
        // fee
        uint256 fee = amountIn.mul(feeRate).div(divicision);
        TransferHelper.safeTransferFrom(
            path[0], to, address(this), fee
        );
        feeAmount[path[0]] += fee;
        // swap
        amountIn = amountIn.mul(divicision-feeRate).div(divicision);
        TransferHelper.safeTransferFrom(
            path[0], to, SwapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );

        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function _swapExactTokensForTokensSupportingFeeOnTransferTokensForTo(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to
    ) private  {

        TransferHelper.safeTransferFrom(
            path[0], to, SwapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(address(this));
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint balanceAfter = IERC20(path[path.length - 1]).balanceOf(address(this));
        uint256 amountOut = balanceAfter.sub(balanceBefore);
        require(
            amountOut >= amountOutMin,
            'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
        // fee
        feeAmount[path[path.length-1]] += amountOut.mul(feeRate).div(divicision);
        //
        uint256 amount = amountOut.mul(divicision-feeRate).div(divicision);
        TransferHelper.safeTransfer(path[path.length-1],to, amount);
    }
    

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    )
        internal
        ensure(deadline)
    {
        require(path[0] == WETH, 'SwapRouter: INVALID_PATH');
        feeAmount[WETH] += amountIn.mul(feeRate).div(divicision);
        amountIn = amountIn.mul(divicision-feeRate).div(divicision);
        IWETH(WETH).deposit{value: amountIn}();
        assert(IWETH(WETH).transfer(SwapV2Library.pairFor(factory, path[0], path[1]), amountIn));
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(path, to);
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address to,
        uint deadline
    )
        internal
        ensure(deadline)
    {
        require(path[path.length - 1] == WETH, 'SwapRouter: INVALID_PATH');
        TransferHelper.safeTransferFrom(
            path[0], to, SwapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );
        _swapSupportingFeeOnTransferTokens(path, address(this));
        uint amountReceive = IERC20(WETH).balanceOf(address(this));
        require(amountReceive >= amountOutMin, 'SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).withdraw(amountReceive);
        feeAmount[WETH] += amountReceive.mul(feeRate).div(divicision);
        uint256 amountOut = amountReceive.mul(divicision-feeRate).div(divicision);
        TransferHelper.safeTransferETH(to, amountOut);
    }

     function setFeeRate(uint256 _fee) public onlyOwner{
        require(_fee <= 500);           // 5%
        feeRate = _fee;
    }
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
}

library SwapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'SwapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SwapV2Library: ZERO_ADDRESS');
    }
    
    // 96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f
    // 0b76109834366c3a2eedefea8af2ffdb7fb0130c45d48236e864df8d4814ff33
    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = ISwapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'SwapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'SwapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'SwapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma experimental ABIEncoderV2;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IBotRouter{
    function feeTokens(address token) external returns(bool);
}

contract Tardewiz_limit is ReentrancyGuard, BasicOrder {

    using SafeMath for uint256;

    struct OrderInfo {
        uint256 amountIn;
        address[] path;
        uint256 amountOutMin;
        uint256 deadline;
        uint state;                      // 1 pending 2 success 3 cancle 
        address user;
        uint256 fee;          
    }

    /// @notice user info mapping
    mapping(address => uint256[]) public usersOrders;
    mapping(uint256 => OrderInfo) public orders;
    uint256 public totalGasFee;
    uint256 public currentOrderId = 1;
    
    uint256 public gasFee = 0.005 ether;

    address public botRouter;

    constructor(address _factory, address _WETH) BasicOrder(_factory,_WETH){}

    function setBotRouter(address _router) public onlyOwner{
        require(_router != address(0),"Invalid address");
        botRouter = _router;
    }

    function recoverERC20(address tokenAddress) external onlyOwner {
        uint256 amount = feeAmount[tokenAddress];
        require(amount > 0,"invalid Amount!!");
        if(tokenAddress != WETH){
            TransferHelper.safeTransfer(tokenAddress, msg.sender, amount);
        }else{
            amount += totalGasFee;
            _safeTransferETH(msg.sender,amount);
            totalGasFee = 0;
        }
        feeAmount[tokenAddress] = 0;
	}

    function setGasFeeAmount(uint256 _fee) public onlyOwner {
        require(_fee <= 0.01 ether,"Invalid fee");
        gasFee = _fee;
    }

    function makeOrder(uint256 _amountIn, address[] calldata _path, uint256 _amountOutMin, uint256 _deadline) public payable nonReentrant{
        require(_path.length >= 2, "LimitOrder: INVALID_PATH");
        require(_amountIn > 0 && _amountOutMin > 0 ,"LimitOrder: Invalid amount");
        uint256 fee = gasFee;
        if(_path[0] == WETH){
            fee += _amountIn;
        }else{
            uint256 allowance = IERC20(_path[0]).allowance(msg.sender, address(this));
            require(allowance >= _amountIn,'LimitOrder: Increase Allowance');
        }
        require(msg.value == fee, 'LimitOrder: INVALID_VALUE');
        
        orders[currentOrderId] = OrderInfo({
            amountIn: _amountIn,
            path: _path,
            amountOutMin: _amountOutMin,
            deadline: block.timestamp +_deadline,
            state: 1,
            user: msg.sender,
            fee: gasFee

        });
        usersOrders[msg.sender].push(currentOrderId);
        currentOrderId += 1;
    }

    function cancelOrder(uint256 _orderId) public {
        OrderInfo memory order = orders[_orderId];
        require(order.state == 1,"Invalid state!");
        require(order.deadline > 0, "Invalid Order!");
        if(block.timestamp < order.deadline){
            require(order.user == msg.sender,"Failed!");
        }
        _deleteOrder(order, _orderId, 3);
    }

    function timestamp() public view returns(uint256){
        return block.timestamp;
    }

    function _deleteOrder(OrderInfo memory  order, uint256 _orderId, uint _state) internal{
        orders[_orderId].state = _state;
        if(_state == 3){                // cancel
            if(order.path[0] == WETH ){
                uint256 amount = order.amountIn;
                if(order.user == msg.sender){
                    amount += order.fee;
                }else {
                    _sendToken(WETH, msg.sender, order.fee);
                }
                _sendToken(WETH, order.user, amount);
            }
        }else if (_state == 2){
            totalGasFee += order.fee;
        }
    }

    function _sendToken(address tokenAddress,address to, uint256 amount) internal  {
        if(tokenAddress != WETH){
            TransferHelper.safeTransfer(tokenAddress, to, amount);
        }else{
            _safeTransferETH(to,amount);
        }
	}

    function _safeTransferETH(address to, uint value) private {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    function fromEthNoFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");
       
        swapExactETHForTokens(order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    function fromEthOnFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");

        swapExactETHForTokensSupportingFeeOnTransferTokens(order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    function toEthNoFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");
        swapExactTokensForETH(order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    function toEthOnFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");
        swapExactTokensForETHSupportingFeeOnTransferTokens(order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    function tokenToTokenNoFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");
        bool isFrom = true;
        if(IBotRouter(botRouter).feeTokens(order.path[0]) == false && IBotRouter(botRouter).feeTokens(order.path[order.path.length-1]) == true){
            isFrom = false;
        }
        swapExactTokensForTokens(isFrom, order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    function tokenToTokenOnFee(uint256 _orderId) external returns(bool) {
        OrderInfo memory order = orders[_orderId];
        require(order.deadline >= block.timestamp && order.state == 1,"LimitOrder: Invalid order");
        bool isFrom = true;
        if(IBotRouter(botRouter).feeTokens(order.path[0]) == false && IBotRouter(botRouter).feeTokens(order.path[order.path.length-1]) == true){
            isFrom = false;
        }
        swapExactTokensForTokensSupportingFeeOnTransferTokens(isFrom, order.amountIn, order.amountOutMin, order.path, order.user, order.deadline);
        _deleteOrder(order, _orderId,2);
        return true;
    }

    /**
        ****************************** check functions ******************************
     */

    function getUserOrdersInfo(address user) public view returns(OrderInfo[] memory){
        
        uint256[] memory orderIds = usersOrders[user];
        uint256 length = orderIds.length;
        OrderInfo[] memory userOrders = new OrderInfo[](length);
        for(uint256 i=0;i<length;i++){
            uint256 id = orderIds[i];
            OrderInfo memory order = orders[id];
            userOrders[i] = order;
        }
        return userOrders;
    }

    function getOrderDetails(uint256[] memory _orderIds) public returns(string[] memory){
        uint256 length = _orderIds.length;
        string[] memory results = new string[](length);
        for(uint256 i=0;i<length;i++){
            results[i] = getOrderState(_orderIds[i]);
        }
        return results;
    }

    function getOrderState(uint256 _orderId) public returns(string memory){
        OrderInfo memory order = orders[_orderId];
        if(order.deadline < block.timestamp || order.deadline == 0 || order.state == 2){
            return "";
        }else if (order.state == 3){
            return "cancel";
        }
        address[] memory path = order.path;
        if(path[0] == WETH){
            return tryFromEth(_orderId);
        }else if (path[path.length-1] == WETH){
            return tryToEth(_orderId);
        }else{
            return tryTokenToToken(_orderId);
        }
    }

    function getOrder(uint256 _orderId) public view returns(OrderInfo memory){
        OrderInfo memory order = orders[_orderId];
        return order;
    }

    function tryFromEth(uint256 _orderId) public returns(string memory){
        try this.fromEthNoFee(_orderId) returns(bool) {
            return "fromEthNoFee";
        }catch {
            return "";
        }

        try this.fromEthOnFee(_orderId) returns(bool) {
            return "fromEthOnFee";
        }catch {
            return "";
        }
    }

    function tryToEth(uint256 _orderId) public returns(string memory){
        try this.toEthNoFee(_orderId) returns(bool) {
            return "toEthNoFee";
        }catch {
            return "";
        }

        try this.toEthOnFee(_orderId) returns(bool) {
            return "toEthOnFee";
        }catch {
            return "";
        }
    }

    function  tryTokenToToken(uint256 _orderId) public returns(string memory){
        try this.tokenToTokenNoFee(_orderId) returns(bool) {
            return "tokenToTokenNoFee";
        }catch {
            return "";
        }

        try this.tokenToTokenOnFee(_orderId) returns(bool) {
            return "tokenToTokenOnFee";
        }catch {
            return "";
        }
    }
    

}