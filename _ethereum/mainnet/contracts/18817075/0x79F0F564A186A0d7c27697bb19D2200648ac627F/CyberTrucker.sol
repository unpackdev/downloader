/*

$CTRUCK - CyberTrucker

Drive a CyberTruck to the moon or hitch a ride in one. Sell tickets in $CTRUCK or $ETH for your CyberTruck ride. Snipe and Resale purchased tickets for profit! Trucker who holds the ALL TIME record for highest tickets ever in circulation, gets 2 percent $CTRUCK buy and sell tax. 

This Contract implements the $CTRUCK ERC20 and CyberTrucker Game IN ENTIRETY. Liquidity will be LOCKED post Launch on our telegram portal. Contract will be renounced within the lock period. Interact with this contract directly using scripts shared on our gitbook or use our upcoming Dapp on our website or on IPFS.

Total Supply of $CTRUCK is 420 million. 5% is assigned to the Team and 95% added to LP on UniSwap v2. 

Usage of any other dapps or bots to interact with this contract is at your own risk!

CyberTrucker resides entirely ON CHAIN.

First ticket is reserved for the Trucker and cannot be sold. 
Trucker shall pick his own road to the moon, while buying the first ticket, on both $CTRUCK and $ETH. Road CANNOT be modified once set.


Fire topTrucker() and topLoad() on the contract to get the address and all time record supply of top trucker
Events: 
	TicketTrade - Info on the ticket trade
	TruckerMooned - Address of mooned trucker along with his all time record for tickets in circulation
	TradingEnabled - Fairlaunch on Uniswap
	TicketEnabled - Gameplay enabled
	MaxTxAmountUpdated - max tokens an address can hold
	Transfer - ERC20
    Approval - ERC20

CyberTrucker:
https://t.me/CyberTrucker_Portal

Links:
https://CyberTrucker.fun/
https://t.me/CyberTrucker_Portal
https://twitter.com/CyberTruckerERC
https://CyberTrucker.gitbook.io/CyberTrucker/
https://github.com/cybertrucker-erc/CTruckLaunchKit

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//import "./console.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable is Context {
    address public _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
contract CyberTrucker is Context, IERC20, Ownable {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address payable private _taxWallet;
    address private team1;
	address private team2;
	address private team3;
	address private team4;
	address private team5;

    uint256 private _tax = 40; //40%
    uint256 private _tier1 = 20; //20%
    uint256 private _tier2 = 15; //15%
    uint256 private _tier3 = 10; //10%
    uint256 private _tier4 = 4; //4%
    

    // Reduction Rules
    uint256 private _buyCount = 0;
    uint256 private _rPeriod0 = 60;
    uint256 private _rPeriod1 = 120; 
    uint256 private _rPeriod2 = 300; 
    uint256 private _rPeriod3 = 600;  
    

    uint256 private _tradingOpened;

    bool private ticketEnabled = false;
    bool private setupComplete = false;


    // Token Information
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 420000000 * 10**_decimals;
    string private constant _name = unicode"CyberTrucker";
    string private constant _symbol = unicode"CTRUCK";

    // Contract Swap Rules             
    uint256 private _taxSwapThreshold= 420000 * 10**_decimals; //0.1%
    uint256 private _maxTaxSwap= 4200000 * 10**_decimals; //1%
    uint256 private _maxInitHold= 4200000 * 10**_decimals; //1%
    uint256 private _maxTeamHold= 21000000 * 10**_decimals; //5%

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    bool private inSwap = false;
    

	address private protocolFeeWallet;
    uint256 private protocolFeePercent = 10000000000000000;
    uint256 private truckerFeePercent = 10000000000000000; 
    uint256 private topFeePercent = 5000000000000000; 


    //id=0-eth,id=1-ctruck

    mapping(address => mapping(uint256 => mapping(address => uint256))) public ticketsBalance;
    mapping(address => mapping(uint256 => uint256)) public ticketsSupply;
    mapping(address => mapping(uint256 => uint256)) public ticketsRoad;
    mapping(address => mapping(uint256 => uint256)) public ticketsDirection;
    mapping(address => mapping(uint256 => uint256)) private ticketsReserve;

    address payable topTrucker;
    uint256 topLoad;
    
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event TruckerMooned(address trucker, uint256 topLoad);
    event TicketEnabled();
    event TradingEnabled();
    event TicketTrade(address trader, address trucker, address topTrucker, bool isBuy, uint256 ticketAmount, uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 topEthAmount, uint256 supply);

    event TicketTradeNative(address trader, address trucker, address topTrucker, bool isBuy, uint256 ticketAmount, uint256 cyberAmount, uint256 protocolCyberAmount, uint256 subjectCyberAmount, uint256 topCyberAmount, uint256 supply);

    struct FeeInfo {
	  uint256 price;
	  uint256 protocolFee;
	  uint256 truckerFee;
	  uint256 topFee;

	}

	
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
    	//owner and taxwallet are same here!
        _owner = _msgSender();
        
        team1 = 0xc3241f86E558A38f96b18e92B4DBC700278ef95D;
		team2 = 0xc8F9599b1707F9b77491881315A239f8C7CDFC3C;
		team3 = 0xC35d7A31c469Eb3eA61355418095E33Bac30c372;
		team4 = 0xc1810fC42Ce1AAC89b5D75884FF53232a9c372Df;
		team5 = 0x67eD4fdDC48292d16D75fEAe525813539e5D4e7E;

        _taxWallet = payable(team1);
        
        //owner is the first topTrucker
        topTrucker = payable(_owner);
        topLoad = 0;
        protocolFeeWallet = _taxWallet;

        //assign 95% to LP
        _balances[_owner] = _tTotal - _maxTeamHold;
        emit Transfer(address(0), _owner, _tTotal - _maxTeamHold);

        //assign 5% to team
        _balances[team1] = _maxTeamHold/5;
        _balances[team2] = _maxTeamHold/5;
        _balances[team3] = _maxTeamHold/5;
        _balances[team4] = _maxTeamHold/5;
        _balances[team5] = _maxTeamHold/5;

        emit Transfer(address(0), team1, _maxTeamHold/5);
        emit Transfer(address(0), team2, _maxTeamHold/5);
        emit Transfer(address(0), team3, _maxTeamHold/5);
        emit Transfer(address(0), team4, _maxTeamHold/5);
        emit Transfer(address(0), team5, _maxTeamHold/5);

        emit MaxTxAmountUpdated(_maxInitHold);

    }

    function setUpUniSwap(uint addLiq) public onlyOwner{
        require(!setupComplete);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        if(addLiq>0) {
            _balances[address(this)] = _tTotal - _maxTeamHold;
            _balances[owner()] = 0;
            emit Transfer(owner(), address(this), _tTotal - _maxTeamHold);
            uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        }

        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        setupComplete = true;
        if(addLiq>0) 
            startTrading();


    }

    function startTrading() public onlyOwner{
    	require(!tradingOpen && setupComplete);
        tradingOpen = true;
        _tradingOpened = block.timestamp;
        emit TradingEnabled();

    }

    function startTicketing() public onlyOwner{
    	require(!ticketEnabled && tradingOpen);
    	ticketEnabled = true;
    	emit TicketEnabled();
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(amount <= _allowances[sender][_msgSender()]);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from 0");
        require(spender != address(0), "ERC20: approve to 0");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setTax() private {
        if(_tax != _tier4) {
            if (block.timestamp >= (_tradingOpened + _rPeriod3)) {
                _tax = _tier4; 
                emit MaxTxAmountUpdated(_tTotal);
            }
            else if (block.timestamp >= (_tradingOpened + _rPeriod2)) {
                _tax = _tier3;
            }
            else if (block.timestamp >= (_tradingOpened + _rPeriod1)) {
                _tax = _tier2; 
            }
            else if (block.timestamp >= (_tradingOpened + _rPeriod0)) {       
                _tax = _tier1; 
            }        
            
        }

    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: from 0");
        require(to != address(0), "ERC20: to 0");
        require(amount > 0, ">0");

        uint256 taxAmount=0;

        if (from != owner() && to != owner()) {
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
            	//buy from uniswap
                require(tradingOpen == true);
            	if(_tax > _tier4 && from != address(this)) {
            		//whale sniper protection.
            		//block if address total goes over 1%
            		require((_balances[to] + amount) <= _maxInitHold, "limit hit");
            	}
            	taxAmount = amount * _tax / 100;
                _buyCount++;
                //Enable Gameplay on 5000 buys
                if(_buyCount >= 5000 && !ticketEnabled) {
                	ticketEnabled = true;
                	emit TicketEnabled();
                }
                _setTax();
            }
            if(to == uniswapV2Pair && from!= address(this) ){
            	//sell from uniswap
                require(tradingOpen == true);
                taxAmount = amount * _tax / 100;
                _setTax();
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && contractTokenBalance > _taxSwapThreshold) {
            	//we swap only on sell to uniswap pool
                swapTokensForEth(min(contractTokenBalance, _maxTaxSwap));
                
                recoverEth();
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)] + (taxAmount/2);
          _balances[topTrucker]=_balances[address(this)] + (taxAmount/2);
          emit Transfer(from, address(this), taxAmount/2);
          emit Transfer(from, topTrucker, taxAmount/2);
        }

        _balances[from]=_balances[from] - amount;
        _balances[to]=_balances[to] + amount - taxAmount;

        emit Transfer(from, to, amount - taxAmount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    //this method is useless post renouncing.
    function recoverEth() public onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0) {
            sendETHToFee(address(this).balance);
        }

    }


    function setRoad(uint256 road, uint256 id) private {
        require(road >= 0 && road < 2);
        //Allow only once! last share is never sold, so supply can never be 0 again!
        require(ticketsSupply[msg.sender][id] == 0);
        ticketsRoad[msg.sender][id] = road;
    }


    function setticketsDirection(uint256 direction, uint256 id) private {
        require(ticketsSupply[msg.sender][id] == 0);
        require(direction > 0 && direction < 1000000);
        ticketsDirection[msg.sender][id] = direction;
    }


    function getPrice(address trucker, uint256 id, uint256 amount, bool isSale, uint256 road, uint256 direction) public view returns (uint256) {
        uint256 supply = ticketsSupply[trucker][id];
        uint256 price = 0;
        //uint256 road
        if(road == 4)
            road = ticketsRoad[trucker][id];
        if(direction == 0)
            direction = ticketsDirection[trucker][id];
        if(road == 0) {
            if(isSale) {
                supply = supply - amount;
            }
            price = getPriceExponential(supply, amount);

        } else if(road == 1) {          
            if(isSale) {
                price = ticketsReserve[trucker][id] - (((ticketsSupply[trucker][id]-amount) * (ticketsSupply[trucker][id]-amount + 1) / 2) * (1 ether/direction));
            } else {
                price = (((ticketsSupply[trucker][id]+amount) * (ticketsSupply[trucker][id]+amount + 1) / 2) * (1 ether/direction) - ticketsReserve[trucker][id]);
                //console.log(price);
            }        
        }

        return price;
        
    }

    function getPriceExponential(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1 )* (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1 ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 16000;
    }

    function getBuyPriceAfterFee(address trucker, uint256 id, uint256 amount, uint256 road, uint256 direction) public view returns (uint256) {
        uint256 price = getPrice(trucker, id, amount, false, road, direction);
        uint256 protocolFee = price * protocolFeePercent * (id==0?3:1) / 1 ether;
        uint256 subjectFee = price * truckerFeePercent / 1 ether;
        uint256 topFee = price * topFeePercent / 1 ether;
        return price + protocolFee + subjectFee + topFee;
    }

    function getSellPriceAfterFee(address trucker, uint256 id, uint256 amount) public view returns (uint256) {
        uint256 price = getPrice(trucker, id, amount, true, 4, 0);
        uint256 protocolFee = price * protocolFeePercent * (id==0?3:1) / 1 ether;
        uint256 subjectFee = price * truckerFeePercent / 1 ether;
        uint256 topFee = price * topFeePercent / 1 ether;
        return price - protocolFee - subjectFee - topFee;
    }


    function initRoad(uint256 id, uint256 amount, uint256 supply, uint256 direction, uint256 road, address trucker, FeeInfo memory feeInfo) private {
    	if(supply == 0 && trucker == msg.sender) {
            setRoad(road, id);
            
            //if linear 
            if(road == 1) 
                setticketsDirection(direction, id);
             
            
        }
        feeInfo.price = getPrice(trucker, id, amount, false, 4, 0);
        feeInfo.protocolFee = feeInfo.price * protocolFeePercent * (id==0?3:1) / 1 ether;
        feeInfo.truckerFee = feeInfo.price * truckerFeePercent / 1 ether;
        feeInfo.topFee = feeInfo.price * topFeePercent / 1 ether;
        require(supply > 0 || trucker == msg.sender, "first");
    }

    function updateTickets(address trucker, uint256 id, uint256 amount, uint256 supply, uint256 price) private {
    	ticketsBalance[trucker][id][msg.sender] +=  amount;
        ticketsSupply[trucker][id] = supply + amount;
        ticketsReserve[trucker][id] += price;

        if(ticketsSupply[trucker][0] + ticketsSupply[trucker][1] > topLoad) {
        	topLoad = ticketsSupply[trucker][0] + ticketsSupply[trucker][1];
        	topTrucker = payable(trucker);
        	emit TruckerMooned(topTrucker, topLoad);
        }

    }

    function buyTicketsEth(address trucker, uint256 amount, uint road, uint256 direction) public payable {
    	require(ticketEnabled);
    	FeeInfo memory feeInfo;
    	uint256 id = 0; //eth
        uint256 supply = ticketsSupply[trucker][id];

        initRoad(id, amount, supply, direction, road, trucker, feeInfo);
        //console.log(feeInfo.price + feeInfo.protocolFee + feeInfo.truckerFee + feeInfo.topFee);
        require(msg.value >= feeInfo.price + feeInfo.protocolFee + feeInfo.truckerFee + feeInfo.topFee, "Less");

        
        updateTickets(trucker, id, amount, supply, feeInfo.price);
        
        emit TicketTrade(msg.sender, trucker, topTrucker, true, amount, feeInfo.price, feeInfo.protocolFee, feeInfo.truckerFee, feeInfo.topFee, supply + amount);
        (bool success1, ) = protocolFeeWallet.call{value: feeInfo.protocolFee}("");
        (bool success2, ) = trucker.call{value: feeInfo.truckerFee}("");
        (bool success3, ) = topTrucker.call{value: feeInfo.topFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }

    function buyTicketsCT(address trucker, uint256 amount, uint road, uint256 direction) public  {
    	require(ticketEnabled);
    	FeeInfo memory feeInfo;
    	uint256 id = 1; //cybertrucker
        uint256 supply = ticketsSupply[trucker][id];
        initRoad(id, amount, supply, direction, road, trucker, feeInfo);
        

        //check erc20balances[sharesSubject].
        //we will check n update users erc20 balance here!
        require(_balances[msg.sender] >= feeInfo.price + feeInfo.protocolFee + feeInfo.truckerFee + feeInfo.topFee, "Less");
        
        updateTickets(trucker, id, amount, supply, feeInfo.price);

        _balances[protocolFeeWallet] += feeInfo.protocolFee;
        _balances[trucker] += feeInfo.truckerFee;
        _balances[topTrucker] += feeInfo.topFee;
        _balances[address(this)] += feeInfo.price;
        _balances[msg.sender] -= (feeInfo.price + feeInfo.protocolFee + feeInfo.truckerFee + feeInfo.topFee);
        
        emit Transfer(msg.sender, protocolFeeWallet, feeInfo.protocolFee);
        emit Transfer(msg.sender, trucker, feeInfo.truckerFee);
        emit Transfer(msg.sender, topTrucker, feeInfo.topFee);
        emit Transfer(msg.sender, address(this), feeInfo.price);

        emit TicketTradeNative(msg.sender, trucker, topTrucker, true, amount, feeInfo.price, feeInfo.protocolFee, feeInfo.truckerFee, feeInfo.topFee, supply + amount);

        
    }

    function updateTicketsSell(address trucker, uint256 id, uint256 amount, uint256 supply, FeeInfo memory feeInfo) private {       
        require(ticketsBalance[trucker][id][msg.sender] >= amount, "less");

        feeInfo.price = getPrice(trucker, id, amount, true, 4, 0);
        feeInfo.protocolFee = feeInfo.price * protocolFeePercent * (id==0?3:1) / 1 ether;
        feeInfo.truckerFee = feeInfo.price * truckerFeePercent / 1 ether;
        feeInfo.topFee = feeInfo.price * topFeePercent / 1 ether;
        
        ticketsBalance[trucker][id][msg.sender] -=  amount;
        ticketsSupply[trucker][id] = supply - amount;
        ticketsReserve[trucker][id] -= feeInfo.price;

    }



    function sellTicketsEth(address trucker, uint256 amount) public payable {
    	require(ticketEnabled);
    	FeeInfo memory feeInfo;
    	uint256 id = 0; //eth
        uint256 supply = ticketsSupply[trucker][id];
        require(supply > amount, "last");
        

        updateTicketsSell(trucker, id, amount, supply, feeInfo);
        
        emit TicketTrade(msg.sender, trucker, topTrucker, false, amount, feeInfo.price, feeInfo.protocolFee, feeInfo.truckerFee, feeInfo.topFee, supply - amount);
        (bool success1, ) = msg.sender.call{value: feeInfo.price - feeInfo.protocolFee - feeInfo.truckerFee - feeInfo.topFee}("");
        (bool success2, ) = protocolFeeWallet.call{value: feeInfo.protocolFee}("");
        (bool success3, ) = trucker.call{value: feeInfo.truckerFee}("");
        (bool success4, ) = topTrucker.call{value: feeInfo.topFee}("");
        require(success1 && success2 && success3 && success4, "ffunds");
    }

    function sellTicketsCT(address trucker, uint256 amount) public {
    	require(ticketEnabled);
    	FeeInfo memory feeInfo;
    	uint256 id = 1; //cybertrucker
        uint256 supply = ticketsSupply[trucker][id];
        require(supply > amount, "last");
        
        updateTicketsSell(trucker, id, amount, supply, feeInfo);

        _balances[protocolFeeWallet] += feeInfo.protocolFee;
        _balances[trucker] += feeInfo.truckerFee;
        _balances[topTrucker] += feeInfo.topFee;
        _balances[address(this)] -= feeInfo.price;
        _balances[msg.sender] += (feeInfo.price - feeInfo.protocolFee - feeInfo.truckerFee - feeInfo.topFee);
        
        emit Transfer(address(this), protocolFeeWallet, feeInfo.protocolFee);
        emit Transfer(address(this), trucker, feeInfo.truckerFee);
        emit Transfer(address(this), topTrucker, feeInfo.topFee);
        emit Transfer(address(this), msg.sender, feeInfo.price - feeInfo.protocolFee - feeInfo.truckerFee - feeInfo.topFee);
        
        emit TicketTradeNative(msg.sender, trucker, topTrucker, false, amount, feeInfo.price, feeInfo.protocolFee, feeInfo.truckerFee, feeInfo.topFee, supply - amount);
        
    }
  
    receive() external payable {}
}