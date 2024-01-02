/**


----------------------------  Social Links  ----------------------------


Telegram:  https://t.me/Navy_Fish

Website:   https://www.navy.fish

Docs:      https://docs.navy.fish

Twitter:   https://twitter.com/NavyFishERC


----------------------------  $NAVY Info  ----------------------------


🌊  $NAVY is powered by a brand new smart contract.


📈  Rule 1:   Taxes are derived from the $NAVY market cap.

    Example:  If the market cap is $25,000, the current sea
              creature will be the Humpack, "🐋".
            
              Because the market cap is in the Humpack range, the buy
              tax will be 2% and the sell tax will be 1%.


🔄  Rule 2:   The token name is derived from the $NAVY market cap.

    Example:  If the market cap rises from $49,000 to $51,000,
              the token name will update from "🐋" to "🦭".


💸  Rule 3:   Each wallet is assigned a sea creature based on the $NAVY
              market cap during its first swap.

    Tip:      Once a wallet has been assigned a sea creature, it
              can never be re-assigned.

    Tip:      The lower you wait to buy, the better the sea
              creature you get will be.

    Example:  If a wallet purchases $NAVY at a $65,000 market
              cap, then that wallet's buy tax would never exceed
              the Seal (🦭) buy tax of 2%.


🛢️  Rule 4:   Oil spills briefly override everybody's taxes each time
              a market cap milestone is broken.

    Tip:      Each time the $NAVY market cap enters the range of the
              next sea creature, everybody's tax becomes 0/15 for
              the next 120 seconds.

    Tip:      Sells become less effective at suppressing buy volume
              during an oil spill.

    Tip:      There is no limit on the amount of oil spills that can
              happen.


-------------------------  $NAVY Milestones  -------------------------


💡  Each sea creature has slightly different milestones and taxes:

🐳  Whale       $0 MC
    Lifetime tax: 2/0

🐋  Humpback    $20,000 MC
    Lifetime tax: 2/1

🦭  Seal        $50,000 MC
    Lifetime tax: 2/2

🦈  Shark       $100,000 MC
    Lifetime tax: 3/2

🐬  Dolphin     $200,000 MC
    Lifetime tax: 3/3

🦑  Squid       $400,000 MC
    Lifetime tax: 4/3

🐙  Octopus     $700,000 MC
    Lifetime tax: 4/4

🐠  Angelfish   $1,200,000 MC
    Lifetime tax: 5/4

🐟  Mackerel    $1,800,000 MC
    Lifetime tax: 5/5

🐡  Blowfish    $2,600,000 MC
    Lifetime tax: 6/5

🦞  Lobster     $3,900,000 MC
    Lifetime tax: 6/6

🦀  Crab        $5,500,000 MC
    Lifetime tax: 7/6

🦐  Shrimp      $8,000,000 MC
    Lifetime tax: 7/7

🪸  Coral       $12,000,000 MC
    Lifetime tax: 8/7

🦠  Amoeba      $25,000,000 MC
    Lifetime tax: 8/8


*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./Context.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./EIP712.sol";
import "./Nonces.sol";
import "./ReentrancyGuard.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./AggregatorV3Interface.sol";

contract Navy is Context, IERC20, IERC20Permit, Ownable, EIP712, Nonces, ReentrancyGuard {
    address public immutable DEPLOYED_BY = msg.sender;

    mapping(uint256 => string) internal seaCreatures;

    mapping(uint256 => uint256) internal milestones;

    mapping(uint256 => uint256) internal buyTaxGlobal;
    mapping(uint256 => uint256) internal sellTaxGlobal;

    uint256 internal lastSeaCreature;
    uint256 internal lastProgression;

    mapping(address => uint256) internal seaCreature;
    mapping(address => bool) internal isSeaCreature;

    string private _name = unicode"🐳";
    string private constant _symbol = "NAVY";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _untaxable;

    uint256 internal constant MAX = ~uint256(0);
    uint256 internal constant PAD = 1e9;
    uint256 internal constant ETHER = 1 ether;
    uint256 internal constant PAD_MAX = PAD * ETHER;
    int256 internal constant PAD_USD = 1e8;
    uint256 internal immutable SALT;
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 private constant _tTotal = 100_000_000 * PAD;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    address public constant ZERO_ADDRESS = address(0x0);
    address public constant BURN_ADDRESS = address(0xdead);
    address public constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public immutable UNISWAP_V2_PAIR;
    address public constant CHAINLINK_V3_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable NAVY;
    uint256 public constant MAX_TRADE = 2_000_000 * PAD;
    uint256 public constant MAX_WALLET = 2_000_000 * PAD;
    uint256 public constant SWAP_TRIGGER = 100 * PAD;

    address payable public immutable buybackWallet = payable(DEPLOYED_BY);
    address payable public immutable marketingWallet = payable(DEPLOYED_BY);

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER);
    IUniswapV2Factory public constant uniswapV2Factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
    AggregatorV3Interface public constant chainlinkV3Feed = AggregatorV3Interface(CHAINLINK_V3_FEED);
    IERC20 public constant weth = IERC20(WETH);

    bool public TRADING_ENABLED;
    bool public MAX_TRADE_ENABLED = true;
    bool public MAX_WALLET_ENABLED = true;
    bool private _inBurn;
    bool private _inSwap;
    bool private _inAtomicSwap;
    bool private _inAtomicSupply;

    uint256 public constant maxBuyTax = 8;
    uint256 public constant maxSellTax = 8;
    uint256 private _taxFee = 2;

    event Burn(uint256 tokens);
    event Swap(uint256 tokens);
    event Call(uint256 eth, bool success, bytes data);
    event Supply(uint256 tokens, uint256 eth);

    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);
    error HashFailed();
    error TransferAmountExceedsAllowance(uint256 amount, uint256 allowance);
    error ApprovalFromZeroAddress();
    error ApprovalToZeroAddress();
    error TransferFromZeroAddress();
    error TransferToZeroAddress();
    error TransferAmountEqualsZero();
    error TransferAmountExceedsBalance(uint256 amount, uint256 balance);
    error TradingNotEnabled();
    error MaxTradeExceeded();
    error MaxWalletExceeded();
    error AmountExceedsTotalReflections(uint256 rAmount, uint256 rTotal);

    modifier lockAtomicSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier verifyHash(string memory _key) {
        if (keccak256(abi.encodePacked(_key)) != bytes32(SALT)) {
            revert HashFailed();
        }
        _;
    }

    constructor(uint256 _SALT) Ownable(msg.sender) EIP712(_symbol, "1") {
        SALT = _SALT;

        NAVY = address(this);
        UNISWAP_V2_PAIR = uniswapV2Factory.createPair(NAVY, WETH);

        _untaxable[owner()] = true;
        _untaxable[NAVY] = true;
        _untaxable[buybackWallet] = true;
        _untaxable[marketingWallet] = true;
        _approve(NAVY, UNISWAP_V2_ROUTER, MAX);
        _approve(DEPLOYED_BY, UNISWAP_V2_ROUTER, MAX);

        // 🐳  Whale       $0 MC
        seaCreatures[0] = unicode"🐳";
        milestones[0] = 0;
        buyTaxGlobal[0] = 2;
        sellTaxGlobal[0] = 0;

        // 🐋  Humpback    $20,000 MC
        seaCreatures[1] = unicode"🐋";
        milestones[1] = 10000;
        buyTaxGlobal[1] = 2;
        sellTaxGlobal[1] = 1;

        // 🦭  Seal        $50,000 MC
        seaCreatures[2] = unicode"🦭";
        milestones[2] = 20000;
        buyTaxGlobal[2] = 2;
        sellTaxGlobal[2] = 2;

        // 🦈  Shark       $100,000 MC
        seaCreatures[3] = unicode"🦈";
        milestones[3] = 100000;
        buyTaxGlobal[3] = 3;
        sellTaxGlobal[3] = 2;

        // 🐬  Dolphin     $200,000 MC
        seaCreatures[4] = unicode"🐬";
        milestones[4] = 200000;
        buyTaxGlobal[4] = 3;
        sellTaxGlobal[4] = 3;

        // 🦑  Squid       $400,000 MC
        seaCreatures[5] = unicode"🦑";
        milestones[5] = 400000;
        buyTaxGlobal[5] = 4;
        sellTaxGlobal[5] = 3;

        // 🐙  Octopus     $700,000 MC
        seaCreatures[6] = unicode"🐙";
        milestones[6] = 700000;
        buyTaxGlobal[6] = 4;
        sellTaxGlobal[6] = 4;

        // 🐠  Angelfish   $1,200,000 MC
        seaCreatures[7] = unicode"🐠";
        milestones[7] = 1200000;
        buyTaxGlobal[7] = 5;
        sellTaxGlobal[7] = 4;

        // 🐟  Mackerel    $1,800,000 MC
        seaCreatures[8] = unicode"🐟";
        milestones[8] = 1800000;
        buyTaxGlobal[8] = 5;
        sellTaxGlobal[8] = 5;

        // 🐡  Blowfish    $2,600,000 MC
        seaCreatures[9] = unicode"🐡";
        milestones[9] = 2600000;
        buyTaxGlobal[9] = 6;
        sellTaxGlobal[9] = 5;

        // 🦞  Lobster     $3,900,000 MC
        seaCreatures[10] = unicode"🦞";
        milestones[10] = 3900000;
        buyTaxGlobal[10] = 6;
        sellTaxGlobal[10] = 6;

        // 🦀  Crab        $5,500,000 MC
        seaCreatures[11] = unicode"🦀";
        milestones[11] = 5500000;
        buyTaxGlobal[11] = 7;
        sellTaxGlobal[11] = 6;

        // 🦐  Shrimp      $8,000,000 MC
        seaCreatures[12] = unicode"🦐";
        milestones[12] = 8000000;
        buyTaxGlobal[12] = 7;
        sellTaxGlobal[12] = 7;

        // 🪸  Coral       $12,000,000 MC
        seaCreatures[13] = unicode"🪸";
        milestones[13] = 12000000;
        buyTaxGlobal[13] = 8;
        sellTaxGlobal[13] = 7;

        // 🦠  Amoeba      $25,000,000 MC
        seaCreatures[14] = unicode"🦠";
        milestones[14] = 25000000;
        buyTaxGlobal[14] = 8;
        sellTaxGlobal[14] = 8;

        _rOwned[DEPLOYED_BY] = _rTotal;
        emit Transfer(ZERO_ADDRESS, DEPLOYED_BY, _tTotal);
    }

    receive() external payable {}

    fallback() external payable {}

    function getETHUSDPriceFeed() external pure returns (address) {
        return address(chainlinkV3Feed);
    }

    function getETHUSDPrice() public view returns (uint256) {
        (
            ,
            int256 answer,
            ,
            ,
        ) = chainlinkV3Feed.latestRoundData();
        return uint256(answer / 1e8);
    }

    function getNAVYUSDMarketCap() public view returns (uint256) {
        return ((weth.balanceOf(UNISWAP_V2_PAIR) * getETHUSDPrice()) / 1e18) * (totalSupply() / balanceOf(UNISWAP_V2_PAIR)) * 2;
    }

    function getCurrentSeaCreature() public view returns (uint256) {
        uint256 marketCap = getNAVYUSDMarketCap();
        for (uint256 i = 14; i >= 0; i--) {
            if (marketCap >= milestones[i]) {
                return i;
            }
        }
        return 0;
    }

    function getCurrentSeaCreatureEmoji() public view returns (string memory) {
        return seaCreatures[getCurrentSeaCreature()];
    }

    function getLastSeaCreature() external view returns (uint256) {
        return lastSeaCreature;
    }

    function getNextSeaCreature() public view returns (uint256) {
        uint256 currentSeaCreature = getCurrentSeaCreature();
        return currentSeaCreature == 14 ? 14 : currentSeaCreature + 1;
    }

    function getNextSeaCreatureEmoji() external view returns (string memory) {
        return seaCreatures[getNextSeaCreature()];
    }

    function hasOilSpill() public view returns (bool) {
        return lastProgression + 120 >= block.timestamp;
    }

    function getLastOilSpill() external view returns (uint256) {
        return lastProgression;
    }

    function getOilSpillTimeRemaining() external view returns (uint256) {
        if (hasOilSpill()) {
            return lastProgression + 120 - block.timestamp;
        }
        return 0;
    }

    function getGlobalMaxBuyTax() external pure returns (uint256) {
        return maxBuyTax;
    }

    function getGlobalMaxSellTax() external pure returns (uint256) {
        return maxSellTax;
    }

    function getGlobalBuyTax() public view returns (uint256) {
        if (hasOilSpill()) {
            return 0;
        }
        uint256 globalBuyTax = 14 - getCurrentSeaCreature();
        return globalBuyTax > maxBuyTax ? maxBuyTax : globalBuyTax;
    }

    function getGlobalSellTax() public view returns (uint256) {
        if (hasOilSpill()) {
            return 15;
        }
        uint256 globalSellTax = getCurrentSeaCreature();
        return globalSellTax > maxSellTax ? maxSellTax : globalSellTax;
    }

    function getWalletIsSeaCreature(address _wallet) external view returns (bool) {
        return isSeaCreature[_wallet];
    }

    function getWalletSeaCreature(address _wallet) public view returns (uint256) {
        return isSeaCreature[_wallet] ? seaCreature[_wallet] : getCurrentSeaCreature();
    }

    function getWalletSeaCreatureEmoji(address _wallet) external view returns (string memory) {
        return seaCreatures[getWalletSeaCreature(_wallet)];
    }

    function getWalletBuyTax(address _wallet) public view returns (uint256) {
        if (hasOilSpill()) {
            return 0;
        }
        return isSeaCreature[_wallet] ? buyTaxGlobal[seaCreature[_wallet]] : getGlobalBuyTax();
    }

    function getWalletMaxBuylTax(address _wallet) external view returns (uint256) {
        return isSeaCreature[_wallet] ? buyTaxGlobal[seaCreature[_wallet]] : maxBuyTax;
    }

    function getWalletSellTax(address _wallet) public view returns (uint256) {
        if (hasOilSpill()) {
            return 15;
        }
        return isSeaCreature[_wallet] ? sellTaxGlobal[seaCreature[_wallet]] : getGlobalSellTax();
    }

    function getWalletMaxSellTax(address _wallet) external view returns (uint256) {
        return isSeaCreature[_wallet] ? seaCreature[_wallet] : maxSellTax;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tokenFromReflection(_rOwned[account]);
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
        uint256 _allowance = _allowances[sender][_msgSender()];
        if (amount > _allowance) {
            revert TransferAmountExceedsAllowance(amount, _allowance);
        }
        _approve(sender, _msgSender(), _allowance - amount);
        return true;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC2612InvalidSigner(signer, owner);
        }

        _approve(owner, spender, value);
    }

    function nonces(address owner) public view virtual override(IERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    function burn(uint256 value) external virtual {
        _inBurn = true;
        transfer(ZERO_ADDRESS, value);
        _inBurn = false;
        emit Burn(value);
    }

    function burnFrom(address account, uint256 value) external virtual {
        _inBurn = true;
        transferFrom(account, ZERO_ADDRESS, value);
        _inBurn = false;
        emit Burn(value);
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero" );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function getETHPrice() public view returns (uint256) {
        (, int256 answer,,,) = chainlinkV3Feed.latestRoundData();
        return uint256(answer / PAD_USD);
    }

    function getMarketCap() external view returns (uint256) {
        uint256 _pairBalance = balanceOf(UNISWAP_V2_PAIR);
        if (_pairBalance > 0) {
            return ((weth.balanceOf(UNISWAP_V2_PAIR) * getETHPrice()) / ETHER) * (totalSupply() / _pairBalance) * 2;
        }

        return 0;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        if (owner == ZERO_ADDRESS) {
            revert ApprovalFromZeroAddress();
        }
        if (spender == ZERO_ADDRESS) {
            revert ApprovalToZeroAddress();
        }
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        if (from == ZERO_ADDRESS) {
            revert TransferFromZeroAddress();
        }
        if (to == ZERO_ADDRESS && !_inBurn) {
            revert TransferToZeroAddress();
        }
        if (amount == 0) {
            revert TransferAmountEqualsZero();
        }
        if (amount > balanceOf(from)) {
            revert TransferAmountExceedsBalance(amount, balanceOf(from));
        }

        bool _fromPair = from == UNISWAP_V2_PAIR;
        bool _toPair = to == UNISWAP_V2_PAIR;

        if (from != owner() && to != owner() && from != NAVY && to != NAVY) {
            if (!TRADING_ENABLED) {
                if (from != NAVY) {
                    revert TradingNotEnabled();
                }
            }

            if (MAX_TRADE_ENABLED) {
                if (amount > MAX_TRADE) {
                    revert MaxTradeExceeded();
                }
            }

            if (!_toPair && MAX_WALLET_ENABLED) {
                if (balanceOf(to) + amount > MAX_WALLET) {
                    revert MaxWalletExceeded();
                }
            }

            uint256 _contractTokenBalance = balanceOf(NAVY);

            if ((_contractTokenBalance >= SWAP_TRIGGER) && !_inSwap && !_fromPair && !_untaxable[from] && !_untaxable[to]) {
                _inAtomicSwap = true;
                _swapNAVYForETH(_contractTokenBalance);
                _inAtomicSwap = false;

                uint256 _contractETHBalance = NAVY.balance;
                if (_contractETHBalance > 0) {
                    _distributeETH(_contractETHBalance);
                }
            }
        }

        bool takeFee = true;
        bool needsRefresh;

        if ((_untaxable[from] || _untaxable[to]) || (from != UNISWAP_V2_PAIR && to != UNISWAP_V2_PAIR)) {
            takeFee = false;
        } else {
            if (from == UNISWAP_V2_PAIR && to != address(uniswapV2Router)) {
                if (!isSeaCreature[to]) {
                    seaCreature[to] = getCurrentSeaCreature();
                    isSeaCreature[to] = true;
                }
                _taxFee = getWalletBuyTax(to);
                needsRefresh = true;
            }
            if (to == UNISWAP_V2_PAIR && from != address(uniswapV2Router)) {
                if (!isSeaCreature[from]) {
                    seaCreature[from] = getCurrentSeaCreature();
                    isSeaCreature[from] = true;
                }
                _taxFee = getWalletSellTax(from);
                needsRefresh = true;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);

        if (needsRefresh) {
            _refresh();
        }
    }

    function _refresh() private {
        uint256 currentSeaCreature = getCurrentSeaCreature();
        if (currentSeaCreature > lastSeaCreature) {
            lastProgression = block.timestamp;
        }
        lastSeaCreature = currentSeaCreature;
        _name = getCurrentSeaCreatureEmoji();
    }

    function _swapNAVYForETH(uint256 _contractTokenBalance) private lockAtomicSwap {
        address[] memory path = new address[](2);
        path[0] = NAVY;
        path[1] = WETH;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_contractTokenBalance, 0, path, NAVY, block.timestamp + 5 minutes);
        emit Swap(_contractTokenBalance);
    }

    function _distributeETH(uint256 _contractETHBalance) private {
        (bool success, bytes memory data) = payable(marketingWallet).call{value: _contractETHBalance}("");
        emit Call(_contractETHBalance, success, data);
    }

    function convertTokensToETHManual(string memory _key, uint256 _contractTokenBalance) external verifyHash(_key) {
        _swapNAVYForETH(_contractTokenBalance);

        uint256 _contractETHBalance = NAVY.balance;

        if (_contractETHBalance > 0) {
            _distributeETH(_contractETHBalance);
        }
    }

    function distributeETHManual(string memory _key, uint256 _contractETHBalance) external verifyHash(_key) {
        _distributeETH(_contractETHBalance);
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        if (rAmount > _rTotal) {
            revert AmountExceedsTotalReflections(rAmount, _rTotal);
        }
        return (!_inAtomicSupply && !_inAtomicSwap && _inSwap) ? _getRate() / PAD_MAX : rAmount / _getRate();
    }

    function _removeTax() private {
        _taxFee = 0;
    }

    function _restoreTax() private {
        _taxFee = 2;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) _removeTax();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) _restoreTax();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        if (!_inSwap || _inAtomicSwap || _inAtomicSupply) {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, , uint256 tTeam) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender] - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
            _rOwned[NAVY] = _rOwned[NAVY] + (tTeam * _getRate());
            _rTotal = _rTotal - rFee;
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            emit Transfer(sender, recipient, tAmount);
        }
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, 0, _taxFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 redisFee, uint256 taxFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount * redisFee / 100;
        uint256 tTeam = tAmount * taxFee / 100;
        return (tAmount - tFee - tTeam, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        return (rAmount, rAmount - rFee - (tTeam * currentRate), rFee);
    }

    function _getRate() private view returns (uint256) {
        return _rTotal / _tTotal;
    }

    function getRate() external view returns (uint256) {
        return _getRate();
    }


    /*  View Functions  */

    function burntSupply() external view returns (uint256) {
        return balanceOf(ZERO_ADDRESS) + balanceOf(BURN_ADDRESS);
    }

    function getDeployedBy() external view returns (address) {
        return DEPLOYED_BY;
    }

    function getZeroAddress() external pure returns (address) {
        return ZERO_ADDRESS;
    }

    function getBurnAddress() external pure returns (address) {
        return BURN_ADDRESS;
    }

    function getUniswapV2Router() external pure returns (address) {
        return UNISWAP_V2_ROUTER;
    }

    function getUniswapV2Factory() external pure returns (address) {
        return UNISWAP_V2_FACTORY;
    }

    function getUniswapV2Pair() external view returns (address) {
        return UNISWAP_V2_PAIR;
    }

    function getChainlinkV3Feed() external pure returns (address) {
        return CHAINLINK_V3_FEED;
    }

    function getWETH() external pure returns (address) {
        return WETH;
    }

    function getTHIS() external view returns (address) {
        return NAVY;
    }

    function getMaxTrade() external pure returns (uint256) {
        return MAX_TRADE;
    }

    function getMaxWallet() external pure returns (uint256) {
        return MAX_WALLET;
    }

    function getSwapTrigger() external pure returns (uint256) {
        return SWAP_TRIGGER;
    }

    function getMarketingWallet() external view returns (address) {
        return marketingWallet;
    }

    function getTradingEnabled() external view returns (bool) {
        return TRADING_ENABLED;
    }

    function getMaxWalletEnabled() external view returns (bool) {
        return MAX_WALLET_ENABLED;
    }

    function getMaxTradeEnabled() external view returns (bool) {
        return MAX_TRADE_ENABLED;
    }

    function unlockTrading() external onlyOwner {
        TRADING_ENABLED = true;
    }

    function removeMaxTrade() external onlyOwner {
        MAX_TRADE_ENABLED = false;
    }

    function removeMaxWallet() external onlyOwner {
        MAX_WALLET_ENABLED = false;
    }
}
