// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/*⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⢦⡀⠉⠙⢦⡀⠀⠀⣀⣠⣤⣄⣀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⡤⠤⠴⠶⠤⠤⢽⣦⡀⠀⢹⡴⠚⠁⠀⢀⣀⣈⣳⣄⠀⠀
⠀⠀⠀⠀⠀⢠⠞⣁⡤⠴⠶⠶⣦⡄⠀⠀⠀⠀⠀⠀⠀⠶⠿⠭⠤⣄⣈⠙⠳⠀
⠀⠀⠀⠀⢠⡿⠋⠀⠀⢀⡴⠋⠁⠀⣀⡖⠛⢳⠴⠶⡄⠀⠀⠀⠀⠀⠈⠙⢦⠀
⠀⠀⠀⠀⠀⠀⠀⠀⡴⠋⣠⠴⠚⠉⠉⣧⣄⣷⡀⢀⣿⡀⠈⠙⠻⡍⠙⠲⢮⣧
⠀⠀⠀⠀⠀⠀⠀⡞⣠⠞⠁⠀⠀⠀⣰⠃⠀⣸⠉⠉⠀⠙⢦⡀⠀⠸⡄⠀⠈⠟
⠀⠀⠀⠀⠀⠀⢸⠟⠁⠀⠀⠀⠀⢠⠏⠉⢉⡇⠀⠀⠀⠀⠀⠉⠳⣄⢷⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡾⠤⠤⢼⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡇⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠉⠉⠉⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣀⣀⣀⣻⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣀⣀⡤⠤⠤⣿⠉⠉⠉⠘⣧⠤⢤⣄⣀⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢀⡤⠖⠋⠉⠀⠀⠀⠀⠀⠙⠲⠤⠤⠴⠚⠁⠀⠀⠀⠉⠉⠓⠦⣄⠀⠀⠀
⢀⡞⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⣄⠀
⠘⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠒⠚⠀
   _  ____  _____  _____ ____  ______ 
  | ||  _ \|  __ \|_   _|  _ \|  ____|
 / __) |_) | |__) | | | | |_) | |__   
 \__ \  _ <|  _  /  | | |  _ <|  __|  
 (   / |_) | | \ \ _| |_| |_) | |____ 
  |_||____/|_|  \_\_____|____/|______|


  Twitter: https://twitter.com/fraudeth_gg
  Telegram: http://t.me/fraudportal
  Website: https://fraudeth.gg
  Docs: https://docs.fraudeth.gg                                                                                                                                   
 */

