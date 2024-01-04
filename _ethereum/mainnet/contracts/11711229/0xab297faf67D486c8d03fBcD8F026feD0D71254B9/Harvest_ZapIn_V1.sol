// ███████╗░█████╗░██████╗░██████╗░███████╗██████╗░░░░███████╗██╗
// ╚════██║██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗░░░██╔════╝██║
// ░░███╔═╝███████║██████╔╝██████╔╝█████╗░░██████╔╝░░░█████╗░░██║
// ██╔══╝░░██╔══██║██╔═══╝░██╔═══╝░██╔══╝░░██╔══██╗░░░██╔══╝░░██║
// ███████╗██║░░██║██║░░░░░██║░░░░░███████╗██║░░██║██╗██║░░░░░██║
// ╚══════╝╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚══════╝╚═╝░░╚═╝╚═╝╚═╝░░░░░╚═╝
// Copyright (C) 2020 zapper

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Zapper
///@notice This contract adds liquidity to Harvest vaults with ETH or ERC tokens
// SPDX-License-Identifier: GPLv2

pragma solidity ^0.5.0;

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address payable public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account)
        internal
        pure
        returns (address payable)
    {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// -- Curve --
interface ICurveRegistry {
    function metaPools(address tokenAddress)
        external
        view
        returns (address swapAddress);
}

interface ICurveZapIn {
    function ZapIn(
        address _fromTokenAddress,
        address _toTokenAddress,
        address _swapAddress,
        uint256 _incomingTokenQty,
        uint256 _minPoolTokens,
        address _allowanceTarget,
        address _swapTarget,
        bytes calldata _swapCallData
    ) external payable returns (uint256 crvTokensBought);
}

// -- Uniswap --
interface IUniZapInV3 {
    function ZapIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _allowanceTarget,
        address _swapTarget,
        bytes calldata swapData
    ) external payable returns (uint256);
}

// -- Harvest --
interface IVault {
    function underlying() external view returns (address);

    function depositFor(uint256 amount, address holder) external;
}

