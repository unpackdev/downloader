// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransferHelper.sol";

import "./XSDStablecoin.sol";
import "./BankXLibrary.sol";
import "./Initializable.sol";
import "./IRouter.sol";
import "./IPIDController.sol";
import "./IRewardManager.sol";
import "./IXSDWETHpool.sol";
import "./IBankXWETHpool.sol";
import "./IWETH.sol";
//swap first
//then burn 10% using different function maybe
//recalculate price
// do not burn uXSD if there is a deficit
contract Router is IRouter, Initializable {

    address public WETH;
    address public collateral_pool_address;
    address public XSDWETH_pool_address;
    address public BankXWETH_pool_address;
    address public reward_manager_address;
    address public arbitrage;
    address public bankx_address;
    address public xsd_address;
    address public treasury;
    address public smartcontract_owner;
    uint public last_called;
    uint public pid_cooldown;
    uint public block_delay;
    bool public swap_paused;
    bool public liquidity_paused;
    XSDStablecoin private XSD;
    IRewardManager private reward_manager;
    IPIDController private pid_controller;
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'BankXRouter: EXPIRED');
        _;
    }

    function initialize(address _bankx_address, address _xsd_address,address _XSDWETH_pool, address _BankXWETH_pool,address _collateral_pool,address _reward_manager_address,address _pid_address,uint _pid_cooldown,address _treasury, address _smartcontract_owner,address _WETH, uint _block_delay) public initializer {
        require((_bankx_address != address(0))
        &&(_xsd_address != address(0))
        &&(_XSDWETH_pool != address(0))
        &&(_BankXWETH_pool != address(0))
        &&(_collateral_pool != address(0))
        &&(_treasury != address(0))
        &&(_pid_address != address(0))
        &&(_pid_cooldown != 0)
        &&(_smartcontract_owner != address(0))
        &&(_WETH != address(0)), "Zero address detected");
        bankx_address = _bankx_address;
        xsd_address = _xsd_address;
        XSDWETH_pool_address = _XSDWETH_pool;
        BankXWETH_pool_address = _BankXWETH_pool;
        collateral_pool_address = _collateral_pool;
        reward_manager_address = _reward_manager_address;
        reward_manager = IRewardManager(_reward_manager_address);
        pid_controller = IPIDController(_pid_address);
        pid_cooldown = _pid_cooldown;
        XSD = XSDStablecoin(_xsd_address);
        treasury = _treasury;
        WETH = _WETH;
        smartcontract_owner = _smartcontract_owner;
        block_delay = _block_delay;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }
    // add a variable that keeps track of 10% swap burn.
    // **** ADD LIQUIDITY ****
    //creator may add XSD/BankX to their respective pools via this function
    function creatorProvideLiquidity(address pool) internal  {
        if(pool == XSDWETH_pool_address){
            reward_manager.creatorProvideXSDLiquidity();
        }
        else if(pool == BankXWETH_pool_address){
            reward_manager.creatorProvideBankXLiquidity();
        }
    }

    function userProvideLiquidity(address pool, address sender) internal  {
        if(pool == XSDWETH_pool_address){
            reward_manager.userProvideXSDLiquidity(sender);
        }
        else if(pool == BankXWETH_pool_address){
            reward_manager.userProvideBankXLiquidity(sender);
        }
    }

    function refreshPID() internal{
        if(block.timestamp>(last_called+pid_cooldown)){
            pid_controller.systemCalculations();
            last_called = block.timestamp;
        }
    }

    function creatorAddLiquidityTokens(
        address tokenB,
        uint amountB,
        uint deadline
    ) public ensure(deadline) override {
        require(msg.sender == treasury || msg.sender == smartcontract_owner, "ONLY TREASURY & SMARTCONTRACT OWNER");
        require(tokenB == xsd_address || tokenB == bankx_address, "token address is invalid");
        require(amountB>0, "Please enter a valid amount");
        if(tokenB == xsd_address){
            TransferHelper.safeTransferFrom(tokenB, msg.sender, XSDWETH_pool_address, amountB);
            reward_manager.creatorProvideXSDLiquidity();
    }
    else if(tokenB == bankx_address){
        TransferHelper.safeTransferFrom(tokenB, msg.sender, BankXWETH_pool_address, amountB);
        reward_manager.creatorProvideBankXLiquidity();
    }
    }

    function creatorAddLiquidityETH(
        address pool,
        uint256 deadline
    ) external ensure(deadline) payable override {
        require(msg.sender == treasury || msg.sender == smartcontract_owner, "ONLY TREASURY & SMARTCONTRACT OWNER");
        require(pool == XSDWETH_pool_address || pool == BankXWETH_pool_address, "Pool address is invalid");
        require(msg.value>0,"Please enter a valid amount");
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pool, msg.value));
        creatorProvideLiquidity(pool);
    }

    function userAddLiquidityETH(
        address pool,
        uint deadline
    ) external ensure(deadline) payable override{
        require(pool == XSDWETH_pool_address || pool == BankXWETH_pool_address || pool == collateral_pool_address, "Pool address is not valid");
        require(!liquidity_paused, "Liquidity providing has been paused");
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pool, msg.value));
        if(pool==collateral_pool_address){
            reward_manager.userProvideCollatPoolLiquidity(msg.sender, msg.value);
        }
        else{
            userProvideLiquidity(pool, msg.sender);
        }
    }

    function userRedeemLiquidity(address pool, uint deadline) external ensure(deadline) override {
        if(pool == XSDWETH_pool_address){
            reward_manager.LiquidityRedemption(pool,msg.sender);
        }
        else if(pool == BankXWETH_pool_address){
            reward_manager.LiquidityRedemption(pool,msg.sender);
        }
        else if (pool == collateral_pool_address){
            reward_manager.LiquidityRedemption(pool,msg.sender);
        }
    }

    // **** SWAP ****
    function swapETHForXSD(uint amountOut, uint deadline)
        external
        ensure(deadline)
        payable
        override
    {
        //price check
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks");
        require(!swap_paused, "Swaps have been paused");
        (uint reserveA, uint reserveB, ) = IXSDWETHpool(XSDWETH_pool_address).getReserves();
        uint amounts = BankXLibrary.quote(msg.value, reserveB, reserveA);
        require(amounts >= amountOut, 'BankXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(XSDWETH_pool_address, msg.value));
        IXSDWETHpool(XSDWETH_pool_address).swap(amountOut, 0, msg.sender);
        refreshPID();
    }

    function swapXSDForETH(uint amountOut, uint amountInMax, uint deadline)
        external
        ensure(deadline)
        override
    {
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks");
        require(!swap_paused, "Swaps have been paused");
        (uint reserveA, uint reserveB, ) = IXSDWETHpool(XSDWETH_pool_address).getReserves();
        uint amounts = BankXLibrary.quote(amountOut, reserveB, reserveA);
        require(amounts <= amountInMax, 'BankXRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            xsd_address, msg.sender, XSDWETH_pool_address, amountInMax
        );
        IXSDWETHpool(XSDWETH_pool_address).swap(0, amountOut, address(this));
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(msg.sender, amountOut);
        //burn xsd here 
        if(XSD.totalSupply()-CollateralPool(payable(collateral_pool_address)).collat_XSD()>amountOut/10 && !pid_controller.bucket1()){
            XSD.burnpoolXSD(amountInMax/10);
        }
        refreshPID();
    }

    function swapETHForBankX(uint amountOut, uint deadline)
        external
        ensure(deadline)
        override
        payable
    {
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks");
        require(!swap_paused, "Swaps have been paused");
        (uint reserveA, uint reserveB, ) = IBankXWETHpool(BankXWETH_pool_address).getReserves();
        uint amounts = BankXLibrary.quote(msg.value, reserveB, reserveA);
        require(amounts >= amountOut, 'BankXRouter: INSUFFICIENT_OUTPUT_AMOUNT');
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(BankXWETH_pool_address, msg.value));
        IBankXWETHpool(BankXWETH_pool_address).swap(amountOut, 0, msg.sender);
        refreshPID();
    }

    function swapBankXForETH(uint amountOut, uint amountInMax, uint deadline)
        external
        ensure(deadline)
        override
    {
        require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks");
        require(!swap_paused, "Swaps have been paused");
        (uint reserveA, uint reserveB, ) = IBankXWETHpool(BankXWETH_pool_address).getReserves();
        uint amounts = BankXLibrary.quote(amountOut, reserveB, reserveA);
        require(amounts <= amountInMax, 'BankXRouter: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            bankx_address, msg.sender, BankXWETH_pool_address, amountInMax
        );
        IBankXWETHpool(BankXWETH_pool_address).swap(0,amountOut, address(this));
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(msg.sender, amountOut);
        if((BankXToken(bankx_address).totalSupply() - amountOut/10)>BankXToken(bankx_address).genesis_supply()){
            BankXToken(bankx_address).burnpoolBankX(amountOut/10);
        }
        refreshPID();
    }

    function swapXSDForBankX(uint XSD_amount,address sender,uint256 eth_min_amount, uint256 bankx_min_amount, uint deadline)
        external 
        ensure(deadline)
        override
    {   //only msg.sender or arbitrage contract
        require(!swap_paused, "Swaps have been paused");
        require(msg.sender == sender || msg.sender == arbitrage, "Router:UNVERIFIED ADDRESS");
        (uint reserveA, uint reserveB, ) = IXSDWETHpool(XSDWETH_pool_address).getReserves();
        (uint reserve1, uint reserve2, ) = IBankXWETHpool(BankXWETH_pool_address).getReserves();
        uint ethamount = BankXLibrary.quote(XSD_amount, reserveA, reserveB);
        require(eth_min_amount<= ethamount,'XSDETH: EXCESSIVE_INPUT_AMOUNT');
        uint bankxamount = BankXLibrary.quote(eth_min_amount, reserve2, reserve1);
        require(bankx_min_amount<= bankxamount,'ETHBankX: EXCESSIVE_INPUT_AMOUNT');
        TransferHelper.safeTransferFrom(
            xsd_address, sender, XSDWETH_pool_address, XSD_amount
        );
        IXSDWETHpool(XSDWETH_pool_address).swap(0, ethamount, BankXWETH_pool_address);
        IBankXWETHpool(BankXWETH_pool_address).swap(bankxamount,0,sender);
    }

    function swapBankXForXSD(uint bankx_amount, address sender, uint256 eth_min_amount, uint256 xsd_min_amount, uint deadline)
        external
        ensure(deadline)
        override
    {   
        require(!swap_paused, "Swaps have been paused");
        require(msg.sender == sender || msg.sender == arbitrage, "Router:UNVERIFIED ADDRESS");
        (uint reserveA, uint reserveB, ) = IXSDWETHpool(XSDWETH_pool_address).getReserves();
        (uint reserve1, uint reserve2, ) = IBankXWETHpool(BankXWETH_pool_address).getReserves();
        uint ethamount = BankXLibrary.quote(bankx_amount, reserve1, reserve2);
        require(eth_min_amount<=ethamount,'BankXETH: EXCESSIVE_INPUT_AMOUNT');
        uint xsdamount = BankXLibrary.quote(ethamount, reserveB, reserveA);
        require(xsd_min_amount<=xsdamount, "ETHXSD: EXCESSIVE_INPUT_AMOUNT");
        TransferHelper.safeTransferFrom(
            bankx_address, sender, BankXWETH_pool_address, bankx_amount
        );
        IBankXWETHpool(BankXWETH_pool_address).swap(0, ethamount, XSDWETH_pool_address);
        IXSDWETHpool(XSDWETH_pool_address).swap(xsdamount,0,sender);
    }
    
    function setSmartContractOwner(address _smartcontract_owner) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        require(_smartcontract_owner != address(0), "Zero address detected");
        smartcontract_owner = _smartcontract_owner;
    }

    function renounceOwnership() external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        smartcontract_owner = address(0);
    }
    
    // **** LIBRARY FUNCTIONS ****
    function quote(uint amountA, uint reserveA, uint reserveB) public pure  returns (uint amountB) {
        return BankXLibrary.quote(amountA, reserveA, reserveB);
    }

    function pauseSwaps() external {
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        swap_paused = !swap_paused;
    }

    function pauseLiquidity() external {
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        liquidity_paused = !liquidity_paused;
    }
    
    
    function setBankXAddress(address _bankx_address) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        bankx_address = _bankx_address;
    }

    function setXSDAddress(address _xsd_address) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        xsd_address = _xsd_address;
    }

    function setXSDPoolAddress(address _XSDWETH_pool) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        XSDWETH_pool_address = _XSDWETH_pool;
    }

    function setBankXPoolAddress(address _BankXWETH_pool) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        BankXWETH_pool_address = _BankXWETH_pool;
    }

    function setCollateralPool(address _collateral_pool) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        collateral_pool_address = _collateral_pool;
    }

    function setRewardManager(address _reward_manager_address) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        reward_manager_address = _reward_manager_address;
        reward_manager = IRewardManager(_reward_manager_address);
    }

    function setPIDController(address _pid_address, uint _pid_cooldown) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        pid_controller = IPIDController(_pid_address);
        pid_cooldown = _pid_cooldown;
    }

    function setArbitrageAddress(address _arbitrage) external{
        require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
        arbitrage = _arbitrage;
    }
}