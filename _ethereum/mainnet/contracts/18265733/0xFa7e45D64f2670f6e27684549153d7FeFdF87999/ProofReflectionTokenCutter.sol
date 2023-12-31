pragma solidity ^0.8.17;

import "./EnumerableSet.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ProofReflectionFactoryFees.sol";
import "./IFACTORY.sol";
import "./IDividendDistributor.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IProofReflectionTokenCutter.sol";

contract ProofReflectionTokenCutter is Context, IProofReflectionTokenCutter {
    using EnumerableSet for EnumerableSet.AddressSet;

    //This token was created with PROOF, and audited by Solidity Finance — https://proofplatform.io/projects
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 public swapThreshold;
    uint256 public whitelistEndTime;
    uint256 public whitelistPeriod;

    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 9;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address public proofAdmin;

    mapping(address => bool) public userWhitelist;
    address[] public nftWhitelist;
    bool public whitelistMode = true;

    mapping(address => bool) public isFeeExempt;
    mapping (address => bool) private _isExcluded;
    mapping(address => bool) public isTxLimitExempt;

    address[] private _excluded;

    uint256 public launchedAt;

    uint256 public reflectionFee;
    uint256 public lpFee;
    uint256 public devFee;

    uint256 public reflectionFeeOnSell;
    uint256 public lpFeeOnSell;
    uint256 public devFeeOnSell;

    uint256 public totalFee;
    uint256 public totalFeeIfSelling;

    uint256 private txnCurrentTaxFee = 0;
    uint256 private txnCurrentReflectionFee = 0;

    uint256 public revenueFee = 2;

    IUniswapV2Router02 public router;
    address public pair;
    address public factory;
    address public tokenOwner;
    address payable public devWallet;

    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingStatus = true;

    uint256 public _maxTxAmount;


    constructor() {
        factory = msg.sender;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyProofAdmin() {
        require(
            proofAdmin == _msgSender(),
            "Ownable: caller is not the proofAdmin"
        );
        _;
    }

    modifier onlyOwner() {
        require(tokenOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyFactory() {
        require(factory == _msgSender(), "Ownable: caller is not the factory");
        _;
    }



    function setBasicData(
        BaseData memory _baseData,
        ProofReflectionFactoryFees.allFees memory fees
    ) external onlyFactory {
        _name = _baseData.tokenName;
        _symbol = _baseData.tokenSymbol;
        _tTotal += _baseData.initialSupply;
        _rTotal = (MAX - (MAX % _tTotal));
        swapThreshold = (_baseData.initialSupply * 5) / 4000;

        //Initial supply
        require(_baseData.percentToLP >= 70, "low lp percent");
        uint256 forLP = (_baseData.initialSupply * _baseData.percentToLP) / 100; //95%
        uint256 forOwner = _baseData.initialSupply - forLP; //5%

        _maxTxAmount = (_baseData.initialSupply * 1) / 100;

        router = IUniswapV2Router02(_baseData.routerAddress);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = MAX;

        isFeeExempt[address(this)] = true;
        isFeeExempt[factory] = true;

        userWhitelist[address(this)] = true;
        userWhitelist[factory] = true;
        userWhitelist[pair] = true;
        userWhitelist[_baseData.owner] = true;
        userWhitelist[_baseData.initialProofAdmin] = true;
        userWhitelist[_baseData.routerAddress] = true;
        _addWhitelist(_baseData.whitelists);
        nftWhitelist = _baseData.nftWhitelist;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[_baseData.owner] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[factory] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        _isExcluded[pair] = true;
        

        whitelistPeriod = _baseData.whitelistPeriod;
        reflectionFee = fees.reflectionFee;
        lpFee = fees.lpFee;
        devFee = fees.devFee;

        reflectionFeeOnSell = fees.reflectionFeeOnSell;
        lpFeeOnSell = fees.lpFeeOnSell;
        devFeeOnSell = fees.devFeeOnSell;

        totalFee = devFee + lpFee + revenueFee;	
        totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + revenueFee;

        require(totalFee + reflectionFee <= 12, "Too high fee");
        require(totalFeeIfSelling + reflectionFeeOnSell <= 17, "Too high fee");

        tokenOwner = _baseData.owner;
        devWallet = payable(_baseData.devWallet);
        proofAdmin = _baseData.initialProofAdmin;

        _rOwned[address(0)] += _rTotal;

        _transferStandard(address(0), _msgSender(), forLP);
        _transferStandard(address(0), _baseData.owner, forOwner);

        emit Transfer(address(0), _msgSender(), forLP);
        emit Transfer(address(0), _baseData.owner, forOwner);
    }

    //proofAdmin functions
    function updateProofAdmin(address newAdmin) public virtual onlyProofAdmin {
        proofAdmin = newAdmin;
        userWhitelist[newAdmin] = true;
    }

    function updateWhitelistPeriod(
        uint256 _whitelistPeriod
    ) external onlyProofAdmin {
        whitelistPeriod = _whitelistPeriod;
        whitelistEndTime = launchedAt + (60 * _whitelistPeriod);
        whitelistMode = true;
    }


    //Factory functions
    function swapTradingStatus() public onlyFactory {
        tradingStatus = !tradingStatus;
    }

    function setLaunchedAt() external onlyFactory {
        require(launchedAt == 0, "already launched");
        launchedAt = block.timestamp;
        whitelistEndTime = block.timestamp + (60 * whitelistPeriod);
        whitelistMode = true;
    }

    function cancelToken() public onlyFactory {
        isFeeExempt[address(router)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[tokenOwner] = true;
        tradingStatus = true;
        swapAndLiquifyEnabled = false;
    }

    function changeFees(
        uint256 initialReflectionFee,
        uint256 initialReflectionFeeOnSell,
        uint256 initialLpFee,
        uint256 initialLpFeeOnSell,
        uint256 initialDevFee,
        uint256 initialDevFeeOnSell
    ) external onlyOwner {
        reflectionFee = initialReflectionFee;
        lpFee = initialLpFee;
        devFee = initialDevFee;

        reflectionFeeOnSell = initialReflectionFeeOnSell;
        lpFeeOnSell = initialLpFeeOnSell;
        devFeeOnSell = initialDevFeeOnSell;

        totalFee = devFee + lpFee + revenueFee;	
        totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + revenueFee;

        require(totalFee + reflectionFee <= 12, "Too high fee");
        require(totalFeeIfSelling + reflectionFeeOnSell <= 17, "Too high fee");
    }

    function reduceProofFee() external onlyOwner {
        require(revenueFee == 2, "!already reduced");
        require(launchedAt != 0, "!launched");
        require(block.timestamp >= launchedAt + 72 hours, "too soon");

        revenueFee = 1;
        totalFee = devFee + lpFee + revenueFee;	
        totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + revenueFee;
    }

    function adjustProofFee(uint256 _proofFee) external onlyProofAdmin {
        require(launchedAt != 0, "!launched");
        if (block.timestamp >= launchedAt + 72 hours) {
            require(_proofFee <= 1);
            revenueFee = _proofFee;
            totalFee = devFee + lpFee + revenueFee;
            totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + revenueFee;
        } else {
            require(_proofFee <= 2);
            revenueFee = _proofFee;
            totalFee = devFee + lpFee + revenueFee;
            totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + revenueFee;
        }
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        require(launchedAt != 0, "!launched");
        require(newLimit >= (_tTotal * 5) / 1000, "Min 0.5% limit");	
        require(newLimit <= (_tTotal * 3) / 100, "Max 3% limit");
        _maxTxAmount = newLimit;
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setDevWallet(address payable newDevWallet) external onlyOwner {
        devWallet = payable(newDevWallet);
    }

    function setOwnerWallet(address payable newOwnerWallet) external onlyOwner {	
        tokenOwner = newOwnerWallet;	
    }

    function changeSwapBackSettings(
        bool enableSwapBack,
        uint256 newSwapBackLimit
    ) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function tokenFromReflection(
        uint256 rAmount
    ) private view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            amount <= _maxTxAmount ||
                (isTxLimitExempt[sender] && isTxLimitExempt[recipient]),
            "Max TX Amount"
        );
        
        if(whitelistMode) {
            if (block.timestamp >= whitelistEndTime ) {
                whitelistMode = false;
            } else {
                if (sender == pair) { //buy
                    require(isWhitelisted(recipient) || holdsSupportedNFT(recipient), "Not whitelisted");
                } else if (recipient == pair) { //sell
                    require(isWhitelisted(sender) || holdsSupportedNFT(sender), "Not whitelisted");
                } else { //transfer
                    require((isWhitelisted(sender) || holdsSupportedNFT(sender)) && (isWhitelisted(recipient) || holdsSupportedNFT(recipient)), "Not Whitelisted");
                }
            }
        }

        if (
            sender != tokenOwner &&
            recipient != tokenOwner &&
            !isTxLimitExempt[recipient]
        ) {

            if (
                sender == pair &&    //buy
                recipient != address(router) &&
                !isFeeExempt[recipient]
            ) {
                require(tradingStatus, "!trading");
            }
        }

        if (
            !inSwapAndLiquify &&
            sender != pair &&
            tradingStatus &&
            swapAndLiquifyEnabled &&
            balanceOf(address(this)) >= swapThreshold
        ) {
            swapTokensForEth();
        }

        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            txnCurrentTaxFee = 0;
            txnCurrentReflectionFee = 0;
        } else if (recipient == pair) {
            txnCurrentTaxFee = totalFeeIfSelling;
            txnCurrentReflectionFee = reflectionFeeOnSell;
        } else if (sender == pair) {
            txnCurrentTaxFee = totalFee;
            txnCurrentReflectionFee = reflectionFee;
        } else {
            txnCurrentTaxFee = 0;
            txnCurrentReflectionFee = 0;
        }


        _tokenTransfer(sender,recipient,amount);

    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {

        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tDev
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tDev) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);           
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tDev) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);   
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tDev) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);        
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _takeDev(uint256 tDev) private {
        uint256 currentRate = _getRate();
        uint256 rDev = tDev * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rDev;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + (tDev);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }



    function isWhitelisted(address user) public view returns (bool) {
        return userWhitelist[user];
    }
    function holdsSupportedNFT(address user) public view returns (bool) {
        for (uint256 i = 0; i < nftWhitelist.length; i++) {
            if (IERC721(nftWhitelist[i]).balanceOf(user) > 0) {
                return true;
            }
        }
        return false;
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tDev) = _getTValues(
            tAmount,
            txnCurrentReflectionFee,
            txnCurrentTaxFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tDev,
            currentRate
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tDev);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 _taxFee,
        uint256 _devFee
    ) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = (tAmount * _taxFee) / 100;
        uint256 tDev = (tAmount * _devFee) / 100;
        uint256 tTransferAmount = tAmount - tFee - tDev;
        return (tTransferAmount, tFee, tDev);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - (_rOwned[_excluded[i]]);
            tSupply = tSupply - (_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tDev,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rDev = tDev * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rDev;
        return (rAmount, rTransferAmount, rFee);
    }

    function swapTokensForEth() private lockTheSwap {
        uint256 tokensToLiquify = swapThreshold;

        uint256 amountToLiquify = (tokensToLiquify * lpFee) / totalFee / 2;
        uint256 amountToSwap = tokensToLiquify - amountToLiquify;
        if (amountToSwap == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokensToLiquify);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;    
        uint256 amountEthLiquidity = (amountETH * lpFee) / totalFee / 2;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountEthLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                0x000000000000000000000000000000000000dEaD,
                block.timestamp
            );
        }

        uint256 amountETHafterLP = address(this).balance;


        uint256 revenueBalance = (amountETHafterLP * revenueFee) / totalFee;
        uint256 devBalance = amountETHafterLP - revenueBalance;

        if (amountETH > 0) {
            if (revenueBalance > 0) {
                uint256 revenueSplit = revenueBalance / 2;
                (bool sent, ) = payable(IFACTORY(factory).proofRevenueAddress()).call{value: revenueSplit}("");
                require(sent);
                (bool sent1, ) = payable(IFACTORY(factory).proofRewardPoolAddress()).call{value: revenueSplit}("");
                require(sent1);
            }
            if (devBalance > 0) {
                (bool sent, ) = devWallet.call{value: devBalance}("");
                require(sent, "ETH transfer failed");
            }
        }
    }

    function _addWhitelist(address[] memory _whitelists) internal {
        uint256 length = _whitelists.length;
        for (uint256 i = 0; i < length; i++) {
            userWhitelist[_whitelists[i]] = true;
        }
    }

    function addMoreToWhitelist(WhitelistAdd_ memory _WhitelistAdd) external onlyFactory {
        _addWhitelist(_WhitelistAdd.whitelists);
    }

    receive() external payable {}
}