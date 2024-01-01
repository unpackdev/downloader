// SPDX-License-Identifier: MIT

///@title Koto ERC20 Token
///@author Izanagi Dev
///@notice A stripped down ERC20 tax token that implements automated and continious monetary policy decisions.
///@dev Bonds are the ERC20 token in exchange for Ether. Unsold bonds with automatically carry over to the next day.
/// The bonding schedule is set to attempt to sell all of the tokens held within the contract in 1 day intervals. Taking a snapshot
/// of the amount currently held within the contract at the start of the next internal period, using this amount as the capcipty to be sold.

/// Socials
/// Telegram: https://t.me/IzanangiPortal

pragma solidity =0.8.22;

library PricingLibrary {
    // 1 Slot
    struct Data {
        uint48 lastTune;
        uint48 lastDecay; // last timestamp when market was created and debt was decayed
        uint48 length; // time from creation to conclusion. used as speed to decay debt.
        uint48 depositInterval; // target frequency of deposits
        uint48 tuneInterval; // frequency of tuning
    }

    // 2 Storage slots
    struct Market {
        uint96 capacity; // capacity remaining
        uint96 totalDebt; // total debt from market
        uint96 maxPayout; // max tokens in/out
        uint96 sold; // Koto out
        uint96 purchased; // Eth in
    }

    // 1 Storage Slot
    struct Adjustment {
        uint128 change;
        uint48 lastAdjustment;
        uint48 timeToAdjusted;
        bool active;
    }

    // 2 Storage slots
    struct Term {
        uint48 conclusion; // timestamp when the current market will end
        uint256 controlVariable; // scaling variable for price
    }

    function decay(Data memory data, Market memory market, Term memory terms, Adjustment memory adjustments)
        internal
        view
        returns (Market memory, Data memory, Term memory, Adjustment memory)
    {
        uint48 time = uint48(block.timestamp);
        market.totalDebt -= debtDecay(data, market);
        data.lastDecay = time;

        if (adjustments.active) {
            (uint128 adjustby, uint48 dt, bool stillActive) = controlDecay(adjustments);
            terms.controlVariable -= adjustby;
            if (stillActive) {
                adjustments.change -= adjustby;
                adjustments.timeToAdjusted -= dt;
                adjustments.lastAdjustment = time;
            } else {
                adjustments.active = false;
            }
        }
        return (market, data, terms, adjustments);
    }

    function controlDecay(Adjustment memory info) internal view returns (uint128, uint48, bool) {
        if (!info.active) return (0, 0, false);

        uint48 secondsSince = uint48(block.timestamp) - info.lastAdjustment;
        bool active = secondsSince < info.timeToAdjusted;
        uint128 _decay = active ? (info.change * secondsSince) / info.timeToAdjusted : info.change;
        return (_decay, secondsSince, active);
    }

    function marketPrice(uint256 _controlVariable, uint256 _totalDebt, uint256 _totalSupply)
        internal
        pure
        returns (uint256)
    {
        return ((_controlVariable * debtRatio(_totalDebt, _totalSupply)) / 1e18);
    }

    function debtRatio(uint256 _totalDebt, uint256 _totalSupply) internal pure returns (uint256) {
        return ((_totalDebt * 1e18) / _totalSupply);
    }

    function debtDecay(Data memory data, Market memory market) internal view returns (uint64) {
        uint256 secondsSince = block.timestamp - data.lastDecay;
        return uint64((market.totalDebt * secondsSince) / data.length);
    }

    struct TuneCache {
        uint256 remaining;
        uint256 price;
        uint256 capacity;
        uint256 targetDebt;
        uint256 ncv;
    }

    function tune(
        uint48 time,
        Market memory market,
        Term memory term,
        Data memory data,
        Adjustment memory adjustment,
        uint256 _totalSupply
    ) internal pure returns (Market memory, Term memory, Data memory, Adjustment memory) {
        TuneCache memory cache;
        if (time >= data.lastTune + data.tuneInterval) {
            cache.remaining = term.conclusion - time;
            cache.price = marketPrice(term.controlVariable, market.totalDebt, _totalSupply);
            cache.capacity = market.capacity; //Is this even necessary?
            market.maxPayout = uint96((cache.capacity * data.depositInterval / cache.remaining));
            cache.targetDebt = cache.capacity * data.length / cache.remaining;
            cache.ncv = (cache.price * _totalSupply) / cache.targetDebt;

            if (cache.ncv < term.controlVariable) {
                term.controlVariable = cache.ncv;
            } else {
                uint128 change = uint128(term.controlVariable - cache.ncv);
                adjustment = Adjustment(change, time, data.tuneInterval, true);
            }
            data.lastTune = time;
        }
        return (market, term, data, adjustment);
    }
}

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

