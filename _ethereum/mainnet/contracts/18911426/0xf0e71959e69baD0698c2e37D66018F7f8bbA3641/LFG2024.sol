// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Pair.sol";


contract LFG2024 is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    bool private swapping;
    // bool public isLocked = true;

    address public DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 public swapTokensAtAmount = 1_000 * (10**18);
   
    // based 1000
    uint256 public totalFees = 50;

    address public marketAddress;
     // exclude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isBlackHolder;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    // price
    bool   immutable public isToken0;

    address immutable public WETH;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor(
        address _router, 
        address _marketAddress, 
        address recipient
    ) 
        public ERC20("LFG2024", "LFG2024") 
    {
        
        marketAddress   = _marketAddress;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router); // spooky router
        address _WETH = _uniswapV2Router.WETH(); // Clone, due Immutable variables cannot be read during contract creation time
        WETH = _WETH;

        isToken0 = address(this) < _WETH;

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _WETH);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        // excludeFromFees(owner(), true);

        excludeFromFees(recipient, true);
        _mint(recipient, 10_000_000_000 * (10**18)); 
    }

    receive() external payable {}

    fallback() external payable{}

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);

        address _uniswapV2Pair = IUniswapV2Factory(IUniswapV2Factory(uniswapV2Router.factory()))
            .createPair(address(this), uniswapV2Router.WETH());

        uniswapV2Pair = _uniswapV2Pair;
    }

    function setSwapTokensAtAmount(uint256 amount)public onlyOwner(){
       swapTokensAtAmount = amount;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setBlockHolder(address account, bool _black) public onlyOwner {
        require(_isBlackHolder[account] != _black, "ETC: not effect");
        _isBlackHolder[account] = _black;
    }    

    function setMultipleBlockHolder(address[] calldata accounts, bool _black) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isBlackHolder[accounts[i]] = _black;
        }
    }

    function setConvertFee(uint256 value) external onlyOwner{
        require(value <= 300, "Nova: over max fee");
        totalFees = value;
    }

    function setMarketAddress(address _marketAddress) external onlyOwner{
        marketAddress = _marketAddress;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The Spooky pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlackHolder[from], "ERC20: from address in black list");

        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            from != owner() &&
            to != owner()
        ) {
            swapping = true;
            processFee(contractTokenBalance);                           
            swapping = false;
        }


        bool takeFee = false;
        if( !swapping && (automatedMarketMakerPairs[to])) {
            takeFee = true;
        }
       
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] ) {
            takeFee = false;
        }

        if(takeFee && totalFees > 0) {
        	uint256 fees = amount.mul(totalFees).div(1000);
        	amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);
    }

    function processFee(uint256 contractTokenBalance) private {
        swapTokensForEth(contractTokenBalance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            marketAddress,
            block.timestamp
        );
    }

    function refoundMisToken(address token, address to) external onlyOwner {

        if(token == address(0) ) {
            uint256 bal = address(this).balance;
            (bool success,) = to.call{value:bal}(new bytes(0));
            require(success, 'ETH_TRANSFER_FAILED');
        } else {
            uint256 bal = IERC20(token).balanceOf(address(this));
            safeTransfer(token, to, bal);
        }

    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }
}