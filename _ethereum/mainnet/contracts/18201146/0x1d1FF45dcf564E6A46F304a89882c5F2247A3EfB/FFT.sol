// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

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

interface ERC20 {
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    address internal potentialOwner;
    mapping (address => bool) internal authorizations;

    event Authorize_Wallet(address Wallet, bool Status);

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address  adr) external onlyOwner {
        require(adr != owner, "Already the owner");
        require(adr != address(0), "Can not be zero address.");
        potentialOwner = adr;
        emit OwnershipNominated(adr);
    }

    function acceptOwnership() external {
        require(msg.sender == potentialOwner, "You must be nominated as potential owner before you can accept the role.");
        authorizations[owner] = false;
        authorizations[potentialOwner] = true;

        emit Authorize_Wallet(owner,false);
        emit Authorize_Wallet(potentialOwner,true);
        
        owner = potentialOwner;
        potentialOwner = address(0);
        emit OwnershipTransferred(owner);
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipRenounced(oldOwner, newOwner);
    }

    event OwnershipRenounced(address oldOwner, address newOwner);
    event OwnershipTransferred(address owner);
    event OwnershipNominated(address potentialOwner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract FFT is ERC20, Auth {
    using SafeMath for uint256;

    address immutable WETH;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    string public constant name = "Fantasy Football Token";
    string public constant symbol = "FFT";
    uint8 public constant decimals = 18;

    uint256 public constant totalSupply = 1000000000 * 10**decimals; // 1 Billion total token supply

    uint256 public _maxTxAmount = (totalSupply / 100) * 2; // 2% of the total supply
    uint256 public _maxWalletToken = (totalSupply / 100) * 2; // 2% of the total supply

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWalletLimitExempt;

    
    uint256 public Marketing_PoolFee = 50; //5% Marketing/Pool Fee
    uint256 public totalFee = Marketing_PoolFee;
    uint256 public constant feeDenominator = 1000;

    uint256 sellMultiplier = 100;
    uint256 buyMultiplier = 100;
    uint256 transferMultiplier = 100;

    address public Marketing_PoolFeeReceiver = 0x942250Ef45c7206d5bf50Cd1b94daD2B457eCFCC;
    address public BurnWallet = 0x6ED5810875eB2544E81A69Fcea47D814270e5080;

    //pinksale-locker
    address private pinksaleAddress = 0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE;

    uint256 public launchTime = 0;
    uint256 private launchDurationMinutes = 10; 

    IDEXRouter public router;
    address public immutable pair;
    bool public swapEnabled = true;
    uint256 public swapThreshold = totalSupply / 500;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;


        isFeeExempt[msg.sender] = true;
        isFeeExempt[Marketing_PoolFeeReceiver] =true;
        isFeeExempt[BurnWallet] = true;
	isFeeExempt[pinksaleAddress] = true;
        isTxLimitExempt[pinksaleAddress] = true;
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[Marketing_PoolFeeReceiver] = true;
        isTxLimitExempt[BurnWallet] = true;
        isTxLimitExempt[ZERO] = true;
        isWalletLimitExempt[msg.sender] = true;
        isWalletLimitExempt[Marketing_PoolFeeReceiver] = true;
        isWalletLimitExempt[BurnWallet] = true;
        isWalletLimitExempt[address(this)] = true;
        isWalletLimitExempt[DEAD] = true;
	isWalletLimitExempt[pinksaleAddress] = true;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    receive() external payable { }

    function getOwner() external view override returns (address) { return owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner {
        require(maxWallPercent_base1000 >= 1,"Cannot set max wallet less than 0.1%");
        _maxWalletToken = (totalSupply * maxWallPercent_base1000 ) / 1000;
        emit config_MaxWallet(_maxWalletToken);
    }

    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner {
        require(maxTXPercentage_base1000 >= 1,"Cannot set max transaction less than 0.1%");
        _maxTxAmount = (totalSupply * maxTXPercentage_base1000 ) / 1000;
        emit config_MaxTransaction(_maxTxAmount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (!authorizations[sender] && !isWalletLimitExempt[sender] && !isWalletLimitExempt[recipient] && recipient != pair) {
            require((balanceOf[recipient] + amount) <= _maxWalletToken,"max wallet limit reached");
        }
    
        // Checks max transaction limit
        require((amount <= _maxTxAmount) || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "Max TX Limit Exceeded");

        if(shouldSwapBack()){ swapBack(); }

        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, amount, recipient);

        balanceOf[recipient] = balanceOf[recipient].add(amountReceived);


        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balanceOf[sender] = balanceOf[sender].sub(amount, "Insufficient Balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {
        if(amount == 0 || totalFee == 0){
            return amount;
        }

        uint256 multiplier = transferMultiplier;

        if(recipient == pair) {
            multiplier = sellMultiplier;
        } else if(sender == pair) {
            multiplier = buyMultiplier;
        }

        // Check if the current time is within the launch duration
        if (block.timestamp < launchTime.add(launchDurationMinutes * 1 minutes)) {
            totalFee = 250; //25% tax for the first 10 mins of launch
        }

        uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);

        if(feeAmount > 0){
            balanceOf[address(this)] = balanceOf[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && balanceOf[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        require(amountPercentage < 101, "Max 100%");
        uint256 amountBNB = address(this).balance;
        uint256 amountToClear = ( amountBNB * amountPercentage ) / 100;
        payable(msg.sender).transfer(amountToClear);
        emit BalanceClear(amountToClear);
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) external onlyOwner returns (bool success) {
        require(tokenAddress != address(this), "tokenAddress can not be the native token");

        if(tokens == 0){
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }

        emit clearToken(tokenAddress, tokens);

        return ERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function swapBack() internal swapping {

        uint256 totalBNBFee = totalFee;

        uint256 amountToSwap = swapThreshold;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance;
        uint256 amountBNBMarketing = (amountBNB * Marketing_PoolFee) / totalBNBFee;

        payable(Marketing_PoolFeeReceiver).transfer(amountBNBMarketing);

    }

    function manage_FeeExempt(address[] calldata addresses, bool status) external onlyOwner {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isFeeExempt[addresses[i]] = status;
            emit Wallet_feeExempt(addresses[i], status);
        }
    }

    function manage_TxLimitExempt(address[] calldata addresses, bool status) external onlyOwner {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isTxLimitExempt[addresses[i]] = status;
            emit Wallet_txExempt(addresses[i], status);
        }
    }

    function manage_WalletLimitExempt(address[] calldata addresses, bool status) external onlyOwner {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i=0; i < addresses.length; ++i) {
            isWalletLimitExempt[addresses[i]] = status;
            emit Wallet_holdingExempt(addresses[i], status);
        }
    }

    function update_fees() internal {
        
        require(totalFee.mul(buyMultiplier).div(100) <= 50, "Buy tax cannot be more than 5%");
        require(totalFee.mul(sellMultiplier).div(100) <= 50, "Sell tax cannot be more than 5%");
        require(totalFee.mul(transferMultiplier).div(100) <= 50, "Transfer Tax cannot be more than 5%");    
        

        emit UpdateFee( uint8(totalFee.mul(buyMultiplier).div(100)),
            uint8(totalFee.mul(sellMultiplier).div(100)),
            uint8(totalFee.mul(transferMultiplier).div(100))
            );
    }

    function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) external onlyOwner {
        sellMultiplier = _sell;
        buyMultiplier = _buy;
        transferMultiplier = _trans;

        update_fees();
    }

    function setMarketing_PoolFee_base1000(uint256 _Marketing_PoolFee) external onlyOwner {
        Marketing_PoolFee = _Marketing_PoolFee;
        totalFee = _Marketing_PoolFee;
        
        update_fees();
    } 

    function setFeeReceiverWallets(address _Marketing_PoolFeeReceiver) external onlyOwner {
        require(_Marketing_PoolFeeReceiver != address(0),"Marketing fee address cannot be zero address");

        Marketing_PoolFeeReceiver = _Marketing_PoolFeeReceiver;

        emit Set_Wallets(Marketing_PoolFeeReceiver);
    }

    function setLaunchTime(uint256 _timestamp) external onlyOwner {
       launchTime =  _timestamp;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        require(_amount < (totalSupply/10), "Amount too high");

        swapEnabled = _enabled;
        swapThreshold = _amount;

        emit config_SwapSettings(swapThreshold, swapEnabled);
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return (totalSupply - balanceOf[DEAD] - balanceOf[ZERO]);
    }

    function multiTransfer(address from, address[] calldata addresses, uint256[] calldata tokens) external onlyOwner { 
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        require(addresses.length == tokens.length,"Mismatch between address and token count");

        uint256 SCCC = 0;

        for(uint i=0; i < addresses.length; i++){
            SCCC = SCCC + tokens[i];
        }

        require(balanceOf[from] >= SCCC, "Not enough tokens in wallet");

        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(from,addresses[i],tokens[i]);
        }
    }

event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
event UpdateFee(uint8 Buy, uint8 Sell, uint8 Transfer);
event Wallet_feeExempt(address Wallet, bool Status);
event Wallet_txExempt(address Wallet, bool Status);
event Wallet_holdingExempt(address Wallet, bool Status);
event BalanceClear(uint256 amount);
event clearToken(address TokenAddressCleared, uint256 Amount);
event Set_Wallets(address MarketingWallet);
event config_MaxWallet(uint256 maxWallet);
event config_MaxTransaction(uint256 maxWallet);
event config_SwapSettings(uint256 Amount, bool Enabled);

}