// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./console.sol";

import "./ERC20.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./uniswaprouter.sol";


contract bidelityLimitOrder is Initializable,OwnableUpgradeable {
    
    IUniswapRouter02 public uniswapRouter02;
    
    enum OrderState {Created, Cancelled, Finished}
    enum OrderType {EthForTokens, TokensForEth, TokensForTokens}
    struct Insight {
        address addressA;
        address addressB;
        uint decimalsA;
        uint decimalsB;
        bool locked;
        uint totalOrders;
        uint totalTraders;
        uint commissionA;
        uint commissionB;
    }
    
    struct Limit {
        OrderType orderType;
        address assetIn;
        address assetOut; 
        uint assetInOffered;
        uint assetOutExpected;
        uint price;
        uint slippage;
        address[] path;
        uint executorFee;
        uint expire;
    }
    struct Order {
        OrderState orderState;
        OrderType orderType;
        address payable traderAddress;
        address assetIn;
        address assetOut;
        uint assetInOffered;
        uint assetOutExpected;
        uint executorFee;
        uint stake;
        uint id;
        uint ordersI;
        address[] path;
        uint price;//1e18
        uint slippage;//1e18
        uint expire;
        uint inDecimals;
        uint outDecimals;
        uint created;
        uint updated;
                
    }
    uint public MAXPOSITIONS;    
    uint public STAKE_FEE;
    uint public EXECUTOR_FEE;
    uint[] public orders;
    uint public ordersNum;
    address public executor;
    address payable  public stakeAddress;
    
    event logOrderCreated(
        uint id,
        OrderState orderState, 
        OrderType orderType, 
        address traderAddress, 
        address assetIn, 
        address assetOut,
        uint assetInOffered, 
        uint assetOutExpected, 
        uint executorFee
    );
    event logOrderCancelled(uint id, address payable traderAddress, address assetIn, address assetOut, uint refundETH, uint refundToken);
    event logOrderExecuted(uint id, address executor, uint amount);
    
    mapping(uint => Order) public orderBook;
    mapping(address => uint[]) private ordersForAddress;
    mapping(bytes32=>Insight) public insightInfo;
    bytes32[] public insightId;
    mapping(bytes32=>mapping(address=>bool)) recordedTrader;
    modifier onlyExecutor() {
        require(_msgSender() == executor , "Executable: caller is not the executor");
        _;
    }   
    
    function getKeyPair(address aA,address aB) internal pure returns(bytes32 key){
        if(aA<aB){
            key = keccak256(
                abi.encodePacked(aA,aB)
            );
        }else{
            key = keccak256(
                abi.encodePacked(aB,aA)
            );
        }
    }

    function updateUnlock(bytes32 key,bool locked) external onlyOwner {
        insightInfo[key].locked = locked;
    }
    function update_executor(address _executor) external onlyOwner {
        executor = _executor;
    }

    function initialize(IUniswapRouter02 _uniswapRouter02) public initializer {
        __Ownable_init(_msgSender());
        executor = _msgSender();
        stakeAddress = payable(_msgSender());
        uniswapRouter02 = _uniswapRouter02;
        MAXPOSITIONS = 100;    
        STAKE_FEE = 35*1e14;
        EXECUTOR_FEE = 1e15;
        ordersNum = 0;
    }
    function setUniswapRouter(IUniswapRouter02 _uniswapRouter02) external onlyOwner {
        uniswapRouter02 = _uniswapRouter02;
    }
    function setNewStakeFee(uint256 _STAKE_FEE) external onlyOwner {
        STAKE_FEE = _STAKE_FEE;
    }
    
    function setNewExecutorFee(uint256 _EXECUTOR_FEE) external onlyOwner {
        EXECUTOR_FEE = _EXECUTOR_FEE;
    }
    
    function setNewStakeAddress(address _stakeAddress) external onlyOwner {
        require(_stakeAddress != address(0), 'Do not use 0 address');
        stakeAddress = payable(_stakeAddress);
    }
    
    
    function updateOrder(Order memory order, OrderState newState) internal {
        if(orders.length > 1) {
            uint openId = order.ordersI;
            uint lastId = orders[orders.length-1];
            Order memory lastOrder = orderBook[lastId];
            lastOrder.ordersI = openId;
            orderBook[lastId] = lastOrder;
            orders[openId] = lastId;
        }
        orders.pop();
        order.orderState = newState;
        order.updated = block.timestamp;
        orderBook[order.id] = order;        
    }

    function createOrder(
        Limit calldata limit_info
    ) external payable {
        
        uint payment = msg.value;
        uint stakeValue = 0;
        
        require(limit_info.assetInOffered > 0, "Asset in amount must be greater than 0");
        require(limit_info.assetOutExpected > 0, "Asset out amount must be greater than 0");
        require(limit_info.executorFee >= EXECUTOR_FEE, "Invalid fee");
        
        if(limit_info.orderType == OrderType.EthForTokens) {
            require(limit_info.assetIn == uniswapRouter02.WETH(), "Use WETH as the assetIn");
            stakeValue = limit_info.assetInOffered*STAKE_FEE/1e18;
            require(payment >= (limit_info.assetInOffered+limit_info.executorFee+stakeValue), "Payment = assetInOffered + executorFee + stakeValue");
            
        }
        else {
            require(payment >= limit_info.executorFee, "Transaction value must match executorFee");
            if (limit_info.orderType == OrderType.TokensForEth) { require(limit_info.assetOut == uniswapRouter02.WETH(), "Use WETH as the assetOut"); }
            stakeValue = limit_info.assetInOffered*STAKE_FEE/1e18;
            ERC20(limit_info.assetIn).transferFrom(_msgSender(), address(this), limit_info.assetInOffered+stakeValue);
        }
        
        uint orderId = ordersNum;
        ordersNum++;
        
        
        orderBook[orderId] = Order(OrderState.Created, limit_info.orderType, payable(_msgSender()), 
        limit_info.assetIn, limit_info.assetOut, 
        limit_info.assetInOffered, limit_info.assetOutExpected, 
        limit_info.executorFee, stakeValue, orderId, orders.length,
        limit_info.path,limit_info.price,limit_info.slippage,limit_info.expire,
        ERC20(limit_info.assetIn).decimals(),ERC20(limit_info.assetOut).decimals(),block.timestamp,block.timestamp);
        
        ordersForAddress[_msgSender()].push(orderId);
        orders.push(orderId);
        
        bytes32 key = getKeyPair(limit_info.assetIn,limit_info.assetOut);
        if(insightInfo[key].addressA==address(0)){
            address aA = limit_info.assetIn<limit_info.assetOut?limit_info.assetIn:limit_info.assetOut;
            address aB = limit_info.assetIn<limit_info.assetOut?limit_info.assetOut:limit_info.assetIn;
            insightInfo[key] = Insight(
                aA,
                aB,
                ERC20(aA).decimals(),
                ERC20(aB).decimals(),
                false,
                0,
                0,
                0,
                0
            );
            insightId.push(key);
        }
        require(insightInfo[key].locked==false,"Pair locked");

        insightInfo[key].totalOrders = insightInfo[key].totalOrders+1;
        if(recordedTrader[key][_msgSender()]==false){
            recordedTrader[key][_msgSender()] = true;
            insightInfo[key].totalTraders = insightInfo[key].totalTraders + 1;
        }

        emit logOrderCreated(
            orderId, 
            OrderState.Created, 
            limit_info.orderType, 
            _msgSender(), 
            limit_info.assetIn, 
            limit_info.assetOut,
            limit_info.assetInOffered, 
            limit_info.assetOutExpected, 
            limit_info.executorFee
        );
    }
    function needUpdate(uint offset,uint size) external view returns(bool need){
        if(orders.length==0){
            need = false;
        }else{
            uint256 last_order_id = size==0?orders.length-1:offset+size-1;
            if(last_order_id>=orders.length) last_order_id = orders.length-1;
            uint[] memory amountsOut;
            for(uint256 order_id =last_order_id ; order_id>=offset ;order_id--){
                Order memory order = orderBook[orders[order_id]];  
                if(order.expire<block.timestamp){
                    need = true;
                    break;
                }else{
                    amountsOut = uniswapRouter02.getAmountsOut(order.assetInOffered, order.path);
                
                    if(getExpectedOut(amountsOut,0)>=order.assetOutExpected){
                        need= true;
                        break;
                    }
                }
                if(order_id==0) break;
            }
        }
    }
    function executeOrders(uint offset,uint size) external {
        if(orders.length==0){
            return;
        }else{
            uint256 last_order_id = size==0?orders.length-1:offset+size-1;
            if(last_order_id>=orders.length) last_order_id = orders.length-1;
            for(uint256 order_id =last_order_id ; order_id>=offset ;order_id--){
                if(orderBook[orders[order_id]].expire<block.timestamp){
                    _cancelOrder(orders[order_id]);
                }else{
                    executeOrder(orders[order_id]);
                }
                if(order_id==0) break;
            }


        }
    }
    function getExpectedOut(uint[] memory amountsOut,uint slippage) internal pure returns (uint amountOut){
        amountOut = amountsOut[amountsOut.length-1]*(1e18-slippage)/1e18;
    }
    function executeOrder(uint orderId) internal returns (bool success)   {
        Order memory order = orderBook[orderId];  
        require(order.traderAddress != address(0), "Invalid order");
        require(order.orderState == OrderState.Created, 'Invalid order state');
        
    
        uint[] memory amountsOut;
        success = false;
        uint amountOutExactly;
        if (order.orderType == OrderType.EthForTokens) {
            
            amountsOut = uniswapRouter02.getAmountsOut(order.assetInOffered, order.path);
            
            if(getExpectedOut(amountsOut,0)>=order.assetOutExpected){
                try uniswapRouter02.swapExactETHForTokens{value:order.assetInOffered}(getExpectedOut(amountsOut,order.slippage), order.path, order.traderAddress, block.timestamp) returns (uint[] memory result) {
                    amountOutExactly = result[result.length-1];
                    success = true;
                    stakeAddress.transfer(order.stake);
                }catch {
                }
            }
        }
        else if (order.orderType == OrderType.TokensForEth) {

            amountsOut = uniswapRouter02.getAmountsOut(order.assetInOffered, order.path);

            if(getExpectedOut(amountsOut,0)>=order.assetOutExpected){
                ERC20(order.assetIn).approve(address(uniswapRouter02), order.assetInOffered);
                try uniswapRouter02.swapExactTokensForETH(order.assetInOffered, getExpectedOut(amountsOut,order.slippage), order.path, order.traderAddress, block.timestamp) returns (uint[] memory result) {
                    success = true;
                    amountOutExactly = result[result.length-1];
                    ERC20(order.assetIn).transfer(stakeAddress, order.stake);
                }catch {
                }
            }
        }
        else if (order.orderType == OrderType.TokensForTokens) {

            amountsOut = uniswapRouter02.getAmountsOut(order.assetInOffered, order.path);
            
            if(getExpectedOut(amountsOut,0)>=order.assetOutExpected){
                ERC20(order.assetIn).approve(address(uniswapRouter02), order.assetInOffered);
                try uniswapRouter02.swapExactTokensForTokens(order.assetInOffered, getExpectedOut(amountsOut,order.slippage), order.path, order.traderAddress, block.timestamp) returns (uint[] memory result) {
                    success = true;
                    amountOutExactly = result[result.length-1];
                    ERC20(order.assetIn).transfer(stakeAddress, order.stake);
                }catch {
                }
            }

        }
        if(success){
            updateOrder(order, OrderState.Finished);
            payable(_msgSender()).transfer(order.executorFee);

            bytes32 key = getKeyPair(order.assetIn,order.assetOut);
            if(order.assetIn<order.assetOut){
                insightInfo[key].commissionA = insightInfo[key].commissionA + order.stake;
            }else{
                insightInfo[key].commissionB = insightInfo[key].commissionB + order.stake;
            }

            emit logOrderExecuted(order.id, _msgSender(), amountOutExactly);
        }
    }
    function _cancelOrder(uint orderId) internal {
        Order memory order = orderBook[orderId];  
        require(order.traderAddress != address(0), "Invalid order");
        require(_msgSender() == order.traderAddress, 'This order is not yours');
        require(order.orderState == OrderState.Created, 'Invalid order state');
        
        updateOrder(order, OrderState.Cancelled);
        
        uint refundETH = 0;
        uint refundToken = 0;
        
        if (order.orderType != OrderType.EthForTokens) {

            refundETH = order.executorFee;
            refundToken = order.assetInOffered+order.stake;
            (order.traderAddress).transfer(refundETH);
            ERC20(order.assetIn).transfer(order.traderAddress, refundToken);
        }
        else {
            refundETH = order.assetInOffered+order.executorFee+order.stake;
            (order.traderAddress).transfer(refundETH);
        }
        
        emit logOrderCancelled(order.id, order.traderAddress, order.assetIn, order.assetOut, refundETH, refundToken);        
    }
    
    function cancelOrder(uint orderId) external {
        _cancelOrder(orderId);
    }
    
    function calculatePaymentETH(uint ethValue) external view returns (uint valueEth, uint stake, uint executorFee, uint total) {
        uint pay = ethValue;
        uint stakep = pay*STAKE_FEE/1e18;
        uint totalp = (pay+stakep+EXECUTOR_FEE);
        return (pay, stakep, EXECUTOR_FEE, totalp);
    }
    
    function getOrdersLength() external view returns (uint) {
        return orders.length;
    }
    function getOrdersForAddress(address _address,uint offset ) public view returns(Order[] memory,uint) {
        uint totalCount = 0;
        Order[]  memory orders_address = new Order[](MAXPOSITIONS);
        for(uint i=offset;i<ordersForAddress[_address].length;i++){
            orders_address[totalCount] = orderBook[ordersForAddress[_address][i]];
            totalCount++;
            if(totalCount>=MAXPOSITIONS-1) break;

        }
        return(orders_address,totalCount);
    }
    function getOrdersForAddressLength(address _address) external view returns (uint)
    {
        return ordersForAddress[_address].length;
    }

    function getOrderIdForAddress(address _address, uint index) external view returns (uint)
    {
        return ordersForAddress[_address][index];
    }    

    function withdraw(address _token, uint256 _amount,address to) onlyOwner external  {
        require(ERC20(_token).transfer(to, _amount), 'transferFrom() failed.');
    }

    function payout () public onlyOwner returns(bool res) {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
        return true;
    }   

    function getInsight(uint offset,uint size ) public view returns(Insight[] memory,uint){

        uint totalCount = 0;
        Insight[]  memory insightTotal = new Insight[](size);
        for(uint i=offset;i<insightId.length;i++){
            insightTotal[totalCount] = insightInfo[insightId[i]];
            totalCount++;
            if(totalCount>=size) break;
        }
        return(insightTotal,totalCount);

    }

    function getOpenOrders(uint offset,uint size ) public view returns(Order[] memory,uint){

        uint totalCount = 0;
        Order[]  memory orders_total = new Order[](size);
        for(uint i=offset;i<orders.length;i++){
            orders_total[totalCount] = orderBook[orders[i]];
            totalCount++;
            if(totalCount>=size) break;
        }
        return(orders_total,totalCount);

    }
 
    function getOrders(uint offset,uint size ) public view returns(Order[] memory,uint){
        uint totalCount = 0;
        Order[]  memory orders_total = new Order[](size);
        for(uint i=offset;i<ordersNum;i++){
            orders_total[totalCount] = orderBook[i];
            totalCount++;
            if(totalCount>=size) break;
        }
        return(orders_total,totalCount);

    }

    receive() external payable {}
    
}