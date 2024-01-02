// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CollateralPool.sol";
import "./IXSDWETHpool.sol";
import "./IBankXWETHpool.sol";
import "./XSDStablecoin.sol";
import "./IRouter.sol";
import "./CollateralPoolLibrary.sol";
import "./IPIDController.sol";
import "./BankXToken.sol";

contract Arbitrage is ReentrancyGuard{
    address public xsd_address;
    address public bankx_address;
    address public smartcontract_owner;
    address public router_address;
    address public pid_address;
    address public collateral_pool;
    address public xsd_pool;
    address public bankx_pool;
    address public origin_address;

    uint public arbitrage_paused;
    uint public last_update;
    uint public block_delay;
    bool public pause_arbitrage;

    XSDStablecoin private XSD;
    BankXToken private BankX;
    IPIDController private pid_controller;
    IRouter private Router;

constructor(
        address _xsd_address,
        address _bankx_address,
        address _collateral_pool,
        address _router_address,
        address _pid_controller,
        address _xsd_pool,
        address _bankx_pool,
        address _origin_address,
        address _smartcontract_owner,
        uint _block_delay
    ) {
        require((_smartcontract_owner != address(0))
            && (_origin_address != address(0))
            && (_collateral_pool != address(0))
            && (_xsd_pool != address(0))
            && (_bankx_pool != address(0))
            && (_router_address != address(0))
            && (_xsd_address != address(0))
            && (_bankx_address != address(0))
            && (_pid_controller != address(0))
            , "Zero address detected");
        xsd_address = _xsd_address;
        XSD = XSDStablecoin(_xsd_address);
        bankx_address = _bankx_address;
        BankX = BankXToken(_bankx_address);
        collateral_pool = _collateral_pool;
        router_address = _router_address;
        Router = IRouter(_router_address);
        pid_address = _pid_controller;
        pid_controller = IPIDController(_pid_controller);
        smartcontract_owner = _smartcontract_owner;
        origin_address = _origin_address;
        bankx_pool = _bankx_pool;
        xsd_pool = _xsd_pool;
        block_delay = _block_delay;
    }

function burnBankX(uint256 bankx_amount,uint256 eth_min_amount, uint256 bankx_min_amount, uint256 deadline) external nonReentrant {
    require(pause_arbitrage, "Arbitrage Paused");
    require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks");
    uint256 time_elapsed = block.timestamp - last_update;
    require(time_elapsed >= arbitrage_paused, "internal cooldown not passed");
    uint256 bankx_price = pid_controller.bankx_updated_price();
    uint256 xag_usd_price = XSD.xag_usd_price();
    uint silver_price = (xag_usd_price*(1e4))/(311035);
    require(pid_controller.xsd_updated_price()>(silver_price + (silver_price/1e3)), "BurnBankX:ARBITRAGE ERROR");
    (uint256 xsd_amount) = CollateralPoolLibrary.calcMintAlgorithmicXSD(
    bankx_price, 
    xag_usd_price,
    bankx_amount
    );
    BankX.pool_burn_from(msg.sender, bankx_amount);
    XSD.pool_mint(msg.sender, xsd_amount);
    Router.swapXSDForBankX(xsd_amount,msg.sender, eth_min_amount, bankx_min_amount,deadline);
    pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
    last_update = block.timestamp;
    pid_controller.systemCalculations();
}

function burnXSD(uint256 XSD_amount,uint256 eth_min_amount, uint256 xsd_min_amount, uint256 deadline) external nonReentrant {
    require(pause_arbitrage, "Arbitrage Paused");
    require(((pid_controller.lastPriceCheck(msg.sender).lastpricecheck+(block_delay)) <= block.number) && (pid_controller.lastPriceCheck(msg.sender).pricecheck), "Must wait for block_delay blocks");
    uint256 time_elapsed = block.timestamp - last_update;
    require(time_elapsed >= arbitrage_paused, "internal cooldown not passed");
    uint256 xag_usd_price = XSD.xag_usd_price();
    uint silver_price = (xag_usd_price*(1e4))/(311035); 
    require(pid_controller.xsd_updated_price()<(silver_price - (silver_price/1e3)), "BurnXSD:ARBITRAGE ERROR");
    uint256 bankx_dollar_value_d18 = (XSD_amount*xag_usd_price)/(31103477); 
    uint256 bankx_amount = (bankx_dollar_value_d18*(1e6))/pid_controller.bankx_updated_price();
    if(XSD.totalSupply()>CollateralPool(payable(collateral_pool)).collat_XSD()){
        XSD.pool_burn_from(msg.sender,XSD_amount);    }
    else{
        TransferHelper.safeTransferFrom(xsd_address, msg.sender,origin_address, XSD_amount);
    }
    BankX.pool_mint(msg.sender, bankx_amount);
    Router.swapBankXForXSD(bankx_amount,msg.sender, eth_min_amount, xsd_min_amount,deadline);
    pid_controller.lastPriceCheck(msg.sender).pricecheck = false;
    last_update = block.timestamp;
    pid_controller.systemCalculations();
}
function setArbitrageCooldown(uint sec) external {
    require(msg.sender == smartcontract_owner, "Only the owner can access this function");
    arbitrage_paused = block.timestamp + sec;
}
function pauseArbitrage() external {
    require(msg.sender == smartcontract_owner, "Only the owner can access this function");
    pause_arbitrage = !pause_arbitrage;
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

function resetAddresses(address _xsd_address,
        address _bankx_address,
        address _collateral_pool,
        address _router_address,
        address _pid_controller,
        address _xsd_pool,
        address _bankx_pool,
        address _origin_address,
        address _smartcontract_owner, 
        uint _block_delay) external{
    require(msg.sender == smartcontract_owner, "Only the smart contract owner can access this function");
    require((_smartcontract_owner != address(0))
            && (_origin_address != address(0))
            && (_collateral_pool != address(0))
            && (_xsd_pool != address(0))
            && (_bankx_pool != address(0))
            && (_router_address != address(0))
            && (_xsd_address != address(0))
            && (_bankx_address != address(0))
            && (_pid_controller != address(0))
            , "Zero address detected");
        xsd_address = _xsd_address;
        XSD = XSDStablecoin(_xsd_address);
        bankx_address = _bankx_address;
        BankX = BankXToken(_bankx_address);
        collateral_pool = _collateral_pool;
        router_address = _router_address;
        Router = IRouter(_router_address);
        pid_address = _pid_controller;
        pid_controller = IPIDController(_pid_controller);
        smartcontract_owner = _smartcontract_owner;
        origin_address = _origin_address;
        bankx_pool = _bankx_pool;
        xsd_pool = _xsd_pool;
        block_delay = _block_delay;
}
}