contract Harvest_ZapIn_V1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool public stopped = false;
    uint256 public goodwill;

    ICurveRegistry public curveReg;
    ICurveZapIn public curveZap;
    IUniZapInV3 public uniZap;
    IUniZapInV3 public sushiZap;

    constructor(
        ICurveRegistry _curveReg,
        ICurveZapIn _curveZap,
        IUniZapInV3 _uniZap,
        IUniZapInV3 _sushiZap
    ) public {
        curveReg = _curveReg;
        curveZap = _curveZap;
        uniZap = _uniZap;
        sushiZap = _sushiZap;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    /**
    @notice This function adds liquidity to a Harvest vault with ETH or ERC20 tokens
    @param toWhomToIssue account that will recieve fTokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param vault Harvest vault address for the pool
    @param minToTokens The minimum acceptable quantity of tokens if a swap occurs. Reverts otherwise
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
     */
    function ZapInTokenVault(
        address toWhomToIssue,
        address fromToken,
        uint256 amountIn,
        address vault,
        uint256 minToTokens,
        address swapTarget,
        bytes calldata swapData
    ) external payable stopInEmergency {
        uint256 toInvest = _pullTokens(fromToken, amountIn, true);

        address vaultUnderlying = IVault(vault).underlying();

        uint256 toTokenAmt;
        if (fromToken == vaultUnderlying) {
            toTokenAmt = toInvest;
        } else {
            toTokenAmt = _fillQuote(
                fromToken,
                vaultUnderlying,
                toInvest,
                swapTarget,
                swapData
            );
            require(toTokenAmt >= minToTokens, "Err: High Slippage");
        }

        _vaultDeposit(toWhomToIssue, vaultUnderlying, toTokenAmt, vault);
    }

    /**
    @notice This function adds liquidity to a Curve Harvest vault with ETH or ERC20 tokens
    @param toWhomToIssue account that will recieve fTokens
    @param fromToken The token used for entry (address(0) if ether)
    @param toTokenAddress The intermediate token to swap to (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param vault Harvest vault address for the pool
    @param minCrvTokens The minimum acceptable quantity of LP tokens. Reverts otherwise
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
     */
    function ZapInCurveVault(
        address toWhomToIssue,
        address fromToken,
        address toTokenAddress,
        uint256 amountIn,
        address vault,
        uint256 minCrvTokens,
        address swapTarget,
        bytes calldata swapData
    ) external payable stopInEmergency {
        uint256 toInvest = _pullTokens(fromToken, amountIn, false);

        address curveTokenAddr = IVault(vault).underlying();
        address curveDepositAddr = curveReg.metaPools(curveTokenAddr);
        uint256 curveLP;

        if (fromToken != address(0)) {
            IERC20(fromToken).safeApprove(address(curveZap), toInvest);
            curveLP = curveZap.ZapIn(
                fromToken,
                toTokenAddress,
                curveDepositAddr,
                toInvest,
                minCrvTokens,
                swapTarget,
                swapTarget,
                swapData
            );
        } else {
            curveLP = curveZap.ZapIn.value(toInvest)(
                fromToken,
                toTokenAddress,
                curveDepositAddr,
                toInvest,
                minCrvTokens,
                swapTarget,
                swapTarget,
                swapData
            );
        }

        // deposit to vault
        _vaultDeposit(toWhomToIssue, curveTokenAddr, curveLP, vault);
    }

    /**
    @notice This function adds liquidity to a Uniswap Harvest vault with ETH or ERC20 tokens
    @param toWhomToIssue account that will recieve fTokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param vault Harvest vault address for the pool
    @param minUniTokens The minimum acceptable quantity of LP tokens. Reverts otherwise
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
     */
    function ZapInUniVault(
        address toWhomToIssue,
        address fromToken,
        uint256 amountIn,
        address vault,
        uint256 minUniTokens,
        address swapTarget,
        bytes calldata swapData
    ) external payable stopInEmergency {
        uint256 toInvest = _pullTokens(fromToken, amountIn, false);

        address uniPair = IVault(vault).underlying();
        uint256 uniLP;
        if (fromToken == address(0)) {
            uniLP = uniZap.ZapIn.value(toInvest)(
                fromToken,
                uniPair,
                toInvest,
                minUniTokens,
                swapTarget,
                swapTarget,
                swapData
            );
        } else {
            IERC20(fromToken).safeApprove(address(uniZap), toInvest);
            uniLP = uniZap.ZapIn(
                fromToken,
                uniPair,
                toInvest,
                minUniTokens,
                swapTarget,
                swapTarget,
                swapData
            );
        }

        _vaultDeposit(toWhomToIssue, uniPair, uniLP, vault);
    }

    /**
    @notice This function adds liquidity to a Sushiswap Harvest vault with ETH or ERC20 tokens
    @param toWhomToIssue account that will recieve fTokens
    @param fromToken The token used for entry (address(0) if ether)
    @param amountIn The amount of fromToken to invest
    @param vault Harvest vault address for the pool
    @param minSushiTokens The minimum acceptable quantity of LP tokens. Reverts otherwise
    @param swapTarget Excecution target for the first swap
    @param swapData DEX quote data
     */
    function ZapInSushiVault(
        address toWhomToIssue,
        address fromToken,
        uint256 amountIn,
        address vault,
        uint256 minSushiTokens,
        address swapTarget,
        bytes calldata swapData
    ) external payable stopInEmergency {
        // get incoming tokens
        uint256 toInvest = _pullTokens(fromToken, amountIn, false);

        // get sushi lp tokens
        address sushiPair = IVault(vault).underlying();
        uint256 sushiLP;
        if (fromToken == address(0)) {
            sushiLP = sushiZap.ZapIn.value(toInvest)(
                fromToken,
                sushiPair,
                toInvest,
                minSushiTokens,
                swapTarget,
                swapTarget,
                swapData
            );
        } else {
            IERC20(fromToken).safeApprove(address(sushiZap), toInvest);
            sushiLP = sushiZap.ZapIn(
                fromToken,
                sushiPair,
                toInvest,
                minSushiTokens,
                swapTarget,
                swapTarget,
                swapData
            );
        }

        // deposit to vault
        _vaultDeposit(toWhomToIssue, sushiPair, sushiLP, vault);
    }

    function _pullTokens(
        address token,
        uint256 amount,
        bool enableGoodwill
    ) internal returns (uint256 value) {
        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");
            value = msg.value;
        } else {
            require(amount > 0, "Invalid token amount");
            require(msg.value == 0, "Eth sent with token");
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            value = amount;
        }

        if (enableGoodwill && goodwill > 0) {
            uint256 goodwillPortion = (value.mul(goodwill)).div(10000);
            value = value.sub(goodwillPortion);
        }

        return value;
    }

    function _vaultDeposit(
        address toWhomToIssue,
        address underlyingToken,
        uint256 underlyingAmt,
        address vault
    ) internal {
        IERC20(underlyingToken).safeApprove(vault, underlyingAmt);
        IVault(vault).depositFor(underlyingAmt, toWhomToIssue);
    }

    function _fillQuote(
        address _fromTokenAddress,
        address toToken,
        uint256 _amount,
        address swapTarget,
        bytes memory swapCallData
    ) internal returns (uint256 amtBought) {
        uint256 valueToSend;
        if (_fromTokenAddress == address(0)) {
            valueToSend = _amount;
        } else {
            IERC20 fromToken = IERC20(_fromTokenAddress);
            fromToken.safeApprove(address(swapTarget), 0);
            fromToken.safeApprove(address(swapTarget), _amount);
        }

        uint256 iniBal = IERC20(toToken).balanceOf(address(this));
        (bool success, ) = swapTarget.call.value(valueToSend)(swapCallData);
        require(success, "Error Swapping Tokens 1");
        uint256 finalBal = IERC20(toToken).balanceOf(address(this));

        amtBought = finalBal.sub(iniBal);
    }

    function updateCurveRegistry(ICurveRegistry _curveReg) external onlyOwner {
        curveReg = _curveReg;
    }

    function updateCurveZap(ICurveZapIn _curveZap) external onlyOwner {
        curveZap = _curveZap;
    }

    function updateUniZap(IUniZapInV3 _uniZap) external onlyOwner {
        uniZap = _uniZap;
    }

    function updateSushiZap(IUniZapInV3 _sushiZap) external onlyOwner {
        sushiZap = _sushiZap;
    }

    function set_new_goodwill(uint256 _new_goodwill) external onlyOwner {
        require(
            _new_goodwill >= 0 && _new_goodwill <= 100,
            "GoodWill Value not allowed"
        );
        goodwill = _new_goodwill;
    }

    function toggleContractActive() external onlyOwner {
        stopped = !stopped;
    }

    function withdrawTokens(IERC20[] calldata _tokenAddresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            _tokenAddresses[i].safeTransfer(
                owner(),
                _tokenAddresses[i].balanceOf(address(this))
            );
        }
    }

    function withdrawETH() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        address payable _to = Address.toPayable(owner());
        _to.transfer(contractBalance);
    }
}