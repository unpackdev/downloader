// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.1.0

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/libs/TransferHelper.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/interfaces/ICoFiXVaultForStaking.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines methods for CoFiXVaultForStaking
interface ICoFiXVaultForStaking {

    /// @dev Modify configuration
    /// @param cofiUnit CoFi mining unit
    function setConfig(uint cofiUnit) external;

    /// @dev Get configuration
    /// @return cofiUnit CoFi mining unit
    function getConfig() external view returns (uint cofiUnit);

    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param weights weight array
    function batchSetPoolWeight(address[] calldata xtokens, uint[] calldata weights) external;

    /// @dev Get total staked amount of xtoken
    /// @param xtoken xtoken address (or CNode address)
    /// @return totalStaked Total lock volume of target xtoken
    /// @return cofiPerBlock Mining speed, cofi per block
    function getChannelInfo(address xtoken) external view returns (uint totalStaked, uint cofiPerBlock);

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, address addr) external view returns (uint);

    /// @dev Get the number of CoFi to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return The number of CoFi to be collected by the target address on the designated transaction lock
    function earned(address xtoken, address addr) external view returns (uint);

    /// @dev Stake xtoken to earn CoFi, this method is only for CoFiXRouter
    /// @param xtoken xtoken address (or CNode address)
    /// @param to Target address
    /// @param amount Stake amount
    function routerStake(address xtoken, address to, uint amount) external;
    
    /// @dev Stake xtoken to earn CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Stake amount
    function stake(address xtoken, uint amount) external;

    /// @dev Withdraw xtoken, and claim earned CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Withdraw amount
    function withdraw(address xtoken, uint amount) external;

    /// @dev Claim CoFi
    /// @param xtoken xtoken address (or CNode address)
    function getReward(address xtoken) external;
}


// File contracts/interfaces/ICoFiXRouter.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines methods for CoFiXRouter
interface ICoFiXRouter {

    /// @dev Register trade pair
    /// @param token0 pair-token0. 0 address means eth
    /// @param token1 pair-token1. 0 address means eth
    /// @param pool Pool for the trade pair
    function registerPair(address token0, address token1, address pool) external;

    /// @dev Get pool address for trade pair
    /// @param token0 pair-token0. 0 address means eth
    /// @param token1 pair-token1. 0 address means eth
    /// @return pool Pool for the trade pair
    function pairFor(address token0, address token1) external view returns (address pool);

    /// @dev Register routing path
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param path Routing path
    function registerRouterPath(address src, address dest, address[] calldata path) external;

    /// @dev Get routing path from src token address to dest token address
    /// @param src Src token address
    /// @param dest Dest token address
    /// @return path If success, return the routing path, 
    /// each address in the array represents the token address experienced during the trading
    function getRouterPath(address src, address dest) external view returns (address[] memory path);

    /// @dev Maker add liquidity to pool, get pool token (mint XToken to maker) 
    /// (notice: msg.value = amountETH + oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The deadline of this request
    /// @return xtoken The liquidity share token address obtained
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidity(
        address pool,
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external payable returns (address xtoken, uint liquidity);

    /// @dev Maker add liquidity to pool, get pool token (mint XToken) and stake automatically 
    /// (notice: msg.value = amountETH + oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The deadline of this request
    /// @return xtoken The liquidity share token address obtained
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidityAndStake(
        address pool,
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external payable returns (address xtoken, uint liquidity);

    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) 
    /// (notice: msg.value = oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param  amountETHMin The minimum amount of ETH wanted to get from pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The deadline of this request
    /// @return amountETH The real amount of ETH transferred from the pool
    /// @return amountToken The real amount of Token transferred from the pool
    function removeLiquidityGetTokenAndETH(
        address pool,
        address token,
        uint liquidity,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountETH, uint amountToken);

    /// @dev Swap exact tokens for tokens
    /// @param  path Routing path. If you need to exchange through multi-level routes, you need to write down all 
    /// token addresses (ETH address is represented by 0) of the exchange path
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The minimum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The deadline of this request
    /// @return amountOut The real amount of Token transferred out of pool
    function swapExactTokensForTokens(
        address[] calldata path,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint amountOut);

    /// @dev Acquire the transaction mining share of the target XToken
    /// @param xtoken The destination XToken address
    /// @return Target XToken's transaction mining share
    function getTradeReward(address xtoken) external view returns (uint);
}


// File contracts/interfaces/ICoFiXDAO.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the DAO methods
interface ICoFiXDAO {