import "./ERC20.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract Bribe is ERC20, Ownable, AccessControl {
    using SafeMath for uint256;
    IRouter public constant uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public deployerWallet;
    address payable public taxAddress;

    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public INIT_SUPPLY = 80000 * 10**18;
    
    uint256 public DEPLOYER = 72000 * 10 **18;
    // 5% TEAM
    uint256 public TEAM = 4000 * 10**18;
    // 5% Marketing
    uint256 public MARKETING = 4000 * 10**18;
    
    uint256 public totalSwapTaxed;
    uint256 public taxPercent = 5; // 5% of each transaction is taxed
    uint256 public swapThreshold = 1000 * 10**18;
    uint256 public _totalSupply;
    uint256 public maxWallet = 1200 * 10 ** 18;
    
    bool public tradingActive = false;
    bool private inSwap;
    bool public launchGuard = true;

    mapping(address => bool) public excludedFromTax;
    mapping(address => bool) public marketPairs;

    constructor( 
        
        address _teamAddr,
        address _marketingAddr
        ) ERC20("Bribe", "BRIBE") {
        // Grant the minter role to a specified address

        
        _mint(_teamAddr, TEAM);
        _mint(_marketingAddr, MARKETING);
        _mint(msg.sender, DEPLOYER);
        
        _totalSupply = INIT_SUPPLY;
        _setupRole(MINTER_ROLE, msg.sender);
        deployerWallet = msg.sender;
        // Mint initial supply of tokens

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        _approve(address(this), address(msg.sender), type(uint256).max);
    }

    function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _totalSupply = _totalSupply.add(amount);
        
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _totalSupply = _totalSupply.sub(amount);
        _burn(to, amount);
    }

    function transfer(address to, uint256 value)
        public
        override
        tradingLock(msg.sender)
        validRecipient(to)
        returns (bool)
    {
        require(value <= balanceOf(msg.sender), "Not enough tokens");
        return _transferFrom(msg.sender, to, value);
    }

    function transferFrom(address from, address to, uint256 value) public override tradingLock(from) validRecipient(to) returns (bool) {
        require(value <= balanceOf(from), "Not enough tokens");
        _spendAllowance(from,msg.sender, value);
        return _transferFrom(from, to, value);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        if(inSwap){ return _basicTransfer(from, to, value); }  

        if(marketPairs[to]) {
            uint256 contractBalance = balanceOf(address(this));
            if(contractBalance >= swapThreshold) {
                swapBack();
                // send the ETH to the taxAddress
            }
        }  

        if (marketPairs[to] || marketPairs[from]) {
            // amount can't be more than 1% of the initial supply 

            if(excludedFromTax[to] || excludedFromTax[from]) {
                _basicTransfer(from, to, value);
                return true;
            }

            uint256 bribeTaxAmount = value.mul(taxPercent).div(100);

            totalSwapTaxed = totalSwapTaxed.add(bribeTaxAmount);

            _transfer(from, address(this), bribeTaxAmount);        
            uint256 bribeToTransfer = value.sub(bribeTaxAmount);

            if(marketPairs[to]) {
                require(!isContract(from), "Can't sell from contract");
                require(value <= _totalSupply.div(100), "Can't sell more than 1% of the supply at once");
            }
            else if(marketPairs[from]) {
                require(!isContract(to), "Can't buy from contract");
                require(value <= _totalSupply.div(20), "Can't buy more than 5% of the supply at once");
                if(launchGuard == true){ 
                    require(value <= _totalSupply.div(135), "Can't buy more than 0.75% of the supply at once");
                    require(balanceOf(to).add(value) <= maxWallet, "Max tokens per wallet reached");
                }
            }
            _transfer(from, to, bribeToTransfer);
        } else {
            _transfer(from, to, value);
        }
        return true;
    }

    function _basicTransfer(address from, address to, uint256 value) internal returns (bool) {
        _transfer(from, to, value);
        emit Transfer(from, to, value);
        return true;
    }

    function swapBack() internal swapping {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEthAndSendToTax(contractBalance);
        taxAddress.transfer(address(this).balance);        

    }

    function swapTokensForEthAndSendToTax(uint256 contractBalance) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractBalance,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function isContract(address account) private view returns (bool) {
        if(account == address(this)) return false;

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function setMinter(address minter) public onlyOwner {
        // Grant the minter role to a specified address
        _setupRole(MINTER_ROLE, minter);
    }

    function setTaxPercent(uint256 _taxPercent) public onlyOwner {
        require(_taxPercent <= 30, "Can't have a tax superior to 30%");
        taxPercent = _taxPercent;
    }

    function setTaxAddress(address payable _taxAddress) public onlyOwner {
        //set taxAddress
        taxAddress = _taxAddress;
    }

    function activateTrading() public onlyOwner {
        tradingActive = true;
    }

    function setSwapThreshold(uint256 _swapThreshold) public onlyOwner {
        //set swapThreshold
        swapThreshold = _swapThreshold;
    }

    function setExcludedFromTax(address account, bool _excluded) public onlyOwner {
        // exclude address from tax
        excludedFromTax[account] = _excluded;
    }

    modifier tradingLock(address from) {
        require(tradingActive || from == deployerWallet, "Token: Trading is not active.");
        _;
    }
    function setMarketPairs(address account, bool _marketPair) public onlyOwner {
        // exclude address from tax
        marketPairs[account] = _marketPair;
    }

    function removeLaunchGuard() public onlyOwner{
        launchGuard = false;
    }

    function setMaxWallet(uint256 _maxWallet) public onlyOwner {
        //set maxWallet
        maxWallet = _maxWallet;
    }

    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) public onlyOwner {
        require(to != address(0), "Rescue to the zero address");
        require(token != address(0), "Rescue of the zero address");
        
        // transfer to
        SafeERC20.safeTransfer(IERC20(token),to, amount);
    }

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }
    receive() external payable {}

}