contract Koto {
    struct Limits {
        uint96 maxWallet;
        uint96 maxTransactions;
        bool limits;
    }
    // ========================== STORAGE ========================== \\

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _excluded;
    mapping(address => bool) private _amms;
    uint256 private _totalSupply;

    PricingLibrary.Adjustment private adjustment;
    PricingLibrary.Data private data;
    PricingLibrary.Market private market;
    PricingLibrary.Term private term;
    Limits private limits;
    uint8 private locked;
    bool private launched;

    // =================== CONSTANTS / IMMUTABLES =================== \\

    string private constant NAME = "Koto";
    string private constant SYMBOL = "KOTO";
    uint8 private constant DECIMALS = 18;
    ///@dev flat 5% tax for buys and sells
    uint8 private constant FEE = 50;
    bool private immutable zeroForOne;
    address private constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant OWNER = 0x0688578EC7273458785591d3AfFD120E664900C2;
    address private constant BOND_DEPOSITORY = 0x0e58bD5557C4e0a0Abf0e8d4df24177Ae714452D;
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
        _mint(address(this), 7_000_000e18);
        _mint(OWNER, 2_000_000e18);
        _mint(BOND_DEPOSITORY, 1_000_000e18);
        limits = Limits({maxWallet: 100_000e18, maxTransactions: 100_000e18, limits: true});
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

            // Cache variables that are updated prior to marketprice call to reduce storage retreivals
            uint256 cachedControlVariable = _term.controlVariable;
            uint256 cachedTotalDebt = _market.totalDebt;

            // Can pass in structs here as nothing has been updated yet
            (_market, _data, _term, adjustments) = PricingLibrary.decay(data, _market, _term, adjustments);

            uint256 price = PricingLibrary.marketPrice(cachedControlVariable, cachedTotalDebt, _supply);

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

    function depository() external pure returns (address) {
        return BOND_DEPOSITORY;
    }

    // ========================= ADMIN FUNCTIONS ========================= \\

    ///@notice increase the liquidity of the uniswap v2 pair
    ///@param tokenAmount the amount of tokens to add to the LP pool
    ///@param ethAmount the amount of eth to add to the pool
    ///@dev both the eth and the tokens must already be held within the contract
    function increaseLiquidity(uint256 tokenAmount, uint256 ethAmount) external {
        if (msg.sender != OWNER) revert OnlyOwner();
        _addLiquidity(tokenAmount, ethAmount);
        emit IncreaseLiquidity(tokenAmount, ethAmount);
    }

    ///@notice remove a given address from fees and limits
    ///@param user the user to exclude from fees
    ///@dev this is a one way street so once a user has been excluded they can not then be removed
    function exclude(address user) external {
        if (msg.sender != OWNER) revert OnlyOwner();
        _excluded[user] = true;
        emit UserExcluded(user);
    }

    ///@notice remove trading and wallet limits
    function removeLimits() external {
        if (msg.sender != OWNER) revert OnlyOwner();
        limits.limits = false;
        emit LimitsRemoved(block.timestamp);
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
        emit OpenBondMarket(block.timestamp);
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

    ///@notice increase the liquidity of the Uniswap V2 Pair
    ///@param tokenAmount the amount of tokens to add to the pool
    ///@param ethAmount the amount of ETH to add to the pool
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0xf305d71900000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 4), and(address(), 0xffffffffffffffffffffffffffffffffffffffff))
            mstore(add(ptr, 36), tokenAmount)
            mstore(add(ptr, 68), 0)
            mstore(add(ptr, 100), 0)
            mstore(add(ptr, 132), BOND_DEPOSITORY)
            mstore(add(ptr, 164), timestamp())
            let result := call(gas(), UNISWAP_V2_ROUTER, ethAmount, ptr, 196, 0, 0)
            if iszero(result) { revert(0, 0) }
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
        uint256 initialPrice = _getPrice();
        uint96 targetDebt = uint96(_balances[address(this)]);
        uint96 capacity = targetDebt;
        uint96 maxPayout = uint96(targetDebt * 14400 / INTERVAL);
        uint256 controlVariable = initialPrice * _totalSupply / targetDebt;
        bool policy = _policy(capacity, initialPrice);
        uint48 conclusion = uint48(block.timestamp + INTERVAL);

        if (policy) {
            market = PricingLibrary.Market(capacity, targetDebt, maxPayout, 0, 0);
            term = PricingLibrary.Term(conclusion, controlVariable);
            data = PricingLibrary.Data(uint48(block.timestamp), uint48(block.timestamp), uint48(INTERVAL), 14400, 1800);
            emit CreateMarket(capacity, block.timestamp, conclusion);
        } else {
            _burn(address(this), capacity);
            // Set the markets so that they will be closed for the next interval. Important step to make sure
            // that if anyone accidently tries to buy a bond they get refunded their eth.
            term.conclusion = uint48(block.timestamp + INTERVAL);
            market.capacity = 0;
        }
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
        if (checkLimits(from, to, _value)) revert LimitsReached();
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
    function _getPrice() public view returns (uint256 price) {
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

    function _getTokens(address _pair) public view returns (address _token0, address _token1) {
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

    ///@notice check to see if a transaction is within the limits if limits are still enforced
    ///@param to the user who is either initiating the transaction or the user receiving the tokens
    ///@param value the amount of koto tokens within the transaction
    ///@return limited if the user has broken limits (true) or if they are okay to continue (false)
    ///@dev the case were limits are no longer in place is checked first to help save gas once they are turned off
    function checkLimits(address from, address to, uint256 value) private view returns (bool limited) {
        Limits memory _limits = limits;
        if (!_limits.limits) {
            limited = false;
        } else if (from == address(this) && to == pair) {
            limited = false;
        } else {
            if (
                (!_excluded[to] && !_excluded[from])
                    && (_limits.maxTransactions < value || _limits.maxWallet < (_balances[to] + value))
            ) {
                limited = true;
            } else {
                limited = false;
            }
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
    error InvalidTransfer();
    error LimitsReached();
    error MarketClosed();
    error MaxPayout();
    error OnlyOwner();
    error RedeemFailed();
    error Reentrancy();

    receive() external payable {
        if (msg.sender != OWNER && msg.sender != UNISWAP_V2_ROUTER) {
            bond();
        }
    }
}