    /// @dev Application Flag Changed event
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    event ApplicationChanged(address addr, uint flag);
    
    /// @dev Configuration structure of CoFiXDAO contract
    struct Config {
        // Redeem status, 1 means normal
        uint8 status;

        // The number of CoFi redeem per block. 100
        uint16 cofiPerBlock;

        // The maximum number of CoFi in a single redeem. 30000
        uint32 cofiLimit;

        // Price deviation limit, beyond this upper limit stop redeem (10000 based). 1000
        uint16 priceDeviationLimit;
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Set DAO application
    /// @param addr DAO application contract address
    /// @param flag Authorization flag, 1 means authorization, 0 means cancel authorization
    function setApplication(address addr, uint flag) external;

    /// @dev Check DAO application flag
    /// @param addr DAO application contract address
    /// @return Authorization flag, 1 means authorization, 0 means cancel authorization
    function checkApplication(address addr) external view returns (uint);

    /// @dev Set the exchange relationship between the token and the price of the anchored target currency.
    /// For example, set USDC to anchor usdt, because USDC is 18 decimal places and usdt is 6 decimal places. 
    /// so exchange = 1e6 * 1 ether / 1e18 = 1e6
    /// @param token Address of origin token
    /// @param target Address of target anchor token
    /// @param exchange Exchange rate of token and target
    function setTokenExchange(address token, address target, uint exchange) external;

    /// @dev Get the exchange relationship between the token and the price of the anchored target currency.
    /// For example, set USDC to anchor usdt, because USDC is 18 decimal places and usdt is 6 decimal places. 
    /// so exchange = 1e6 * 1 ether / 1e18 = 1e6
    /// @param token Address of origin token
    /// @return target Address of target anchor token
    /// @return exchange Exchange rate of token and target
    function getTokenExchange(address token) external view returns (address target, uint exchange);

    /// @dev Add reward
    /// @param pool Destination pool
    function addETHReward(address pool) external payable;

    /// @dev The function returns eth rewards of specified pool
    /// @param pool Destination pool
    function totalETHRewards(address pool) external view returns (uint);

    /// @dev Settlement
    /// @param pool Destination pool. Indicates which pool to pay with
    /// @param tokenAddress Token address of receiving funds (0 means ETH)
    /// @param to Address to receive
    /// @param value Amount to receive
    function settle(address pool, address tokenAddress, address to, uint value) external payable;

    /// @dev Redeem CoFi for ethers
    /// @notice Eth fee will be charged
    /// @param amount The amount of CoFi
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    function redeem(uint amount, address payback) external payable;

    /// @dev Redeem CoFi for Token
    /// @notice Eth fee will be charged
    /// @param token The target token
    /// @param amount The amount of CoFi
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    function redeemToken(address token, uint amount, address payback) external payable;

    /// @dev Get the current amount available for repurchase
    function quotaOf() external view returns (uint);
}


// File contracts/interfaces/ICoFiXMapping.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for CoFiX builtin contract address mapping
interface ICoFiXMapping {

