//SPDX-License-Identifier: No License

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

// We import this library to be able to use console.log
import "./console.sol";

import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./UniswapV2OracleLibrary.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";

//import open zepplin safemath
import "./SafeMath.sol";


contract CrashContestToken is Context, IERC20, Ownable {

    event CrashAvoided(uint256 drawnNumber, uint256 crashesAtNumber );
    event Crashed(uint256 drawnNumber, uint256 crashesAtNumber );
    event CrashedTransfer(address indexed from, address indexed to, uint256 value);
 
    using SafeMath for uint256;
 
    string constant _name = "Tax Split Prop2Holders, Crashes > ~20 Sells";
    string private constant _symbol = "CRASHGAME";
    uint8 private constant _decimals = 0;
 
    mapping(address => uint256) private _ethOwned;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000 * 10**_decimals;
    uint256 private _rTotal = _tTotal;
    uint256 private _tFeeTotal;
    uint256 private _redisFeeOnBuy = 0;  
    uint256 private _taxFeeOnBuy = 5;  
    uint256 private _redisFeeOnSell = 0;  
    uint256 private _taxFeeOnSell = 5;
    uint256 private _potFeeOfFees = 50; //50 percent of taxes go to pot
    uint256 private _potWinningAmountOfBuys = 10;
    uint256 private _crashStart = 10;
    uint256 public  _numberOfBuys = 0;
    uint256 public  _numberOfSells = 0;
    
    uint256 private _teamTotal = 0;
    uint256 private _potEthBalance = 0;
    uint256 private _potTokenBalance = 0;
    uint256 private _teamEthBalance = 0;

    uint256 public _numOfSellsToStartCrashZone = 1;
    uint256 public _oneOutOfWhatToCrash = 4;

    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;
 
    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;
 
    address payable private _developmentAddress;
    // address payable private _lastTraderAddress;
    // address payable private _secondLastTraderAddress;
    // address payable private _thirdLastTraderAddress;
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
 
    bool private tradingOpen = true;
    bool public isCrashed = false;
    bool private inSwap = false;
 
    uint256 public _maxTxAmount = _tTotal.mul(6).div(100);
    uint256 public _maxWalletSize = _tTotal.mul(6).div(100); 
    uint256 public _swapTokensAtAmount = _tTotal.mul(1).div(1000);

    address payable[] public traders;


    function addTrader(address payable trader) private {
        //only add the trader if they are not already in the array
        for( uint i = 0; i < traders.length; i++ ) {
            if( traders[i] == trader ) {
                return;
            }
        }
        traders.push(trader);        
    }

    //our positions in eth and eth price in usd(c)
    struct Position {
        uint256 ethAmount;
        uint256 ethPrice;
    }
 
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    constructor(address devAddress, address uniwapRouterAddress, uint256 numOfSellsToStartCrashZone, uint256 oneOutOfWhatToCrash ) {

        _developmentAddress = payable(devAddress);
        
        //game settings
        _numOfSellsToStartCrashZone = numOfSellsToStartCrashZone;
        _oneOutOfWhatToCrash = oneOutOfWhatToCrash;
        
        _rOwned[_msgSender()] = _rTotal;
 
        //if uniwapRouterAddress != address(0)
        if( address( uniwapRouterAddress) != address(0) ) {
            IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniwapRouterAddress);
            uniswapV2Router = _uniswapV2Router;
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
        }
 
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_developmentAddress] = true;

        //initialize the traders array with 10 dev addresses
        for( uint i = 0; i < 10; i++ ) {
            traders.push(payable(address(devAddress)));
        }
 
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return tokenFromReflection(_rOwned[account]);
    }

    
 
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }
 
    function tokenFromReflection(uint256 rAmount)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
 
    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0) return;
 
        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;
 
        _redisFee = 0;
        _taxFee = 0;
    }
 
    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
    }
 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
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
        require(!isCrashed || (from == owner() || to == owner()), "Coin cannot be crashed" );

        // console.log(
        //     "from %s to %s amount %s",
        //     from,
        //     to,
        //     amount
        // );
 
        if (from != owner() && to != owner()) {

            // console.log( "NEITHER From owner or to owner" );
 
            //Trade start check
            if (!tradingOpen) {
                // console.log( "trading not open" );
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
 
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            
            if(to != uniswapV2Pair) {
                // console.log( "pair address ", uniswapV2Pair );
                // console.log( "current balance: ", balanceOf(to) );
                // console.log( "max wallet size: ", _maxWalletSize );
                uint256 result = balanceOf(to) + amount;
                // console.log( "result balance: ", result, " < ", _maxWalletSize );
                require(result < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }
 
            uint256 contractTokenBalance = balanceOf(address(this)) - _potTokenBalance;
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
 
            // console.log( "contractTokenBalance: ", contractTokenBalance );
            // console.log( "_maxTxAmount: ", _maxTxAmount );
            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }

            if (canSwap && !inSwap && from != uniswapV2Pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                // console.log( "swapTokensForEth" );
                swapTokensForEth(contractTokenBalance);                
                if (_teamEthBalance > 0) {
                    sendETHToFee(_teamEthBalance);
                }
            }
        }
 
        bool takeFee = true;
 
        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
            setFees(to, from);
        }
 
        _tokenTransfer(from, to, amount, takeFee);
    }

    function setFees( address to, address from ) private {
        //Set Fee for Buys
        if( ( from == uniswapV2Pair && to != address(uniswapV2Router)) ) {
            _redisFee = _redisFeeOnBuy;
            _taxFee = _taxFeeOnBuy;
            _numberOfBuys = _numberOfBuys.add(1);
            addTrader(payable(to));
        }

        //Set Fee for Sells
        if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
            _redisFee = _redisFeeOnSell;
            _taxFee = _taxFeeOnSell;
            _numberOfSells = _numberOfSells.add(1);
        }
    }

    function _distributeBalance() private {
        uint256 contractETHBalance = address(this).balance;
        uint256 overFlowBalance = contractETHBalance.sub(_teamEthBalance).sub(_potEthBalance);
        uint256 ethToPot = overFlowBalance.mul(0).div(100); //only the team gets eth, the winner gets taxes in tokens
        uint256 ethToTeam = overFlowBalance.sub(ethToPot);
        _teamEthBalance = _teamEthBalance.add(ethToTeam);
        _potEthBalance = _potEthBalance.add(ethToPot);
    }

    function distributeBalance() public onlyOwner {
        _distributeBalance();
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

        _distributeBalance();
    }
 
    function sendETHToFee(uint256 amount) private {
        _teamEthBalance = _teamEthBalance.sub(amount);
        _developmentAddress.transfer(amount);
    }
 
    function setTradingOpen() public onlyOwner {
        tradingOpen = true;
    }
 
    function manualswap() external {
        require(_msgSender() == _developmentAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
 
    function manualsend() external {
        require(_msgSender() == _developmentAddress);        
        sendETHToFee(_teamEthBalance);                
    }

    // function setPotFeeOfFees(uint256 potFeeOfFees) public onlyOwner {
    //     require(potFeeOfFees >= 0 && potFeeOfFees <= 100, "Pot fee of fees must be between 0% and 100%");
    //     _potFeeOfFees = potFeeOfFees;
    // }

    //function for any addres to claim their eth owned/rewards
    function claimEth() public {
        require(_ethOwned[_msgSender()] > 0, "You have no eth to claim!");
        uint256 ethToClaim = _ethOwned[_msgSender()];
        _ethOwned[_msgSender()] = 0;
        payable(_msgSender()).transfer(ethToClaim);
    }
 
    // function blockBots(address[] memory bots_) public onlyOwner {
    //     for (uint256 i = 0; i < bots_.length; i++) {
    //         bots[bots_[i]] = true;
    //     }
    // }
 
    // function unblockBot(address notbot) public onlyOwner {
    //     bots[notbot] = false;
    // }
 
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();
        // console.log( "about to _transferStandard" );
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();
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
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        //output the balances
        // console.log(
        //     "sender %s balance now %s",
        //     sender,
        //     balanceOf(sender)
        // );
        // console.log(
        //     "recipient %s balance now %s",
        //     recipient,
        //     balanceOf(recipient)
        // );
        bool isBuy = (sender == uniswapV2Pair && recipient != address(uniswapV2Router));
        _takeTeam(tTeam, isBuy);
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }
 
    function _takeTeam(uint256 tTeam, bool isBuy) private {
        if( isCrashed == false ) {
            console.log( "not crashed");

            uint256 currentRate = _getRate();
            uint256 rTeamTotal = tTeam.mul(currentRate);
            _rOwned[address(this)] = _rOwned[address(this)].add(rTeamTotal);
            _potTokenBalance = _potTokenBalance.add(tTeam.mul(_potFeeOfFees).div(100));
            _teamTotal = _teamTotal.add(tTeam);

            // //print out all these balances
            // console.log(
            //     "pot balance: ", _potTokenBalance                
            // );

            bool isSell = (isBuy == false);

            bool inCrashZone = _numberOfSells >= _numOfSellsToStartCrashZone;

            // console.log(
            //     "numberOfSells: ", _numberOfSells );

            uint256 _randomNumber = randomNumber(_potTokenBalance);
            // console.log("randomNumber: ", _randomNumber );
            _randomNumber = _randomNumber.mod(_oneOutOfWhatToCrash);
            // console.log("modded randomNumber: ", _randomNumber );
            bool shouldCrash = _randomNumber == 0;


            if( inCrashZone && !shouldCrash && isSell ) {
                emit CrashAvoided(_randomNumber, _oneOutOfWhatToCrash);
            }

            if( inCrashZone && shouldCrash && isSell ) {             
                //loop over all traders and move the rOwned to address(this)
                for( uint i = 0; i < traders.length; i++ ) {
                    address payable trader = traders[i];
                    if( !_isExcludedFromFee[trader] ) { //<-- we exclude the dev/this/owner address from the pot
                        uint256 lostTraderBalance = _rOwned[address(trader)];
                        _rOwned[address(this)] = _rOwned[address(this)].add(lostTraderBalance);
                        _rOwned[trader] = 0;
                        _potTokenBalance = 0;
                        // console.log( "lostTraderBalance: ", lostTraderBalance );
                        emit CrashedTransfer(trader, address(this), lostTraderBalance); 
                    }                  
                }
                isCrashed = true;
                emit Crashed(_randomNumber, _oneOutOfWhatToCrash);
            }
            else {
                
                //sum the balance of rOwned of all the traders
                uint256 traderBalance = 0;
                for( uint i = 0; i < traders.length; i++ ) {
                    address payable trader = traders[i];
                    if( !_isExcludedFromFee[trader] ) { //<-- we exclude the dev/this/owner address from the pot
                        traderBalance = traderBalance.add(_rOwned[address(trader)]);
                    }                     
                }

                //create an array the size of the amount of traders
                uint256[] memory traderPotSplits = new uint256[](traders.length);
                //caluclate the pot split proportional to their trader balance
                for( uint i = 0; i < traders.length; i++ ) {
                    address payable trader = traders[i];
                    if( !_isExcludedFromFee[trader] ) { //<-- we exclude the dev/this/owner address from the pot
                        traderPotSplits[i] = _rOwned[address(trader)].mul(100).div(traderBalance);
                    }
                }       

                //save off the pot token balance
                uint256 potTokenBalance = _potTokenBalance;

                //transfer the _potTokenBalance to each of the traders
                for( uint i = 0; i < traders.length; i++ ) {
                    address payable trader = traders[i];
                    if( !_isExcludedFromFee[trader] ) { //<-- we exclude the dev/this/owner address from the pot
                        uint256 tokensToTransfer = potTokenBalance.mul(traderPotSplits[i]).div(100);

                        //little safety incase theres inprecision
                        if( tokensToTransfer > potTokenBalance ) {
                            tokensToTransfer = potTokenBalance;
                        }

                        if( tokensToTransfer > 0 ) { 
                            // console.log(
                            //     "balace of %s before dist of %s", trader,
                            //      balanceOf(trader)
                            // );
                            potTokenBalance = potTokenBalance.sub(tokensToTransfer);
                            _rOwned[address(this)] = _rOwned[address(this)].sub(tokensToTransfer);
                            _rOwned[trader] = _rOwned[trader].add(tokensToTransfer); 

                            // console.log(
                            //     "balace of %s after dist of %s", trader,
                            //      balanceOf(trader)
                            // );
                            emit Transfer(address(this), trader, tokensToTransfer);                   
                        }
                    }
                }

                _potTokenBalance = potTokenBalance;
            }
        }
    }

    function randomNumber(uint256 seed) internal view returns (uint256) {
        // console.log( "randomNumber" );
       return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
    }
 
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
 
    receive() external payable {}
 
    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
 
    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }
 
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        //print out all params
       
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }
 
    function _getRate() private pure returns (uint256) {
        // (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return 1;//rSupply.div(tSupply);
    }
    //public getRate
    function getRate() public pure returns (uint256) {
        return _getRate();
    }
 
    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
 
    // function setFee(uint256 redisFeeOnBuy, uint256 redisFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
    //     require(redisFeeOnBuy >= 0 && redisFeeOnBuy <= 5, "Buy rewards must be between 0% and 5%");
    //     require(taxFeeOnBuy >= 0 && taxFeeOnBuy <= 50, "Buy tax must be between 0% and 50%");
    //     require(redisFeeOnSell >= 0 && redisFeeOnSell <= 5, "Sell rewards must be between 0% and 5%");
    //     require(taxFeeOnSell >= 0 && taxFeeOnSell <= 99, "Sell tax must be between 0% and 99%");

    //     _redisFeeOnBuy = redisFeeOnBuy;
    //     _redisFeeOnSell = redisFeeOnSell;
    //     _taxFeeOnBuy = taxFeeOnBuy;
    //     _taxFeeOnSell = taxFeeOnSell;

    // }
 
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }
 
    function setMaxWalletSize(uint256 amountPercent) public onlyOwner {
        require(amountPercent>0);
        _maxWalletSize = (_tTotal * amountPercent ) / 100;
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
    }
 
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }

    //get the pot eth balance
    function getPotEthBalance() public view returns (uint256) {
        return _potEthBalance;
    }   

    //_potTokenBalance
    function getPotTokenBalance() public view returns (uint256) {
        return _potTokenBalance;
    }

    //get the 3 last traders
    function getLastTraders() public view returns (address[] memory) {
        //convert traders to to address array
        address[] memory results = new address[](traders.length);
        //push the traders onto the results array
        for( uint i = 0; i < traders.length; i++ ) {
            results[i] = address(traders[i]);
        }
        return results;
    }

    //set the pot winning amount
    function setPotWinningAmountOfBuys(uint256 potWinningAmountOfBuys) public onlyOwner {
        _potWinningAmountOfBuys = potWinningAmountOfBuys;
    }

    //get the pot winning amount
    function getPotWinningAmountOfBuys() public view returns (uint256) {
        return _potWinningAmountOfBuys;
    }

    //has the pot been reached 
    function hasPotBeenReached() public view returns (bool) {
        return _numberOfBuys >= _potWinningAmountOfBuys;
    }

    //get eth balance for an address
    function getEthBalance(address account) public view returns (uint256) {
        return _ethOwned[account];
    }

    //set marketing and development address
    function setDevelopmentAddress(address payable developmentAddress) public onlyOwner {
        _developmentAddress = developmentAddress;
    }
}