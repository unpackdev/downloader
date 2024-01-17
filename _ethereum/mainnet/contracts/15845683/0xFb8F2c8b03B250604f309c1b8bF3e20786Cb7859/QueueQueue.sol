/*
 * QueueQueue - QQ
 * 
 * Buy tax
 * 4% Queue Rewards 
 * 1% Misc Tax
 * 
 * Sell tax
 * 4% Queue Rewards 
 * 1% Misc Tax
 *
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.17;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXPair { 
    function sync() external;
}

interface IDEXRouter {
    function factory() external pure returns (address);    
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract UsdHelper {
    address private immutable _token;
    IBEP20 private immutable usd;
    modifier onlyToken() {require(msg.sender == _token); _;}
    constructor (address owner, address wrappedAddress) {
        _token = owner;
        usd = IBEP20(wrappedAddress);
    }
    function giveMeMyMoneyBack() external onlyToken {usd.transfer(_token, usd.balanceOf(address(this)));}
}

contract QueueQueue is IBEP20 {
    string constant _name = "QueueQueue";
    string constant _symbol = "QQ";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 100 * (10**_decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public limitless;
    mapping(address => bool) public isExludedFromMaxWallet;

    uint256 public tax = 5;
    uint256 private rewards = 4;
    uint256 private misc = 1;
    uint256 private swapAt = _totalSupply / 10_000;
    uint256 public maxWalletInPercent = 1;

    IDEXRouter public constant ROUTER = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public constant CEO = 0x2c7a1b029e1852825985ba0f94b0Dcb57Aa60239;
    address private constant rewardAddress = 0xFb50D7d98A2e8CF2f63CC17d18e6712Ade3452B3;

    address public immutable pcsPair;
    address[] public pairs;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; 
    }

    IBEP20 public constant rewardToken = IBEP20(0xFb50D7d98A2e8CF2f63CC17d18e6712Ade3452B3);
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public lastClaim;
    mapping (address => Share) public shares;
    mapping (address => bool) public addressNotGettingRewards;

    uint256 public totalShares;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 private veryLargeNumber = 10 ** 36;
    uint256 private rewardTokenBalanceBefore;
    uint256 private distributionGas;
    uint256 public rewardsToSendPerTx;
    UsdHelper private immutable helper;
    bool private launched;
    uint256 public minTokensForRewards;
    uint256 private currentIndex;
    address[] private shareholders;
    
    modifier onlyCEO(){
        require (msg.sender == CEO, "Only the CEO can do that");
        _;
    }

    event TaxesSetToZero();

    constructor() {
        pcsPair = IDEXFactory(IDEXRouter(ROUTER).factory()).createPair(rewardAddress, address(this));
        _allowances[address(this)][address(ROUTER)] = type(uint256).max;

        isExludedFromMaxWallet[pcsPair] = true;
        isExludedFromMaxWallet[address(this)] = true;

        addressNotGettingRewards[pcsPair] = true;
        addressNotGettingRewards[address(this)] = true;

        limitless[CEO] = true;
        limitless[address(this)] = true;
        helper = new UsdHelper(address(this), address(rewardToken));

        _balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
    }

    receive() external payable {}
    function name() public pure override returns (string memory) {return _name;}
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function decimals() public pure override returns (uint8) {return _decimals;}
    function symbol() public pure override returns (string memory) {return _symbol;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    
    function allowance(address holder, address spender) public view override returns (uint256) {
        return _allowances[holder][spender];
    }
    
    function approveMax(address spender) external returns (bool) {return approve(spender, type(uint256).max);}
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) + addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Can't use zero address here");
        require(allowance(msg.sender, spender) >= subtractedValue, "Can't subtract more than current allowance");
        _allowances[msg.sender][spender]  = allowance(msg.sender, spender) - subtractedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            require(_allowances[sender][msg.sender] >= amount, "Insufficient Allowance");
            _allowances[sender][msg.sender] -= amount;
            emit Approval(sender, msg.sender, _allowances[sender][msg.sender]);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function rescueQueueBeforeLaunch() external onlyCEO {
        require(!launched);
        rewardToken.transfer(CEO, rewardToken.balanceOf(address(this)));
    }

    function launch() external onlyCEO {
        require(!launched);
        rewardToken.approve(address(ROUTER), type(uint256).max);
        
        ROUTER.addLiquidity(
            address(this),
            rewardAddress,
            _balances[address(this)],
            rewardToken.balanceOf(address(this)),
            0,
            0,
            CEO,
            block.timestamp
        );
        launched = true;
    }


    function setTaxToZero() external onlyCEO {
        rewards = 0;
        misc = 0;
        tax = 0;        
        emit TaxesSetToZero();
    }
    
    function setMaxWalletToTwoPercent() external onlyCEO {
		require(maxWalletInPercent == 1);
        maxWalletInPercent = 2;
    }

    function removeMaxWallet() external onlyCEO {
        maxWalletInPercent = 100;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (limitless[sender] || limitless[recipient]) return _lowGasTransfer(sender, recipient, amount);
		amount = takeTax(sender, recipient, amount);
        _lowGasTransfer(sender, recipient, amount);
        return true;
    }

    function takeTax(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 totalTax = tax;
        if(!isExludedFromMaxWallet[recipient]) require(_balances[recipient] + amount < _totalSupply * maxWalletInPercent / 100, "MaxWallet");
        if(tax == 0) return amount;
        
        uint256 taxAmount = amount * totalTax / 100;
        if(misc > 0) _lowGasTransfer(sender, CEO, taxAmount * misc / totalTax);
        if(rewards > 0) _lowGasTransfer(sender, address(this), taxAmount * rewards / totalTax);
        
        if(_balances[address(this)] > 0 && isPair(recipient)) swapForRewards();
        return amount - taxAmount;
    }

    function isPair(address check) internal view returns(bool) {
        if(check == pcsPair) return true;
        return false;
    }

    function _lowGasTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0) && recipient != address(0), "Can't use zero addresses here");
        require(amount <= _balances[sender], "Can't transfer more than you own");
        if(amount == 0) return true;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        if(!addressNotGettingRewards[sender]) setShare(sender);
        if(!addressNotGettingRewards[recipient]) setShare(recipient);
		return true;
    }

    function swapForRewards() internal {
        if(_balances[address(this)] < swapAt) return;
        rewardTokenBalanceBefore = rewardToken.balanceOf(address(this));

        address[] memory pathForSelling = new address[](2);
        pathForSelling[0] = address(this);
        pathForSelling[1] = address(rewardToken);

        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _balances[address(this)],
            0,
            pathForSelling,
            address(helper),
            block.timestamp
        );
        helper.giveMeMyMoneyBack();

        uint256 newrewardTokenBalance = rewardToken.balanceOf(address(this));
        if(newrewardTokenBalance <= rewardTokenBalanceBefore) return;
        
        uint256 amount = newrewardTokenBalance - rewardTokenBalanceBefore;
        rewardsPerShare = rewardsPerShare + (veryLargeNumber * amount / totalShares);
    }

    function setShare(address shareholder) internal {
        // rewards for the past are paid out   //maybe replace with return for small holder to save gas
        if(shares[shareholder].amount >= minTokensForRewards) distributeRewards(shareholder);

        // hello shareholder
        if(
            shares[shareholder].amount == 0 
            && _balances[shareholder] >= minTokensForRewards
        ) 
        addShareholder(shareholder);
        
        // goodbye shareholder
        if(
            shares[shareholder].amount >= minTokensForRewards
            && _balances[shareholder] < minTokensForRewards
        ){
            totalShares = totalShares - shares[shareholder].amount;
            shares[shareholder].amount = 0;
            removeShareholder(shareholder);
            return;
        }

        // already shareholder, just different balance
        if(_balances[shareholder] >= minTokensForRewards){
        totalShares = totalShares - shares[shareholder].amount + _balances[shareholder];
        shares[shareholder].amount = _balances[shareholder];///
        shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
        }
    }

    function claim() external {
        if(getUnpaidEarnings(msg.sender) > 0) distributeRewards(msg.sender);
    }

    function distributeRewards(address shareholder) internal {
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount == 0) return;

        rewardToken.transfer(shareholder,amount);
        totalDistributed = totalDistributed + amount;
        shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
        shares[shareholder].totalExcluded = getTotalRewardsOf(shares[shareholder].amount);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        uint256 shareholderTotalRewards = getTotalRewardsOf(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalRewards <= shareholderTotalExcluded) return 0;
        return shareholderTotalRewards - shareholderTotalExcluded;
    }

    function getTotalRewardsOf(uint256 share) internal view returns (uint256) {
        return share * rewardsPerShare / veryLargeNumber;
    }
   
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}