    /// @dev Set the built-in contract address of the system
    /// @param cofiToken Address of CoFi token contract
    /// @param cofiNode Address of CoFi Node contract
    /// @param cofixDAO ICoFiXDAO implementation contract address
    /// @param cofixRouter ICoFiXRouter implementation contract address for CoFiX
    /// @param cofixController ICoFiXController implementation contract address
    /// @param cofixVaultForStaking ICoFiXVaultForStaking implementation contract address
    function setBuiltinAddress(
        address cofiToken,
        address cofiNode,
        address cofixDAO,
        address cofixRouter,
        address cofixController,
        address cofixVaultForStaking
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return cofiToken Address of CoFi token contract
    /// @return cofiNode Address of CoFi Node contract
    /// @return cofixDAO ICoFiXDAO implementation contract address
    /// @return cofixRouter ICoFiXRouter implementation contract address for CoFiX
    /// @return cofixController ICoFiXController implementation contract address
    function getBuiltinAddress() external view returns (
        address cofiToken,
        address cofiNode,
        address cofixDAO,
        address cofixRouter,
        address cofixController,
        address cofixVaultForStaking
    );

    /// @dev Get address of CoFi token contract
    /// @return Address of CoFi Node token contract
    function getCoFiTokenAddress() external view returns (address);

    /// @dev Get address of CoFi Node contract
    /// @return Address of CoFi Node contract
    function getCoFiNodeAddress() external view returns (address);

    /// @dev Get ICoFiXDAO implementation contract address
    /// @return ICoFiXDAO implementation contract address
    function getCoFiXDAOAddress() external view returns (address);

    /// @dev Get ICoFiXRouter implementation contract address for CoFiX
    /// @return ICoFiXRouter implementation contract address for CoFiX
    function getCoFiXRouterAddress() external view returns (address);

    /// @dev Get ICoFiXController implementation contract address
    /// @return ICoFiXController implementation contract address
    function getCoFiXControllerAddress() external view returns (address);

    /// @dev Get ICoFiXVaultForStaking implementation contract address
    /// @return ICoFiXVaultForStaking implementation contract address
    function getCoFiXVaultForStakingAddress() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by CoFiX system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string calldata key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string calldata key) external view returns (address);
}


// File contracts/interfaces/ICoFiXGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This interface defines the governance methods
interface ICoFiXGovernance is ICoFiXMapping {

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight 
    /// to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}


// File contracts/CoFiXBase.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
// Router contract to interact with each CoFiXPair, no owner or governance
/// @dev Base contract of CoFiX
contract CoFiXBase {

    // Address of CoFiToken contract
    address constant COFI_TOKEN_ADDRESS = 0x1a23a6BfBAdB59fa563008c0fB7cf96dfCF34Ea1;

    // Address of CoFiNode contract
    address constant CNODE_TOKEN_ADDRESS = 0x558201DC4741efc11031Cdc3BC1bC728C23bF512;

    // Genesis block number of CoFi
    // CoFiToken contract is created at block height 11040156. However, because the mining algorithm of CoFiX1.0
    // is different from that at present, a new mining algorithm is adopted from CoFiX2.1. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the CoFi begins to decay. According to the circulation when CoFi2.0 is online, the new mining
    // algorithm is used to deduce and convert the CoFi, and the new algorithm is used to mine the CoFiX2.1
    // on-line flow, the actual block is 11040688
    uint constant COFI_GENESIS_BLOCK = 11040688;

    /// @dev ICoFiXGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance ICoFiXGovernance implementation contract address
    function initialize(address governance) virtual public {
        require(_governance == address(0), "CoFiX:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance ICoFiXGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || ICoFiXGovernance(governance).checkGovernance(msg.sender, 0), "CoFiX:!gov");
        _governance = newGovernance;
    }

    /// @dev Migrate funds from current contract to CoFiXDAO
    /// @param tokenAddress Destination token address.(0 means eth)
    /// @param value Migrate amount
    function migrate(address tokenAddress, uint value) external onlyGovernance {

        address to = ICoFiXGovernance(_governance).getCoFiXDAOAddress();
        if (tokenAddress == address(0)) {
            ICoFiXDAO(to).addETHReward { value: value } (address(0));
        } else {
            TransferHelper.safeTransfer(tokenAddress, to, value);
        }
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(ICoFiXGovernance(_governance).checkGovernance(msg.sender, 0), "CoFiX:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "CoFiX:!contract");
        _;
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v4.1.0

// MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/Context.sol@v4.1.0

// MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/ERC20.sol@v4.1.0

// MIT

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


// File contracts/CoFiToken.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
// CoFiToken with Governance. It offers possibilities to adopt off-chain gasless governance infra.
contract CoFiToken is ERC20("CoFi Token", "CoFi") {

    address public governance;
    mapping (address => bool) public minters;

    // Copied and modified from SUSHI code:
    // https://github.com/sushiswap/sushiswap/blob/master/contracts/SushiToken.sol
    // Which is copied and modified from YAM code and COMPOUND:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint nonce,uint expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @dev An event thats emitted when a new governance account is set
    /// @param  _new The new governance address
    event NewGovernance(address _new);

    /// @dev An event thats emitted when a new minter account is added
    /// @param  _minter The new minter address added
    event MinterAdded(address _minter);

    /// @dev An event thats emitted when a minter account is removed
    /// @param  _minter The minter address removed
    event MinterRemoved(address _minter);

    modifier onlyGovernance() {
        require(msg.sender == governance, "CoFi: !governance");
        _;
    }

    constructor() {
        governance = msg.sender;
    }

    function setGovernance(address _new) external onlyGovernance {
        require(_new != address(0), "CoFi: zero addr");
        require(_new != governance, "CoFi: same addr");
        governance = _new;
        emit NewGovernance(_new);
    }

    function addMinter(address _minter) external onlyGovernance {
        minters[_minter] = true;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) external onlyGovernance {
        minters[_minter] = false;
        emit MinterRemoved(_minter);
    }

    /// @notice mint is used to distribute CoFi token to users, minters are CoFi mining pools
    function mint(address _to, uint _amount) external {
        require(minters[msg.sender], "CoFi: !minter");
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    /// @notice SUSHI has a vote governance bug in its token implementation, CoFi fixed it here
    /// read https://blog.peckshield.com/2020/09/08/sushi/
    function transfer(address _recipient, uint _amount) public override returns (bool) {
        super.transfer(_recipient, _amount);
        _moveDelegates(_delegates[msg.sender], _delegates[_recipient], _amount);
        return true;
    }

    /// @notice override original transferFrom to fix vote issue
    function transferFrom(address _sender, address _recipient, uint _amount) public override returns (bool) {
        super.transferFrom(_sender, _recipient, _amount);
        _moveDelegates(_delegates[_sender], _delegates[_recipient], _amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "CoFi::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "CoFi::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "CoFi::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint)
    {
        require(blockNumber < block.number, "CoFi::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint delegatorBalance = balanceOf(delegator); // balance of underlying CoFis (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint srcRepNew = srcRepOld - (amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint dstRepNew = dstRepOld + (amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint oldVotes,
        uint newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "CoFi::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}


// File contracts/CoFiXVaultForStaking.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Stake xtoken or CNode, earn CoFi
contract CoFiXVaultForStaking is CoFiXBase, ICoFiXVaultForStaking {

    /// @dev Account information
    struct Account {
        // Staked of current account
        uint160 balance;
        // Token dividend value mark of the unit that the account has received
        uint96 rewardCursor;
    }
    
    /// @dev Stake channel information
    struct StakeChannel{

        // Mining amount weight
        uint cofiWeight;
        // Total staked amount
        uint totalStaked;

        // xtoken global sign
        // Total ore drawing mark of settled transaction
        uint128 tradeReward;
        // Total settled ore output mark
        //uint128 totalReward;
        // The dividend mark that the settled company token can receive
        uint96 rewardPerToken;
        // Settlement block mark
        uint32 blockCursor;

        // Accounts
        // address=>balance
        mapping(address=>Account) accounts;
    }
    
    // // CoFi mining speed weight base
    // uint constant COFI_WEIGHT_BASE = 1e9;

    // CoFi mining unit
    uint _cofiUnit;

    // Address of CoFiXRouter
    address _cofixRouter;
    
    // staking通道信息xtoken=>StakeChannel
    mapping(address=>StakeChannel) _channels;
    
    /// @dev Create CoFiXVaultForStaking
    constructor () {
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance ICoFiXGovernance implementation contract address
    function update(address newGovernance) public override {
        super.update(newGovernance);
        _cofixRouter = ICoFiXGovernance(newGovernance).getCoFiXRouterAddress();
    }

    modifier onlyRouter() {
        require(msg.sender == _cofixRouter, "CoFiXPair: Only for CoFiXRouter");
        _;
    }

    /// @dev Modify configuration
    /// @param cofiUnit CoFi mining unit
    function setConfig(uint cofiUnit) external override onlyGovernance {
        _cofiUnit = cofiUnit;
    }

    /// @dev Get configuration
    /// @return cofiUnit CoFi mining unit
    function getConfig() external view override returns (uint cofiUnit) {
        return _cofiUnit;
    }

    /// @dev Initialize ore drawing weight
    /// @param xtokens xtoken array
    /// @param weights weight array
    function batchSetPoolWeight(address[] calldata xtokens, uint[] calldata weights) external override onlyGovernance {
        uint cnt = xtokens.length;
        require(cnt == weights.length, "CoFiXVaultForStaking: mismatch len");
        for (uint i = 0; i < cnt; ++i) {
            address xtoken = xtokens[i];
            require(xtoken != address(0), "CoFiXVaultForStaking: invalid xtoken");
            StakeChannel storage channel = _channels[xtoken] ;
            _updateReward(xtoken, channel);
            channel.cofiWeight = weights[i];
        }
    }

    /// @dev Get stake channel information
    /// @param xtoken xtoken address (or CNode address)
    /// @return totalStaked Total lock volume of target xtoken
    /// @return cofiPerBlock Mining speed, cofi per block
    function getChannelInfo(address xtoken) external view override returns (uint totalStaked, uint cofiPerBlock) {
        StakeChannel storage channel = _channels[xtoken];
        return (channel.totalStaked, uint(channel.cofiWeight) * _cofiUnit);
    }

    /// @dev Get staked amount of target address
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(address xtoken, address addr) external view override returns (uint) {
        return uint(_channels[xtoken].accounts[addr].balance);
    }

    /// @dev Get the number of CoFi to be collected by the target address on the designated transaction pair lock
    /// @param xtoken xtoken address (or CNode address)
    /// @param addr Target address
    /// @return The number of CoFi to be collected by the target address on the designated transaction lock
    function earned(address xtoken, address addr) public view override returns (uint) {
        // Load staking channel
        StakeChannel storage channel = _channels[xtoken];
        // Call _calcReward() to calculate new reward
        uint newReward = _calcReward(channel);
        
        // Load account
        Account memory account = channel.accounts[addr];
        uint balance = uint(account.balance);
        // Load total amount of staked
        uint totalStaked = channel.totalStaked;
        if (xtoken == CNODE_TOKEN_ADDRESS) {
            // Get the cumulative share of the trading ore output of the corresponding track
            newReward += ICoFiXRouter(_cofixRouter).getTradeReward(xtoken) - uint(channel.tradeReward);
            // Since there are no decimal places in CNode, in order to unify the accuracy, when calculating 
            // the dividend of CNode unit token, the quantity is multiplied by 1 ether
            //balance *= 1 ether;
            //totalStaked *= 1 ether;
        }

        // Unit token dividend
        uint rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }
        
        return (rewardPerToken - _decodeFloat(account.rewardCursor)) * balance / 1 ether;
    }

    /// @dev Stake xtoken to earn CoFi, this method is only for CoFiXRouter
    /// @param xtoken xtoken address (or CNode address)
    /// @param to Target address
    /// @param amount Stake amount
    function routerStake(address xtoken, address to, uint amount) external override onlyRouter {
        // Load stake channel
        StakeChannel storage channel = _channels[xtoken];
        // Settle reward for account
        Account memory account = _getReward(xtoken, channel, to);

        // Update totalStaked
        channel.totalStaked += amount;

        // Update stake balance of account
        account.balance = uint160(uint(account.balance) + amount);
        channel.accounts[to] = account;
    }

    /// @dev Stake xtoken to earn CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Stake amount
    function stake(address xtoken, uint amount) external override {
        // Load stake channel
        StakeChannel storage channel = _channels[xtoken];
        // Settle reward for account
        Account memory account = _getReward(xtoken, channel, msg.sender);

        // Transfer xtoken from msg.sender to this
        TransferHelper.safeTransferFrom(xtoken, msg.sender, address(this), amount);
        // Update totalStaked
        channel.totalStaked += amount;

        // Update stake balance of account
        account.balance = uint160(uint(account.balance) + amount);
        channel.accounts[msg.sender] = account;
    }

    /// @dev Withdraw xtoken, and claim earned CoFi
    /// @param xtoken xtoken address (or CNode address)
    /// @param amount Withdraw amount
    function withdraw(address xtoken, uint amount) external override {
        // Load stake channel
        StakeChannel storage channel = _channels[xtoken];
        // Settle reward for account
        Account memory account = _getReward(xtoken, channel, msg.sender);

        // Update totalStaked
        channel.totalStaked -= amount;
        // Update stake balance of account
        account.balance = uint160(uint(account.balance) - amount);
        channel.accounts[msg.sender] = account;

        // Transfer xtoken to msg.sender
        TransferHelper.safeTransfer(xtoken, msg.sender, amount);
    }

    /// @dev Claim CoFi
    /// @param xtoken xtoken address (or CNode address)
    function getReward(address xtoken) external override {
        StakeChannel storage channel = _channels[xtoken];
        channel.accounts[msg.sender] = _getReward(xtoken, channel, msg.sender);
    }

    // Calculate reward, and settle the target account
    function _getReward(
        address xtoken, 
        StakeChannel storage channel, 
        address to
    ) private returns (Account memory account) {
        // Load account
        account = channel.accounts[to];
        // Update the global dividend information and get the new unit token dividend amount
        uint rewardPerToken = _updateReward(xtoken, channel);
        
        // Calculate reward for account
        uint balance = uint(account.balance);
        // if (xtoken == CNODE_TOKEN_ADDRESS) {
        //     //balance *= 1 ether;
        // }
        uint reward = (rewardPerToken - _decodeFloat(account.rewardCursor)) * balance / 1 ether;
        
        // Update sign of account
        account.rewardCursor = _encodeFloat(rewardPerToken);
        //channel.accounts[to] = account;

        // Transfer CoFi to account
        if (reward > 0) {
            CoFiToken(COFI_TOKEN_ADDRESS).mint(to, reward);
        }
    }

    // Update the global dividend information and return the new unit token dividend amount
    function _updateReward(address xtoken, StakeChannel storage channel) private returns (uint rewardPerToken) {
        // Call _calcReward() to calculate new reward
        uint newReward = _calcReward(channel);

        // Load total amount of staked
        uint totalStaked = channel.totalStaked;
        if (xtoken == CNODE_TOKEN_ADDRESS) {
            // Obtain the cumulative share of the trading ore output of the corresponding channel
            uint tradeReward = ICoFiXRouter(_cofixRouter).getTradeReward(xtoken);
            newReward += tradeReward - uint(channel.tradeReward);
            channel.tradeReward = uint128(tradeReward);
            // Since there are no decimal places in CNode, in order to unify the accuracy, 
            // when calculating the dividend of CNode unit token, the quantity is multiplied by 1 ether
            //totalStaked *= 1 ether;
        }
        
        rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }

        // Update the dividend value of unit share
        channel.rewardPerToken = _encodeFloat(rewardPerToken);
        // Update settled block number
        channel.blockCursor = uint32(block.number);
    }

    // Calculate new reward
    function _calcReward(StakeChannel storage channel) private view returns (uint newReward) {
        newReward =
            (block.number - uint(channel.blockCursor)) 
            * _reduction(block.number - COFI_GENESIS_BLOCK) 
            * _cofiUnit
            * channel.cofiWeight
            / 400 ;
    }

    /// @dev Calculate dividend data
    /// @param xtoken xtoken address (or CNode address)
    /// @return newReward Amount added since last settlement
    /// @return rewardPerToken New number of unit token dividends
    function calcReward(address xtoken) public view returns (
        uint newReward, 
        uint rewardPerToken
    ) {
        // Load staking channel
        StakeChannel storage channel = _channels[xtoken];
        // Call _calcReward() to calculate new reward
        newReward = _calcReward(channel);

        // Load total amount of staked
        uint totalStaked = channel.totalStaked;
        if (xtoken == CNODE_TOKEN_ADDRESS) {
            // Get the cumulative share of the trading ore output of the corresponding track
            newReward += ICoFiXRouter(_cofixRouter).getTradeReward(xtoken) - uint(channel.tradeReward);
            //totalStaked *= 1 ether;
        }

        rewardPerToken = _decodeFloat(channel.rewardPerToken);
        if (totalStaked > 0) {
            rewardPerToken += newReward * 1 ether / totalStaked;
        }
    }

    // CoFi ore drawing attenuation interval. 2400000 blocks, about one year
    uint constant COFI_REDUCTION_SPAN = 2400000;
    // The decay limit of CoFi ore drawing becomes stable after exceeding this interval. 24 million blocks, about 4 years
    uint constant COFI_REDUCTION_LIMIT = 9600000; // COFI_REDUCTION_SPAN * 4;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    uint constant COFI_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
        // 0
        // | (uint(400 / uint(1)) << (16 * 0))
        // | (uint(400 * 8 / uint(10)) << (16 * 1))
        // | (uint(400 * 8 * 8 / uint(10 * 10)) << (16 * 2))
        // | (uint(400 * 8 * 8 * 8 / uint(10 * 10 * 10)) << (16 * 3))
        // | (uint(400 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10)) << (16 * 4))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10)) << (16 * 5))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10)) << (16 * 6))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 7))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 8))
        // | (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 9))
        // //| (uint(400 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 * 8 / uint(10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10 * 10)) << (16 * 10));
        // | (uint(40) << (16 * 10));

    // Calculation of attenuation gradient
    function _reduction(uint delta) private pure returns (uint) {
        
        if (delta < COFI_REDUCTION_LIMIT) {
            return (COFI_REDUCTION_STEPS >> ((delta / COFI_REDUCTION_SPAN) << 4)) & 0xFFFF;
        }
        return (COFI_REDUCTION_STEPS >> 64) & 0xFFFF;
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint96) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint96((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint96 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }
}