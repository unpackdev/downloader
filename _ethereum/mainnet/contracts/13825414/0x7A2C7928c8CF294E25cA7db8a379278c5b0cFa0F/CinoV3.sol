
// File contracts/CinoV3.sol

pragma solidity ^0.6.12;
// SPDX-License-Identifier: UNLICENSED
/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@#%@@@@@@             @@@@@@%/@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@.&@@@@@@@@@@@             @@@@@@@@@@@&.@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@.@@@@@@@@@@@@@@@@%@@@@@@@@@@@%@@@@@@@@@@@@@@@@.@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@      &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@
@@@@@@@@@@@           &@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@           @@@@@@@@@@
@@@@@@@@@          @@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@@          @@@@@@@@
@@@@@@@ &       @@@@@@@@@@@@@@                     @@@@@@@@@@@@@@       & @@@@@@
@@@@@@@@@@@   @@@@@@@@@@@&                             &@@@@@@@@@@@   &@@@@@@@@@
@@@@&@@@@@@@@@@@@@@@@@&                                   @@@@@@@@@@@@@@@@@@@@@@
@@@ @@@@@@@@@&@@@@@@&          &&      ,&       &&          &@@@@@@&@@@@@@@@@ @@
@@ @@@@@@@@@@@@@@@@                                           @@@@@@@@@@@@@@@@ @
@@@@@@@@@@@@@@@@@@               &&    &&&    &(               @@@@@@@@@@@@@@@@@
@#@@@@@@@@@@@@@@&         &&                         &&         &@@@@@@@@@@@@@@%
@       @@@@@@@@               &&# &&&&& &&&&& &&&               @@@@@@@@      @
@      (@@@@@@@@                     *     .                     @@@@@@@@%     @
@      &@@@@@@@&       &   &&   (&&&&   2   &&&&,   &&   &       %@@@@@@@@     @
@      (@@@@@@@@                     %.   .%                     @@@@@@@@%     @
@       @@@@@@@@               &&% &&&&& &&&&& %&&               @@@@@@@@      @
@#@@@@@@@@@@@@@@&         &&                         &&         &@@@@@@@@@@@@@@%
@@@@@@@@@@@@@@@@@@               &&    &&&    &&               @@@@@@@@@@@@@@@@@
@@ @@@@@@@@@@@@@@@@                                           @@@@@@@@@@@@@@@@ @
@@@ @@@@@@@@@&@@@@@@&          &&      #&       &&          %@@@@@@&@@@@@@@@@ @@
@@@@@@@@@@@@@@@@@@@@@@&                                   @@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@   @@@@@@@@@@@&                             %@@@@@@@@@@@   @@@@@@@@@@
@@@@@@@ &       @@@@@@@@@@@@@@                     @@@@@@@@@@@@@@       & @@@@@@
@@@@@@@@@         .&@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@@@@@@@@@@@@&          @@@@@@@@
@@@@@@@@@@@*          @@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@           @@@@@@@@@@
@@@@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@.@@@@@@@@@@@@@@@&             @@@@@@@@@@@@@@@@,@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@.&@@@@@@@@@@@             @@@@@@@@@@@@,@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

/*
💰 BE THE HOUSE 💰

CINO Token - Cino is a Token that Rewards Holders with profits from our online casino!
     
   
💝 Stake your Cino and get your share of the gross operating profits! 

🤖 Telegram        https://t.me/Cino_Games

📈 Decentralized Finance meets the casino industry!


🔥  Tokenomics - 10% Tax | 4% To marketing | 6% To the Team
💰  80% of Casino profits back to the stakers!
💫  Virtually no fees after Cardano Block Chain Smart Contract release!
⭐️  Token will be bridged to Cardano and BSC with casino integrations on Cardano!
🔒   42% of Token Supply locked on Unicrypt!
🗣   Community Driven Project and Economy 
 
 */

import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";


abstract contract V1 {
    function balanceOf(address account) public view virtual returns (uint256);
}

// Contract implementation
contract CinoV3 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    mapping(address => bool) private _isBlackListedBot;
    address[] private _blackListedBots;

    event ExcludeFromFee(address indexed account, bool isExcluded);

    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    uint256 private _tTotal; //Determined by prior balances
    uint256 private _tFeeTotal;

    string private _name = "Cino Games";
    string private _symbol = "CINO";
    uint8 private _decimals = 18;
    uint256 private launchTime;

    address payable paymentContractAddress =
        payable(0xF2FBB896DA2e53Ce7C1391cA003FD8A3277c55aB);

    // Tax fees will start at 0 so we don't have a big impact when deploying to Uniswap

    address payable _tokenTaxWallet =
        payable(0xE55F6397A171eA6cA1c16cB6811f431bB4422ae0);

    uint256 public _taxFee = 10;
    uint256 private _previousTaxFee = _taxFee;

    address payable public _taxWalletAddress;

    address public _bridgeAdminAddress;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwap = false;
    bool public swapEnabled = true;

    bool public autoSwapEnabled = true;

    uint256 public _maxTxAmount = 100000000000 * 10**18; //no max tx limit rn

    uint256 private _numOfTokensToExchange = 10000 * 10**18;
    bool public enforceMaxTx = true;
    uint256 dropped = 0;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapEnabledUpdated(bool enabled);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() public {
        // Unirouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // PancakeRouter = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        ); // UniswapV2 for Ethereum network
        // Create a uniswap pair for this new token


        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[
            address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
        ] = true;
        _isExcludedFromFee[address(0xf49b13eCef3C4edd3d1C037C62455988E426aD64)] = true;
        launchTime = block.timestamp;
        _taxWalletAddress = paymentContractAddress;
        _bridgeAdminAddress = 0xf49b13eCef3C4edd3d1C037C62455988E426aD64;

        uint256 total = 100000000000 * 10**18;

      
        _tTotal = _tTotal.add(total);

        _tOwned[_msgSender()] = _tTotal;

        // Transferring the equivalent of V1 CINO in the current Liquidity Pool into the dev wallet to provide initial liquidity for V2 as to maintain the market status

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function changePaymentContract(address newContractAddress) external onlyOwner {
        _taxWalletAddress = payable(newContractAddress);
    }


    function changeTokenTaxWallet(address newTaxWalletAddress) external onlyOwner {
        _tokenTaxWallet = payable(newTaxWalletAddress);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");


        _tTotal = _tTotal.add(amount);
        _tOwned[account] = _tOwned[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == _bridgeAdminAddress, "Only Bridge Administrator");
        _mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _tOwned[account] = _tOwned[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _tTotal = _tTotal.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function burn(address owner, uint256 amount) external {
        require(msg.sender == _bridgeAdminAddress, "Only Bridge Administrator");
        _burn(owner, amount);
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
        return _tOwned[account];
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

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isBlackListed(address account) public view returns (bool) {
        return _isBlackListedBot[account];
    }

    function setExcludeFromFee(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = excluded;
    }

    function setBridgeAdminAddress(address bridgeAddress) external onlyOwner {
        _bridgeAdminAddress = bridgeAddress;
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setMaxTxEnforced(bool isMaxTxEnforced)
        public
        onlyOwner
        returns (bool maxTxEnforced)
    {
        enforceMaxTx = isMaxTxEnforced;
        return enforceMaxTx;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function excludeAccount(address account) external onlyOwner {
        require(
            account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            "We can not exclude Uniswap router."
        );
        require(!_isExcluded[account], "Account is already excluded");
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner {
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

    function addBotToBlackList(address account) external onlyOwner {
        require(
            account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            "We can not blacklist Uniswap router."
        );
        require(!_isBlackListedBot[account], "Account is already blacklisted");
        _isBlackListedBot[account] = true;
        _blackListedBots.push(account);
    }

    function removeBotFromBlackList(address account) external onlyOwner {
        require(_isBlackListedBot[account], "Account is not blacklisted");
        for (uint256 i = 0; i < _blackListedBots.length; i++) {
            if (_blackListedBots[i] == account) {
                _blackListedBots[i] = _blackListedBots[
                    _blackListedBots.length - 1
                ];
                _isBlackListedBot[account] = false;
                _blackListedBots.pop();
                break;
            }
        }
    }

    function removeAllFee() private {
        if (_taxFee == 0) return;

        _previousTaxFee = _taxFee;

        _taxFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setMaxTxLimit(uint256 maxTxLimit) external onlyOwner {
        _maxTxAmount = maxTxLimit * 10**18;
    }

    function setAutoSwapEnabled(bool _autoSwapEnabled) external onlyOwner {
        autoSwapEnabled = _autoSwapEnabled;
    }

    function setNumofTokensForExchange(uint256 numOfTokensToExchange)
        external
        onlyOwner
    {
        _numOfTokensToExchange = numOfTokensToExchange;
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
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (
            block.timestamp == launchTime &&
            sender != owner() &&
            sender != address(this)
        ) {
            _isBlackListedBot[recipient] = true;
            _blackListedBots.push(recipient);
        }
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlackListedBot[sender], "You have no power here!");
        require(!_isBlackListedBot[recipient], "You have no power here!");

        if (sender != owner() && recipient != owner() && enforceMaxTx)
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            _maxTxAmount = contractTokenBalance;
        }

        bool overMinTokenBalance = contractTokenBalance >=
            _numOfTokensToExchange;
        if (
            !inSwap &&
            swapEnabled &&
            overMinTokenBalance &&
            sender != uniswapV2Pair &&
            autoSwapEnabled
        ) {
            // We need to swap the current tokens to ETH and send to the marketing wallet
            swapTokensForEth(contractTokenBalance);

            uint256 contractETHBalance = payable(address(this)).balance;
            if (contractETHBalance > 0) {
                sendETHToTaxes(payable(address(this)).balance);
            }
        } else if (
            !inSwap &&
            swapEnabled &&
            overMinTokenBalance &&
            sender != uniswapV2Pair &&
            !autoSwapEnabled
        ) {
            _tokenTransfer(
                address(this),
                _tokenTaxWallet,
                contractTokenBalance,
                false
            );
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        //transfer amount, it will take tax fee
        _tokenTransfer(sender, recipient, amount, takeFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        //generate the uniswap pair path of CINO -> wETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            _taxWalletAddress,
            block.timestamp
        );
    }

    function sendETHToTaxes(uint256 amount) private {
        _taxWalletAddress.call.value(amount)("");
    }

    // We are exposing these functions to be able to manual swap and send
    // in case the token is highly valued and 5M becomes too much
    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        if (autoSwapEnabled) {
            swapTokensForEth(contractBalance);
        } else {
            _tokenTransfer(
                address(this),
                _tokenTaxWallet,
                contractBalance,
                false
            );
        }
    }

    function manualSend() external onlyOwner {
        uint256 contractETHBalance = payable(address(this)).balance;
        sendETHToTaxes(contractETHBalance);
    }

    function setSwapEnabled(bool enabled) external onlyOwner {
        swapEnabled = enabled;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

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

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _takeTaxes(tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function _takeTaxes(uint256 tTotal) private {
        _tOwned[address(this)] = _tOwned[address(this)].add(tTotal);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function _reflectFee(uint256 tFee) private {
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    //to recieve ETH from uniswapV2Router when swapping
    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        return (tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getTaxFee() private view returns (uint256) {
        return _taxFee;
    }

    function _getMaxTxAmount() private view returns (uint256) {
        return _maxTxAmount;
    }

    function _getETHBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }

    function _setTaxFee(uint256 taxFee) external onlyOwner {
        require(taxFee >= 0 && taxFee <= 500, "taxFee should be in 1 - 50");
        _taxFee = taxFee.div(10);
    }
}
