// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//oz libaries
import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";

import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";


contract MALTESE is ERC20, Ownable {
    using Address for address;
    
    //Mainnet router 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    IUniswapV2Router02 public router;
    address public pair;
    
    bool private _liquidityMutex = false;
    uint256 public _tokenLiquidityThreshold = 50000e18;
    bool public ProvidingLiquidity = false;
    
    uint8 public feeliq = 4;
    uint8 public feeburn = 2;
    uint8 public feedev = 3;
    
    uint8 public feesum = feeliq + feeburn + feedev;
    
    address payable public devwallet = payable(0x52de05b025B803DcE0745696b3B4a982c843200B);

    uint256 public buylimit;
    uint256 public transferlimit;
    uint8 public transfertimeout = 12;

    mapping (address => bool) public exemptTransferlimit;    
    mapping (address => bool) public exemptFee; 
    mapping (address => uint256) public lastTransaction; 
    
    event LiquidityProvided(uint256 tokenAmount, uint256 nativeAmount, uint256 exchangeAmount);
    event LiquidityProvisionStateChanged(bool newState);
    event LiquidityThresholdUpdated(uint256 newThreshold);
    
    
    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }
    
    constructor() ERC20("Maltese Coin", "MALTESE") {
        _mint(devwallet, 1e9 * 10 ** decimals());      
        buylimit = 5e6 * 10 ** decimals();
        transferlimit = 5e6 * 10 ** decimals();
        exemptTransferlimit[msg.sender] = true;
        exemptFee[msg.sender] = true;

        exemptTransferlimit[devwallet] = true;
        exemptFee[devwallet] = true;

        exemptTransferlimit[address(this)] = true;
        exemptFee[address(this)] = true;
    }
   
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        
        //check buylimit
        require(sender != pair || amount <= buylimit, "you can't buy that much");

        //check transferlimit
        require(amount <= transferlimit || exemptTransferlimit[sender] || exemptTransferlimit[recipient] , "you can't transfer that much");

        //check transfer timeout
        require(block.timestamp >= lastTransaction[sender] + transfertimeout || exemptFee[sender] || sender == pair, "currently in transfer timeout");

        //calculate fee
        uint256 fee = amount * feesum / 100;
        
        //set fee to zero if fees in contract are handled
        if (_liquidityMutex || exemptFee[sender] || exemptFee[recipient]) fee = 0;
        
        //rest to recipient
        super._transfer(sender, recipient, amount - fee);
        
        //send the fee to the contract
        if (fee > 0) super._transfer(sender, address(this), fee);
        
        //send fees if threshhold has been reached
        if (ProvidingLiquidity) handle_fees();             

        //set time for last transaction
        lastTransaction[sender] = block.timestamp;
        lastTransaction[recipient] = block.timestamp;  
    }
    
    
    function handle_fees() private mutexLock {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= _tokenLiquidityThreshold) {
            contractBalance = _tokenLiquidityThreshold;
            
            //calculate how many tokens we need to exchange
            uint256 exchangeAmount_liq = contractBalance * feeliq / 2 / feesum;
            uint256 exchangeAmount_dev = contractBalance * feedev / feesum ;

            //exchange to ETH
            exchangeTokenToNativeCurrency(exchangeAmount_liq + exchangeAmount_dev);
            uint256 eth = address(this).balance;
            
            uint256 eth_dev = eth * feedev / feesum;
            
            //send ETH to dev
            sendETHToDev(eth_dev);
            
            //add liquidity
            addToLiquidityPool(exchangeAmount_liq, eth - eth_dev);
            
            //burn the rest
            uint256 amountlefttoburn = contractBalance - (exchangeAmount_liq * 2) - exchangeAmount_dev;
            _burn(address(this), amountlefttoburn);

        }
    }

    function exchangeTokenToNativeCurrency(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function addToLiquidityPool(uint256 tokenAmount, uint256 nativeAmount) private {
        _approve(address(this), address(router), tokenAmount);
        //provide liquidity and send lP tokens to zero
        router.addLiquidityETH{value: nativeAmount}(address(this), tokenAmount, 0, 0, address(0), block.timestamp);
    }    
    
    function setRouterAddress(address newRouter) external onlyOwner {
        //give the option to change the router down the line 
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        //checks if pair already exists
        if (get_pair == address(0)) {
            pair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            pair = get_pair;
        }
        router = _newRouter;
    }    
    
    function sendETHToDev(uint256 amount) private {
        //transfers ETH out of contract to devwallet
        devwallet.transfer(amount);
    }
    
    function changeLiquidityProvide(bool state) external onlyOwner {
        //change liquidity providing state
        ProvidingLiquidity = state;
        emit LiquidityProvisionStateChanged(state);
    }
    
    function changeLiquidityTreshhold(uint256 new_amount) external onlyOwner {
        //change the treshhold
        _tokenLiquidityThreshold = new_amount;
        emit LiquidityThresholdUpdated(new_amount);
    }   
    
    function changeFees(uint8 _feeliq, uint8 _feeburn, uint8 _feedev) external onlyOwner returns (bool){
        feeliq = _feeliq;
        feeburn = _feeburn;
        feedev = _feedev;
        feesum = feeliq + feeburn + feedev;
        require(feesum <= 15, "exceeds hardcap");
        return true;
    }

    function changeBuylimit(uint256 _buylimit) external onlyOwner returns (bool) {
        buylimit = _buylimit;
        return true;
    }

    function changeTransferlimit(uint256 _transferlimit) external onlyOwner returns (bool) {
        transferlimit = _transferlimit;
        return true;
    }

    function changeTransferTimeout(uint8 _transfertimeout) external onlyOwner returns (bool) {
        transfertimeout = _transfertimeout;
        return true;
    }

    function updateExemptTransferLimit(address _address, bool state) external onlyOwner returns (bool) {
        exemptTransferlimit[_address] = state;
        return true;
    }

    function updateExemptFee(address _address, bool state) external onlyOwner returns (bool) {
        exemptFee[_address] = state;
        return true;
    }

    function updateDevwallet(address _address) external onlyOwner returns (bool){
        devwallet = payable(_address);
        exemptTransferlimit[devwallet] = true;
        exemptFee[devwallet] = true;
        return true;
    }
    
    // fallbacks
    receive() external payable {}
    
}