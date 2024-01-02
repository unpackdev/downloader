// SPDX-License-Identifier: MIT

///@title Koto ERC20 Token
///@author Izanagi Dev
///@notice A stripped down ERC20 tax token that implements automated and continious monetary policy decisions.
///@dev Bonds are the ERC20 token in exchange for Ether. Unsold bonds with automatically carry over to the next day.
/// The bonding schedule is set to attempt to sell all of the tokens held within the contract in 1 day intervals. Taking a snapshot
/// of the amount currently held within the contract at the start of the next internal period, using this amount as the capcipty to be sold.

/// Socials
/// Telegram: https://t.me/KotoPortal

pragma solidity =0.8.22;

import "./PricingLibrary.sol";
import "./SafeTransferLib.sol";
import "./FullMath.sol";
import "./IERC20Minimal.sol";

contract KotoV2 {
    // ========================== STORAGE ========================== \\

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _excluded;
    mapping(address => bool) private _amms;
    uint256 private _totalSupply;

    // ====================== ETH BOND STORAGE ===================== \\

    PricingLibrary.Adjustment private adjustment;
    PricingLibrary.Data private data;
    PricingLibrary.Market private market;
    PricingLibrary.Term private term;

    // ====================== LP BOND STORAGE ====================== \\

    PricingLibrary.Adjustment private lpAdjustment;
    PricingLibrary.Data private lpData;
    PricingLibrary.Market private lpMarket;
    PricingLibrary.Term private lpTerm;

    uint256 ethCapacityNext;
    uint256 lpCapacityNext;

    uint8 private locked;
    bool private launched;

    // =================== CONSTANTS / IMMUTABLES =================== \\

    string private constant NAME = "Koto V2";
    string private constant SYMBOL = "KOTOV2";
    uint8 private constant DECIMALS = 18;
    ///@dev flat 5% tax for buys and sells
    uint8 private constant FEE = 50;
    bool private immutable zeroForOne;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant OWNER = 0x946eF43867225695E29241813A8F41519634B36b;
    address private constant BOND_DEPOSITORY = 0x298ECA8683000B3911B2e7Dd07FD496D8019043E;
    address private immutable pair;
    address private immutable token0;
    address private immutable token1;
    uint256 private constant INTERVAL = 86400; // 1 day in seconds

    // ========================== MODIFIERS ========================== \\

    modifier lock() {
        if (locked == 2) revert Reentrancy();
        locked = 2;
        _;
        locked = 1;
    }

    // ========================= CONTRUCTOR ========================= \\

    constructor() {
        pair = _createUniswapV2Pair(address(this), WETH);
        _excluded[OWNER] = true;
        _excluded[BOND_DEPOSITORY] = true;
        _excluded[address(this)] = true;
        _amms[pair] = true;
        _mint(OWNER, 8_500_000e18); //
        (token0, token1) = _getTokens(pair);
        zeroForOne = address(this) == token0 ? true : false;
        _allowances[address(this)][UNISWAP_V2_ROUTER] = type(uint256).max;
        ///@dev set term conclusion to type uint48 max to prevent bonds being created before opening them to the public
        term.conclusion = type(uint48).max;
    }

    // ==================== EXTERNAL FUNCTIONS ===================== \\

    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (_to == address(0) || _value == 0) revert InvalidTransfer();
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == address(0) || _value == 0) revert InvalidTransfer();
        if (_from != msg.sender) {
            if (_allowances[_from][msg.sender] < _value) revert InsufficentAllowance();
            _allowances[_from][msg.sender] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        address owner = msg.sender;
        _allowances[owner][_spender] = _value;
        return true;
    }

    ///@notice exchange ETH for Koto tokens at the current bonding price
    ///@dev bonds are set on 1 day intervals with 4 hour deposit intervals and 30 minute tune intervals.
    function bond() public payable lock returns (uint256 payout) {
        // If the previous market has ended create a new market.
        if (block.timestamp > term.conclusion) {
            _create();
        }
        if (market.capacity != 0) {
            // Cache variables for later use to minimize storage calls
            PricingLibrary.Market memory _market = market;
            PricingLibrary.Term memory _term = term;
            PricingLibrary.Data memory _data = data;
            PricingLibrary.Adjustment memory adjustments = adjustment;
            uint256 _supply = _totalSupply;
            uint48 time = uint48(block.timestamp);

            // Can pass in structs here as nothing has been updated yet
            (_market, _data, _term, adjustments) = PricingLibrary.decay(data, _market, _term, adjustments);

            uint256 price = PricingLibrary.marketPrice(_term.controlVariable, _market.totalDebt, _supply);

            payout = (msg.value * 1e18 / price);
            if (payout > market.maxPayout) revert MaxPayout();

            // Update market variables
            _market.capacity -= uint96(payout);
            _market.purchased += uint96(msg.value);
            _market.sold += uint96(payout);
            _market.totalDebt += uint96(payout);

            bool success = _bond(msg.sender, payout);
            if (!success) revert BondFailed();
            emit Bond(msg.sender, payout, price);

            //Touches market, data, terms, and adjustments
            (_market, _term, _data, adjustments) =
                PricingLibrary.tune(time, _market, _term, _data, adjustments, _supply);

            // Write changes to storage.
            market = _market;
            term = _term;
            data = _data;
            adjustment = adjustments;
        } else {
            //If bonds are not available refund the eth sent to the contract
            SafeTransferLib.safeTransferETH(msg.sender, msg.value);
        }
    }

    function bondLp(uint256 _lpAmount) public lock returns (uint256 payout) {
        // If the previous market has ended create a new market.
        if (block.timestamp > term.conclusion) {
            _createLpMarket();
        }
        if (lpMarket.capacity != 0) {
            IERC20Minimal(pair).transferFrom(msg.sender, address(BOND_DEPOSITORY), _lpAmount);
            // Cache variables for later use to minimize storage calls
            PricingLibrary.Market memory _market = lpMarket;
            PricingLibrary.Term memory _term = lpTerm;
            PricingLibrary.Data memory _data = lpData;
            PricingLibrary.Adjustment memory adjustments = lpAdjustment;
            uint256 _supply = _totalSupply;
            uint48 time = uint48(block.timestamp);

            // Can pass in structs here as nothing has been updated yet
            (_market, _data, _term, adjustments) = PricingLibrary.decay(lpData, _market, _term, adjustments);

            uint256 price = PricingLibrary.marketPrice(_term.controlVariable, _market.totalDebt, _supply);

            payout = (_lpAmount * 1e18 / price);
            if (payout > lpMarket.maxPayout) revert MaxPayout();

            // Update market variables
            _market.capacity -= uint96(payout);
            _market.purchased += uint96(_lpAmount);
            _market.sold += uint96(payout);
            _market.totalDebt += uint96(payout);

            bool success = _bond(msg.sender, payout);
            if (!success) revert BondFailed();
            emit Bond(msg.sender, payout, price);

            //Touches market, data, terms, and adjustments
            (_market, _term, _data, adjustments) =
                PricingLibrary.tune(time, _market, _term, _data, adjustments, _supply);

            // Write changes to storage.
            lpMarket = _market;
            lpTerm = _term;
            lpData = _data;
            lpAdjustment = adjustments;
        }
    }

    ///@notice burn Koto tokens in exchange for a piece of the underlying reserves
    ///@param amount The amount of Koto tokens to redeem
    ///@return payout The amount of ETH received in exchange for the Koto tokens
    function redeem(uint256 amount) external returns (uint256 payout) {
        // Underlying reserves per token
        uint256 price = (address(this).balance * 1e18) / _totalSupply;
        payout = (price * amount) / 1e18;
        _burn(msg.sender, amount);
        SafeTransferLib.safeTransferETH(msg.sender, payout);
        emit Redeem(msg.sender, amount, payout, price);
    }

    ///@notice burn Koto tokens, without redemption
    ///@param amount the amount of Koto to burn
    function burn(uint256 amount) external returns (bool success) {
        _burn(msg.sender, amount);
        success = true;
        emit Transfer(msg.sender, address(0), amount);
    }

    // ==================== EXTERNAL VIEW FUNCTIONS ===================== \\

    ///@notice get the tokens name
    function name() public pure returns (string memory) {
        return NAME;
    }

    ///@notice get the tokens symbol
    function symbol() public pure returns (string memory) {
        return SYMBOL;
    }

    ///@notice get the tokens decimals
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }

    ///@notice get the tokens total supply
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    ///@notice get the current balance of a user
    ///@param _owner the user whos balance you want to check
    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

    ///@notice get current approved amount for transfer from another party
    ///@param owner the current owner of the tokens
    ///@param spender the user who has approval (or not) to spend the owners tokens
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    ///@notice return the Uniswap V2 Pair address
    function pool() external view returns (address) {
        return pair;
    }

    ///@notice get the owner of the contract
    ///@dev ownership is nontransferable and limited to opening trade, exclusion / inclusion,s and increasing liquidity
    function ownership() external pure returns (address) {
        return OWNER;
    }

    ///@notice the current price a bond
    function bondPrice() external view returns (uint256) {
        return PricingLibrary.marketPrice(term.controlVariable, market.totalDebt, _totalSupply);
    }

    function bondPriceLp() external view returns (uint256) {
        return PricingLibrary.marketPrice(lpTerm.controlVariable, lpMarket.totalDebt, _totalSupply);
    }

    ///@notice return the current redemption price for 1 uint of Koto.
    function redemptionPrice() external view returns (uint256) {
        return ((address(this).balance * 1e18) / _totalSupply);
    }

    function marketInfo()
        external
        view
        returns (PricingLibrary.Market memory, PricingLibrary.Term memory, PricingLibrary.Data memory)
    {
        return (market, term, data);
    }

    function lpMarketInfo()
        external
        view
        returns (PricingLibrary.Market memory, PricingLibrary.Term memory, PricingLibrary.Data memory)
    {
        return (lpMarket, lpTerm, lpData);
    }

    function depository() external pure returns (address) {
        return BOND_DEPOSITORY;
    }

    // ========================= ADMIN FUNCTIONS ========================= \\

    ///@notice remove a given address from fees and limits
    ///@param user the user to exclude from fees
    ///@dev this is a one way street so once a user has been excluded they can not then be removed
    function exclude(address user) external {
        if (msg.sender != OWNER) revert OnlyOwner();
        _excluded[user] = true;
        emit UserExcluded(user);
    }

    ///@notice add a amm pool / pair
    ///@param _pool the address of the pool / pair to add
    function addAmm(address _pool) external {
        if (msg.sender != OWNER) revert OnlyOwner();
        _amms[_pool] = true;
        emit AmmAdded(_pool);
    }

    ///@notice seed the initial liquidity from this contract.
    function launch() external {
        if (msg.sender != OWNER) revert OnlyOwner();
        if (launched) revert AlreadyLaunched();
        _addInitialLiquidity();
        launched = true;
        emit Launched(block.timestamp);
    }

    ///@notice opens the bond market
    ///@dev the liquidity pool must already be launched and initialized. As well as tokens sent to this contract from
    /// the bond depository.
    function open() external {
        if (msg.sender != OWNER) revert OnlyOwner();
        _create();
        _createLpMarket();
        emit OpenBondMarket(block.timestamp);
    }

    ///TODO: change back to permissioned prior to launch.
    function create(uint256 ethBondAmount, uint256 lpBondAmount) external {
        if (msg.sender != OWNER && msg.sender != BOND_DEPOSITORY) revert InvalidSender();
        uint256 total = ethBondAmount + lpBondAmount;
        transferFrom(msg.sender, address(this), total);
        ethCapacityNext = ethBondAmount;
        lpCapacityNext = lpBondAmount;
    }

    // ========================= INTERNAL FUNCTIONS ========================= \\

    ///@notice create the Uniswap V2 Pair
    ///@param _token0 token 0 of the pair
    ///@param _token1 token 1 of the pair
    ///@return _pair the pair address
    function _createUniswapV2Pair(address _token0, address _token1) private returns (address _pair) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0xc9c6539600000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 4), and(_token0, 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(ptr, 36), and(_token1, 0xffffffffffffffffffffffffffffffffffffffff))
            let result := call(gas(), UNISWAP_V2_FACTORY, 0, ptr, 68, 0, 32)
            if iszero(result) { revert(0, 0) }
            _pair := mload(0x00)
        }
    }

    function _addInitialLiquidity() private {
        uint256 tokenAmount = _balances[address(this)];
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0xf305d71900000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 4), and(address(), 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(ptr, 36), tokenAmount)
            mstore(add(ptr, 68), 0)
            mstore(add(ptr, 100), 0)
            mstore(add(ptr, 132), BOND_DEPOSITORY)
            mstore(add(ptr, 164), timestamp())
            let result := call(gas(), UNISWAP_V2_ROUTER, balance(address()), ptr, 196, 0, 0)
            if iszero(result) { revert(0, 0) }
        }
    }

    ///@notice create the next bond market information
    ///@dev this is done automatically if the previous market conclusion has passed
    /// time check must be done elsewhere as the initial conclusion is set to uint48 max,
    /// tokens must also already be held within the contract or else the call will revert
    function _create() private {
        // Set the initial price to the current market price
        uint96 targetDebt = uint96(ethCapacityNext);
        if (ethCapacityNext > 0) {
            uint256 initialPrice = _getPrice();

            uint96 capacity = targetDebt;
            uint96 maxPayout = uint96(targetDebt * 14400 / INTERVAL);
            uint256 controlVariable = initialPrice * _totalSupply / targetDebt;
            bool policy = _policy(capacity, initialPrice);
            uint48 conclusion = uint48(block.timestamp + INTERVAL);

            if (policy) {
                market = PricingLibrary.Market(capacity, targetDebt, maxPayout, 0, 0);
                term = PricingLibrary.Term(conclusion, controlVariable);
                data =
                    PricingLibrary.Data(uint48(block.timestamp), uint48(block.timestamp), uint48(INTERVAL), 14400, 1800);
                emit CreateMarket(capacity, block.timestamp, conclusion);
            } else {
                _burn(address(this), capacity);
                // Set the markets so that they will be closed for the next interval. Important step to make sure
                // that if anyone accidently tries to buy a bond they get refunded their eth.
                term.conclusion = uint48(block.timestamp + INTERVAL);
                market.capacity = 0;
            }
        }
        ethCapacityNext = 0;
    }

    function _createLpMarket() private {
        uint96 targetDebt = uint96(lpCapacityNext);
        if (targetDebt > 0) {
            uint256 initialPrice = _getLpPrice();
            uint96 capacity = targetDebt;
            uint96 maxPayout = uint96(targetDebt * 14400 / INTERVAL);
            uint256 controlVariable = initialPrice * _totalSupply / targetDebt;
            bool policy = _policy(capacity, initialPrice);
            uint48 conclusion = uint48(block.timestamp + INTERVAL);

            if (policy) {
                lpMarket = PricingLibrary.Market(capacity, targetDebt, maxPayout, 0, 0);
                lpTerm = PricingLibrary.Term(conclusion, controlVariable);
                lpData =
                    PricingLibrary.Data(uint48(block.timestamp), uint48(block.timestamp), uint48(INTERVAL), 14400, 1800);
                emit CreateMarket(capacity, block.timestamp, conclusion);
            } else {
                _burn(address(this), capacity);
                // Set the markets so that they will be closed for the next interval. Important step to make sure
                // that if anyone accidently tries to buy a bond they get refunded their eth.
                lpTerm.conclusion = uint48(block.timestamp + INTERVAL);
                lpMarket.capacity = 0;
            }
        }
        lpCapacityNext = 0;
    }

    ///@notice determines if to sell the tokens available as bonds or to burn them instead
    ///@param capacity the amount of tokens that will be available within the next bonding cycle
    ///@param price the starting price of the bonds to sell
    ///@return decision the decision reached determining which is more valuable to sell the bonds (true) or to burn them (false)
    ///@dev the decision is made optimistically using the initial price as the selling price for the deicison. If selling the tokens all at the starting
    /// price does not increase relative reserves more than burning the tokens then they are burned. If they are equivilant burning wins out.
    function _policy(uint256 capacity, uint256 price) private view returns (bool decision) {
        uint256 supply = _totalSupply;
        uint256 burnRelative = (address(this).balance * 1e18) / (supply - capacity);
        uint256 bondRelative = ((address(this).balance * 1e18) + ((capacity * price))) / supply;
        decision = burnRelative >= bondRelative ? false : true;
    }

    function _transfer(address from, address to, uint256 _value) private {
        if (_value > _balances[from]) revert InsufficentBalance();
        bool fees;
        if (_amms[to] || _amms[from]) {
            if (_excluded[to] || _excluded[from]) {
                fees = false;
            } else {
                fees = true;
            }
        }
        if (fees) {
            uint256 fee = (_value * FEE) / 1000;

            unchecked {
                _balances[from] -= _value;
                _balances[BOND_DEPOSITORY] += fee;
            }
            _value -= fee;
            unchecked {
                _balances[to] += _value;
            }
        } else {
            unchecked {
                _balances[from] -= _value;
                _balances[to] += _value;
            }
        }
        emit Transfer(from, to, _value);
    }

    ///@notice mint new koto tokens
    ///@param to the user who will receive the tokens
    ///@param value the amount of tokens to mint
    ///@dev this function is used once, during the creation of the contract and is then
    /// not callable
    function _mint(address to, uint256 value) private {
        unchecked {
            _balances[to] += value;
            _totalSupply += value;
        }
        emit Transfer(address(0), to, value);
    }

    ///@notice burn koto tokens
    ///@param from the user to burn the tokens from
    ///@param value the amount of koto tokens to burn
    function _burn(address from, uint256 value) private {
        if (_balances[from] < value) revert InsufficentBalance();
        unchecked {
            _balances[from] -= value;
            _totalSupply -= value;
        }
        emit Transfer(from, address(0), value);
    }

    ///@notice send the user the correct amount of tokens after the have bought a bond
    ///@param to the user to send the tokens to
    ///@param value the amount of koto tokens to send
    ///@dev bonds are not subject to taxes
    function _bond(address to, uint256 value) private returns (bool success) {
        if (value > _balances[address(this)]) revert InsufficentBondsAvailable();
        unchecked {
            _balances[to] += value;
            _balances[address(this)] -= value;
        }
        success = true;
        emit Transfer(address(this), to, value);
    }

    ///@notice calculate the current market price based on the reserves of the Uniswap Pair
    ///@dev price is returned as the amount of ETH you would get back for 1 full (1e18) Koto tokens
    function _getPrice() private view returns (uint256 price) {
        address _pair = pair;
        uint112 reserve0;
        uint112 reserve1;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)
            let success := staticcall(gas(), _pair, ptr, 4, 0, 0)
            if iszero(success) { revert(0, 0) }
            returndatacopy(0x00, 0, 32)
            returndatacopy(0x20, 0x20, 32)
            reserve0 := mload(0x00)
            reserve1 := mload(0x20)
        }

        if (zeroForOne) {
            price = (uint256(reserve1) * 1e18) / uint256(reserve0);
        } else {
            price = (uint256(reserve0) * 1e18) / uint256(reserve1);
        }
    }

    function _getLpPrice() private view returns (uint256 _lpPrice) {
        address _pair = pair;
        uint112 reserve0;
        uint112 reserve1;
        uint256 lpTotalSupply;
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)
            let success := staticcall(gas(), _pair, ptr, 4, 0, 0)
            if iszero(success) { revert(0, 0) }
            returndatacopy(0x00, 0, 32)
            returndatacopy(0x20, 0x20, 32)
            reserve0 := mload(0x00)
            reserve1 := mload(0x20)
            mstore(add(ptr, 0x20), 0x18160ddd00000000000000000000000000000000000000000000000000000000)
            let result := staticcall(gas(), _pair, add(ptr, 0x20), 4, 0, 32)
            lpTotalSupply := mload(0x00)
        }
        ///@dev with uniswap v2 we simply treat the other token total as equal value to simplify the pricing mechanism
        if (zeroForOne) {
            _lpPrice = FullMath.mulDiv(reserve0 * 2, 1e18, lpTotalSupply);
        } else {
            _lpPrice = FullMath.mulDiv(reserve1 * 2, 1e18, lpTotalSupply);
        }
    }

    function _getTokens(address _pair) private view returns (address _token0, address _token1) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x0dfe168100000000000000000000000000000000000000000000000000000000)
            let resultToken0 := staticcall(gas(), _pair, ptr, 4, 0, 32)
            mstore(add(ptr, 4), 0xd21220a700000000000000000000000000000000000000000000000000000000)
            let resultToken1 := staticcall(gas(), _pair, add(ptr, 4), 4, 32, 32)
            if or(iszero(resultToken0), iszero(resultToken1)) { revert(0, 0) }
            _token0 := mload(0x00)
            _token1 := mload(0x20)
        }
    }

    // ========================= EVENTS ========================= \\

    event AmmAdded(address poolAdded);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Bond(address indexed buyer, uint256 amount, uint256 bondPrice);
    event CreateMarket(uint256 bonds, uint256 start, uint48 end);
    event IncreaseLiquidity(uint256 kotoAdded, uint256 ethAdded);
    event Launched(uint256 time);
    event LimitsRemoved(uint256 time);
    event OpenBondMarket(uint256 openingTime);
    event Redeem(address indexed sender, uint256 burned, uint256 payout, uint256 floorPrice);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event UserExcluded(address indexed userToExclude);

    // ========================= ERRORS ========================= \\

    error AlreadyLaunched();
    error BondFailed();
    error InsufficentAllowance();
    error InsufficentBalance();
    error InsufficentBondsAvailable();
    error InvalidSender();
    error InvalidTransfer();
    error LimitsReached();
    error MarketClosed();
    error MaxPayout();
    error OnlyOwner();
    error RedeemFailed();
    error Reentrancy();

    receive() external payable {}
}
