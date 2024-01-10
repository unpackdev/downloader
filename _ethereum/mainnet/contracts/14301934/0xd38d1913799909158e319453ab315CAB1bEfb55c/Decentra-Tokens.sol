// SPDX-License-Identifier: UNLICENSED

/**
    DE_SHIB (DSHIB) - win SHIB in auto-lotteries just by holding
    #Decentra-Tokens
    Website: https://decentra-tokens.com/
    TG: https://t.me/De_Shib
 */
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./Context.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./VRFConsumerBase.sol";

abstract contract RandomNumberConsumer is VRFConsumerBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256 public randomResult;
    
    //contracts: https://docs.chain.link/docs/vrf-contracts/
    //faucets: https://docs.chain.link/docs/link-token-contracts/
    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee) 
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link  // LINK Token
        )
    {
        keyHash = _keyHash;
        fee = _fee; // 0.1 LINK for testnet, 2 LINK for Live (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber() internal returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
}

contract DecentraTokens is Context, IERC20, Ownable, RandomNumberConsumer {
    using Address for address;

    //tracking addresses for lotto entry using mappings
    uint256 private numAddresses = 0;
    mapping (uint256 => address) private _addressList;
    mapping (address => bool) private _AddressExists;
    //

    //token amounts
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    //

    //token config
    string private _name = "DE-SHIB";
    string private _symbol = "DSHIB";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _jackpotFee = 6;
    uint256 private _previousJackpotFee = _jackpotFee;

    uint256 public _ecosystemFee = 8;
    uint256 private _previousEcosystemFee = _ecosystemFee;

    uint256 public _percentOfSwapIsLotto = 20;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1 * 10**7 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    //

    //Contract init and sniper config
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public JACKPOT_TOKEN_ADDRESS;
    IERC20 jackpotToken;
    uint8 private _jackpotTokenDecimals;
    mapping (address => bool) private _isSniperOrBlacklisted;
    bool private sniperProtection = true;
    bool public _hasLiqBeenAdded = false;
    uint256 private _liqAddBlock = 0;
    uint256 public snipersCaught = 0;
    uint256 private snipeBlockAmt = 2;
    //

    //excludes
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxTx;
    mapping (address => bool) private _isExcludedFromMaxWallet;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isLottoExcluded;
    address[] private _excluded;
    //

    //payable wallets
    address payable private _ecosystemWallet;

    //lotto config
    bool public lottoOn = true;
	uint256 public lottoJackpotAmount;
    uint256 public minLottoBalance = 1 * 10**4 * 10**9;
    mapping(uint256 => Winner) public lottoWinners;
    mapping(address => uint256) public walletWinAmount;
    uint256 public numWinners = 0;
    LotteryState public state;
    uint256 public totalWon = 0;
    //

    //other config and members
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndDistribute;
    bool public swapAndDistributeEnabled = false;

    uint256 public _maxTxAmount = 5 * 10**4 * 10**9; //0.5%
    uint256 public _maxWalletAmount = 15 * 10**4 * 10**9; //1.5%
    uint256 public numTokensSellToDistribute =  2 * 10**4 * 10**9; //0.2%

    bytes32 private requestId;
    //

    //events
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndDistributeEnabledUpdated(bool enabled);
    event LottoEnabledUpdated(bool enabled);
    event SwapAndDistribute(
        uint256 tokensSwapped,
        uint256 jackpotETHAmount,
        uint256 ecosystemETHAmount
    );
    event SniperCaught(address sniperAddress);
    event LotteryStateChanged(LotteryState newState);
    event GetRandom(bytes32 requestId);
    event GotRandom(uint256 randomNumber);
    event WinnerPaid(address indexed user, uint256 amount);
    //

    //enums
    enum LotteryState{
        Open,
        GettingRandom,
        GotRandom
    }
    //

    //structs
    struct Winner {
        address winner;
        uint256 amount;
    }
    //

    //modifiers
    modifier lockTheSwap {
        inSwapAndDistribute = true;
        _;
        inSwapAndDistribute = false;
    }
    //

    constructor (address router, address ecosystemWallet, address jackpotTokenAddress_IN, uint8 jackpotTokenDecimals_IN, uint256 lottoJackpotAmount_IN) 
        RandomNumberConsumer(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, //vrfCoordinator ETH mainnet
            0x514910771AF9Ca656af840dff83E8264EcF986CA, // link address ETH mainnet
            0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445, //key hash ETH mainnet
            2 * 10 ** 18 //fee ETH mainnet
        ) public {
        _rOwned[owner()] = _rTotal;

        JACKPOT_TOKEN_ADDRESS = jackpotTokenAddress_IN;
        _jackpotTokenDecimals = jackpotTokenDecimals_IN;
        lottoJackpotAmount = lottoJackpotAmount_IN * 10**jackpotTokenDecimals_IN;
        jackpotToken = IERC20(JACKPOT_TOKEN_ADDRESS);
    
		addAddress(owner());
        _ecosystemWallet = payable(ecosystemWallet);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner, ecosystem and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_ecosystemWallet] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[_ecosystemWallet] = true;
        _isExcludedFromMaxTx[address(this)] = true;

        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[_ecosystemWallet] = true;
        _isExcludedFromMaxWallet[address(this)] = true;
        _isExcludedFromMaxWallet[DEAD] = true;

        _isLottoExcluded[owner()] = true;
        _isLottoExcluded[_ecosystemWallet] = true;
        _isLottoExcluded[address(this)] = true;
        _isLottoExcluded[uniswapV2Pair] = true;
        _isLottoExcluded[router] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]-(amount));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]+(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender]-(subtractedValue));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _rTotal = _rTotal-(rAmount);
        _tFeeTotal = _tFeeTotal+(tAmount);
    }

    function excludeFromLottoRewards(address addy) public onlyOwner {
        require(_isLottoExcluded[addy] == false, "User already excluded from lotto rewards");
        _isLottoExcluded[addy] = true;
    }

    function excludeFromMaxWallet(address addy) public onlyOwner {
        _isExcludedFromMaxWallet[addy] = true;
    }

    function includeInMaxWallet(address addy) public onlyOwner {
        _isExcludedFromMaxWallet[addy] = true;
    }

    function includeInLottoRewards(address addy) public onlyOwner {
        require(_isLottoExcluded[addy] == true, "User already included in lotto rewards");
        _isLottoExcluded[addy] = false;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/(currentRate);
    }

    function setEcosystemAddress(address ecosystem) external onlyOwner {
        _ecosystemWallet = payable(ecosystem);
    }

    function setJackpotTokenAddress(address token, uint8 decimalsIn) external onlyOwner {
        JACKPOT_TOKEN_ADDRESS = token;
        _jackpotTokenDecimals = decimalsIn;
        jackpotToken = IERC20(JACKPOT_TOKEN_ADDRESS);
    }

    function setlottoJackpotAmount(uint256 minBalance) public onlyOwner() {
        lottoJackpotAmount = minBalance * 10**_jackpotTokenDecimals;
    }

    function setMinLottoBalance(uint256 minBalance) public onlyOwner() {
        minLottoBalance = minBalance * 10**_decimals;
    }

    function setRouterAddress(address newRouter) external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isLottoExcluded[uniswapV2Pair] = true;
        _isLottoExcluded[newRouter] = true;
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
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

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLotto) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _tOwned[recipient] = _tOwned[recipient]+(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeEcosystem(tLiquidity);
        _takeLotto(tLotto);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function excludeFromMaxTx(address account) public onlyOwner {
        _isExcludedFromMaxTx[account] = true;
    }

    function includeInMaxTx(address account) public onlyOwner {
        _isExcludedFromMaxTx[account] = false;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setReflectionTaxPercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLottoTaxPercent(uint256 lottoFee) external onlyOwner() {
        _jackpotFee = lottoFee;
    }

    function setEcosystemFee(uint256 ecosystemFee) external onlyOwner() {
        _ecosystemFee = ecosystemFee;
    }

    function setLottoFeePercent(uint256 percentOfSwapIsLotto) external onlyOwner() {
        _percentOfSwapIsLotto = percentOfSwapIsLotto;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount*10**_decimals;
    }

    function setSwapAndDistributeEnabled(bool _enabled) public onlyOwner {
        swapAndDistributeEnabled = _enabled;
        emit SwapAndDistributeEnabledUpdated(_enabled);
    }

    function setLottoEnabled(bool _lottoOn) public onlyOwner {
        lottoOn = _lottoOn;
        emit LottoEnabledUpdated(_lottoOn);
    }

    function multiSender(address[] calldata _addresses, uint256[] calldata _values) external returns (bool) {
        require(_addresses.length == _values.length, "Address array and values array must be same length");

        for (uint i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Address invalid");
            require(_values[i] > 0, "Value invalid");
            IERC20(address(this)).transferFrom(msg.sender, _addresses[i], _values[i]);
        }
        return true;
    }

    //withdraw dust leftover from swaps
    function withdrawETH(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    //withdraw token link or trapped tokens
    function withdrawToken(address _address, uint256 amount) external onlyOwner {
        // Ensure requested tokens isn't Jackpot token (cannot withdraw the pot)
        require(_address != JACKPOT_TOKEN_ADDRESS, "Cannot withdraw Lottery pot");
        require(_address != address(this), "Cannot withdraw platform token");
        IERC20 token = IERC20(_address);
        token.transfer(msg.sender, amount);
    }

    function getStats() external view returns(uint256, uint256, uint256, LotteryState, uint256) {
        return(lottoJackpotAmount, jackpotToken.balanceOf(address(this)), numWinners, state, totalWon);
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal-(rFee);
        _tFeeTotal = _tFeeTotal+(tFee);
    }

    struct TData {
        uint256 tAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tLotto;
        uint256 currentRate;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, TData memory data) = _getTValues(tAmount);
        data.tAmount = tAmount;
        data.currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(data);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, data.tFee, data.tLiquidity, data.tLotto);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, TData memory) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);

        uint256 tLotto = calculateLottoFee(tAmount);

        uint256 tTransferAmount = tAmount-(tFee)-(tLiquidity)-(tLotto);
        return (tTransferAmount, TData(0, tFee, tLiquidity, tLotto, 0));
    }

    function _getRValues( TData memory _data) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = _data.tAmount*(_data.currentRate);
        uint256 rFee = _data.tFee*(_data.currentRate);
        uint256 rLiquidity = _data.tLiquidity*(_data.currentRate);
        uint256 rLotto = _data.tLotto*(_data.currentRate);
        uint256 rTransferAmount = rAmount-(rFee)-(rLiquidity)-(rLotto);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-(_rOwned[_excluded[i]]);
            tSupply = tSupply-(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal/(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeEcosystem(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity*currentRate;
        _rOwned[address(this)] = _rOwned[address(this)]+rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)]+tLiquidity;
    }

	function addAddress(address adr) private {
        if(!_AddressExists[adr]){
            _AddressExists[adr] = true;
            _addressList[numAddresses] = adr;
            numAddresses++;
        }
    }

    function _takeLotto(uint256 tLotto) private {
        uint256 currentRate =  _getRate();
        uint256 rLotto = tLotto*currentRate;
        _rOwned[address(this)] = _rOwned[address(this)]+rLotto;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)]+tLotto;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount*(_taxFee)/(
            10**2
        );
    }

    function calculateLottoFee(uint256 _amount) private view returns (uint256) {
        return _amount*(_jackpotFee)/(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount*(_ecosystemFee)/(
            10**2
        );
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _ecosystemFee == 0 && _jackpotFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousJackpotFee = _jackpotFee;
        _previousEcosystemFee = _ecosystemFee;

        _taxFee = 0;
        _jackpotFee = 0;
        _ecosystemFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _jackpotFee = _previousJackpotFee;
        _ecosystemFee = _previousEcosystemFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromMaxTx(address account) public view returns(bool) {
        return _isExcludedFromMaxTx[account];
    }

    function setNumTokensSellToDistribute(uint256 _numTokensSellToDistribute) public onlyOwner{
        numTokensSellToDistribute = _numTokensSellToDistribute*10**_decimals;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner() && !_isExcludedFromMaxTx[from] && !_isExcludedFromMaxTx[to])
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if(from != owner() && to != owner() && !_isExcludedFromMaxWallet[to] && from == uniswapV2Pair)
            require(balanceOf(to)+(amount) <= _maxWalletAmount, "Transfer amount makes wallet hold more than max.");

        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToDistribute;
        if (
            overMinTokenBalance &&
            !inSwapAndDistribute &&
            from != uniswapV2Pair &&
            swapAndDistributeEnabled
        ) {
            contractTokenBalance = numTokensSellToDistribute;
            //swa and distribute tokens
            swapAndDistribute(contractTokenBalance);
        }else{
            //check if random got to draw winner here so as not to do too much in one transaction avoiding of gas exceptions
            if (state == LotteryState.GotRandom && lottoOn){
                drawWinner();
            }
        }

        //check jackpot threshold and lotto state here to get random
        uint256 jackpotTokenBalance = jackpotToken.balanceOf(address(this));
        bool overMinJackpotBalance = jackpotTokenBalance >= lottoJackpotAmount;
        if (
            overMinJackpotBalance && 
            state == LotteryState.Open && 
            LINK.balanceOf(address(this)) >= fee && 
            lottoOn
        ) {
            _changeState(LotteryState.GettingRandom);
            requestId = getRandomNumber();
            emit GetRandom(requestId);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

		addAddress(from);
		addAddress(to);

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function getRandomAddress(uint32 seed) private view returns(address) {
        return _addressList[(uint256(keccak256(abi.encode(randomResult, seed))) % numAddresses)];
    }

    function drawWinner() private {
        _changeState(LotteryState.Open);
        //seed for abi encoding random number
        uint32 seed = 1;
        address randomAddress = getRandomAddress(seed);

        //get more random addresses until an address qualifies to win
        while (balanceOf(randomAddress) < minLottoBalance || _isLottoExcluded[randomAddress]){
            seed++;
            randomAddress = getRandomAddress(seed);
            if(seed > 40){
                //cap it at 40 iterations so we don't get infinite loop or out of gas exception
                break;
            }
        }

        uint256 jackpotAmount = jackpotToken.balanceOf(address(this));

        jackpotToken.transfer(randomAddress, jackpotAmount);

        numWinners++;
        lottoWinners[numWinners] = Winner(randomAddress, jackpotAmount);
        walletWinAmount[randomAddress] += jackpotAmount;
        totalWon += jackpotAmount;

        emit WinnerPaid(randomAddress, jackpotAmount);
    }

    function swapAndDistribute(uint256 contractTokenBalance) private lockTheSwap {
        //SWAP TO ETH
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(contractTokenBalance);
        //amount of ETH swapped into
        uint256 deltaBalance = address(this).balance - initialBalance;

        //get the percentage split for Ecosystem, and Jackpot
        uint256 jackpotETHAmount = (deltaBalance*_percentOfSwapIsLotto)/100;

        //swap to jackpot token
        swapEthForJackpotToken(jackpotETHAmount);

        //send ETH to ecosystem
        _ecosystemWallet.transfer(deltaBalance-jackpotETHAmount);

        emit SwapAndDistribute(contractTokenBalance, jackpotETHAmount, deltaBalance-jackpotETHAmount);
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
            address(this),
            block.timestamp
        );
    }

    function swapEthForJackpotToken(uint256 ethAmount) private {
        // generate the uniswap pair path of weth -> token
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = JACKPOT_TOKEN_ADDRESS;

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of token
            path,
            address(this),
            block.timestamp
        );
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == uniswapV2Pair) {
            _liqAddBlock = block.number;
            _hasLiqBeenAdded = true;

            swapAndDistributeEnabled = true;
            emit SwapAndDistributeEnabledUpdated(true);
        }
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function excludeSniper(address sniper) public onlyOwner{
        require(_isSniperOrBlacklisted[sniper], "Address not considered a sniper.");
        _isSniperOrBlacklisted[sniper] = false;
        snipersCaught --;
    }

    function includeSniper(address sniper) public onlyOwner{
        require(!_isSniperOrBlacklisted[sniper], "Address already considered a sniper.");
        _isSniperOrBlacklisted[sniper] = true;
        snipersCaught ++;
    }

    function setSniperProtection(bool _sniperProtection) public onlyOwner{
        sniperProtection = _sniperProtection;
    }

    //this method is responsible for taking all fee, if takeFee is true and checking/banning bots
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if (sniperProtection){
            if (_isSniperOrBlacklisted[sender] || _isSniperOrBlacklisted[recipient]) {
                revert("Sniper rejected.");
            }
            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(sender, recipient);
                if (!_hasLiqBeenAdded && _hasLimits(sender, recipient)) {
                    revert("Only owner can transfer at this time.");
                }
            } else {
                if (_liqAddBlock > 0
                    && sender == uniswapV2Pair
                    && _hasLimits(sender, recipient)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniperOrBlacklisted[recipient] = true;
                        snipersCaught ++;
                        emit SniperCaught(recipient);
                    }
                }
            }
        }

        if(!takeFee)
            removeAllFee();

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

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLotto) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeEcosystem(tLiquidity);

        _takeLotto(tLotto);

        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLotto) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _tOwned[recipient] = _tOwned[recipient]+(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeEcosystem(tLiquidity);
        _takeLotto(tLotto);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tLotto) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-(tAmount);
        _rOwned[sender] = _rOwned[sender]-(rAmount);
        _rOwned[recipient] = _rOwned[recipient]+(rTransferAmount);
        _takeEcosystem(tLiquidity);
        _takeLotto(tLotto);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
    * Callback function used by VRF Coordinator
    */
    function fulfillRandomness(bytes32 _requestId, uint256 randomness) internal override {
        require (requestId == _requestId, "requestId doesn't match");
        
        randomResult = randomness;
        
        _changeState(LotteryState.GotRandom);
        
        emit GotRandom(randomResult);
    }

    function _changeState(LotteryState _newState) private {
        state = _newState;
        emit LotteryStateChanged(state);
    }
}

