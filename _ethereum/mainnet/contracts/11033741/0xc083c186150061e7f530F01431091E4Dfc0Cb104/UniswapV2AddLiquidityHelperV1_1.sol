// Dependency file: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

// import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.6.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// Dependency file: contracts/libraries2/UniswapV2Library.sol

// pragma solidity >=0.5.0;

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
}


// Dependency file: contracts/libraries2/TransferHelper.sol

// pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// Dependency file: contracts/interfaces/IUniswapV2Router01.sol

// pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// Dependency file: contracts/interfaces/IUniswapV2Router02.sol

// pragma solidity >=0.6.2;

// import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// Dependency file: contracts/interfaces/IWETH.sol

// pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// Root file: contracts/UniswapV2AddLiquidityHelperV1_1.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

// import "./Ownable.sol";
// import "./IERC20.sol";
// import "./UniswapV2Library.sol";
// import "./TransferHelper.sol";
// import "./IUniswapV2Router02.sol";
// import "./IWETH.sol";

/// @author Roger Wu (Twitter: @rogerwutw, GitHub: Roger-Wu)
// updates from V1:
// * use binary search to find amountAToSwap, which fix ETH-USDT and ETH-USDC tx failure problem and saves gas
// * remove deadline to save gas
// * make _receiveToken inline to save gas
// * make _swapToSyncRatio inline to save gas
// * remove 1 _approveTokenToRouterIfNecessary call to save gas.
// * replace SafeERC20 with TransferHelper to save gas.
// * remove _approveTokenToRouterIfNecessary to save gas.
// * replace some public with external
// total gas saving: ~28852
contract UniswapV2AddLiquidityHelperV1_1 is Ownable {
    // using SafeMath for uint;
    // using SafeERC20 for IERC20;

    address public immutable _uniswapV2FactoryAddress; // 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    address public immutable _uniswapV2Router02Address; // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    address public immutable _wethAddress; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

    constructor(
        address uniswapV2FactoryAddress,
        address uniswapV2Router02Address,
        address wethAddress
    ) public {
        _uniswapV2FactoryAddress = uniswapV2FactoryAddress;
        _uniswapV2Router02Address = uniswapV2Router02Address;
        _wethAddress = wethAddress;
    }

    // fallback() external payable {}
    receive() external payable {}

    // Add as more tokenA and tokenB as possible to a Uniswap pair.
    // The ratio between tokenA and tokenB can be any.
    // Approve enough amount of tokenA and tokenB to this contract before calling this function.
    // Uniswap pair tokenA-tokenB must exist.
    function swapAndAddLiquidityTokenAndToken(
        address tokenAddressA,
        address tokenAddressB,
        uint112 amountA,
        uint112 amountB,
        uint112 minLiquidityOut,
        address to
    ) external returns(uint liquidity) {
        require(amountA > 0 || amountB > 0, "amounts can not be both 0");

        // transfer user's tokens to this contract
        if (amountA > 0) {
            // _receiveToken(tokenAddressA, amountA);
            TransferHelper.safeTransferFrom(tokenAddressA, msg.sender, address(this), uint(amountA));
        }
        if (amountB > 0) {
            // _receiveToken(tokenAddressB, amountB);
            TransferHelper.safeTransferFrom(tokenAddressB, msg.sender, address(this), uint(amountB));
        }

        return _swapAndAddLiquidity(
            tokenAddressA,
            tokenAddressB,
            uint(amountA),
            uint(amountB),
            uint(minLiquidityOut),
            to
        );
    }

    // Add as more ether and tokenB as possible to a Uniswap pair.
    // The ratio between ether and tokenB can be any.
    // Approve enough amount of tokenB to this contract before calling this function.
    // Uniswap pair WETH-tokenB must exist.
    function swapAndAddLiquidityEthAndToken(
        address tokenAddressB,
        uint112 amountB,
        uint112 minLiquidityOut,
        address to
    ) external payable returns(uint liquidity) {
        uint amountA = msg.value;
        address tokenAddressA = _wethAddress;

        require(amountA > 0 || amountB > 0, "amounts can not be both 0");

        // convert ETH to WETH
        IWETH(_wethAddress).deposit{value: amountA}();
        // transfer user's tokenB to this contract
        if (amountB > 0) {
            // _receiveToken(tokenAddressB, amountB);
            TransferHelper.safeTransferFrom(tokenAddressB, msg.sender, address(this), uint(amountB));
        }

        return _swapAndAddLiquidity(
            tokenAddressA,
            tokenAddressB,
            amountA,
            uint(amountB),
            uint(minLiquidityOut),
            to
        );
    }

    // add as more tokens as possible to a Uniswap pair
    function _swapAndAddLiquidity(
        address tokenAddressA,
        address tokenAddressB,
        uint amountA,
        uint amountB,
        uint minLiquidityOut,
        address to
    ) internal returns(uint liquidity) {
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(_uniswapV2FactoryAddress, tokenAddressA, tokenAddressB);

        // Swap tokenA and tokenB s.t. amountA / reserveA >= amountB / reserveB
        // (or amountA * reserveB >= reserveA * amountB)
        // which means we will swap part of tokenA to tokenB before adding liquidity.
        if (amountA * reserveB < reserveA * amountB) {
            (tokenAddressA, tokenAddressB) = (tokenAddressB, tokenAddressA);
            (reserveA, reserveB) = (reserveB, reserveA);
            (amountA, amountB) = (amountB, amountA);
        }
        uint amountAToAdd = amountA;
        uint amountBToAdd = amountB;
        // _approveTokenToRouterIfNecessary(tokenAddressA, amountA);
        if (IERC20(tokenAddressA).allowance(address(this), _uniswapV2Router02Address) < amountA) {
            TransferHelper.safeApprove(tokenAddressA, _uniswapV2Router02Address, 2**256 - 1);
        }

        uint amountAToSwap = calcAmountAToSwap(reserveA, reserveB, amountA, amountB);
        require(amountAToSwap <= amountA, "bugs in calcAmountAToSwap cause amountAToSwap > amountA");
        if (amountAToSwap > 0) {
            address[] memory path = new address[](2);
            path[0] = tokenAddressA;
            path[1] = tokenAddressB;

            uint[] memory swapOutAmounts = IUniswapV2Router02(_uniswapV2Router02Address).swapExactTokensForTokens(
                amountAToSwap, // uint amountIn,
                1, // uint amountOutMin,
                path, // address[] calldata path,
                address(this), // address to,
                2**256-1 // uint deadline
            );

            amountAToAdd -= amountAToSwap;
            amountBToAdd += swapOutAmounts[swapOutAmounts.length - 1];
        }

        // _approveTokenToRouterIfNecessary(tokenAddressB, amountBToAdd);
        if (IERC20(tokenAddressB).allowance(address(this), _uniswapV2Router02Address) < amountBToAdd) {
            TransferHelper.safeApprove(tokenAddressB, _uniswapV2Router02Address, 2**256 - 1);
        }
        (, , liquidity) = IUniswapV2Router02(_uniswapV2Router02Address).addLiquidity(
            tokenAddressA, // address tokenA,
            tokenAddressB, // address tokenB,
            amountAToAdd, // uint amountADesired,
            amountBToAdd, // uint amountBDesired,
            1, // uint amountAMin,
            1, // uint amountBMin,
            to, // address to,
            2**256-1 // uint deadline
        );

        require(liquidity >= minLiquidityOut, "minted liquidity not enough");

        // Due to the inaccuracy of integer division,
        // there may be a small amount of tokens left in this contract.
        // Usually it doesn't worth it to spend more gas to transfer them out.
        // These tokens will be considered as a donation to the owner.
        // All ether and tokens directly sent to this contract will be considered as a donation to the contract owner.
    }

    function calcAmountAToSwap(
        uint reserveA,
        uint reserveB,
        uint amountA,
        uint amountB
    ) public pure returns(
        uint amountAToSwap
    ) {
        // require(reserveA > 0 && reserveB > 0, "reserves can't be empty");
        // require(reserveA < 2**112 && reserveB < 2**112, "reserves must be < 2**112");
        // require(amountA < 2**112 && amountB < 2**112, "amounts must be < 2**112");
        // require(amountA * reserveB >= reserveA * amountB, "require amountA / amountB >= reserveA / reserveB");

        // separating requirements somehow saves gas.
        require(reserveA > 0, "reserveA can't be empty");
        require(reserveB > 0, "reserveB can't be empty");
        require(reserveA < 2**112, "reserveA must be < 2**112");
        require(reserveB < 2**112, "reserveB must be < 2**112");
        require(amountA < 2**112, "amountA must be < 2**112");
        require(amountB < 2**112, "amountB must be < 2**112");
        require(amountA * reserveB >= reserveA * amountB, "require amountA / amountB >= reserveA / reserveB");

        uint l = 0; // minAmountAToSwap
        uint r = amountA; // maxAmountAToSwap
        // avoid binary search going too deep. saving gas
        uint tolerance = amountA / 10000;
        if (tolerance == 0) { tolerance = 1; }
        uint newReserveA;
        uint newReserveB;
        uint newAmountA;
        uint newAmountB;

        // cache rA_times_1000 and rA_times_rB_times_1000 to save gas
        // Since reserveA, reserveB are both < 2**112,
        // rA_times_rB_times_1000 won't overflow.
        uint rA_times_1000 = reserveA * 1000;
        uint rA_times_rB_times_1000 = rA_times_1000 * reserveB;

        // goal:
        //   after swap l tokenA,
        //     newAmountA / newAmountB >= newReserveA / newReserveB
        //   after swap r tokenA,
        //     newAmountA / newAmountB < newReserveA / newReserveB
        //   r <= l + tolerance
        while (l + tolerance < r) {
            amountAToSwap = (l + r) / 2;

            newReserveA = reserveA + amountAToSwap;
            // (1000 * reserveA + 997 * amountAToSwap) * newReserveB = 1000 * reserveA * reserveB
            newReserveB = rA_times_rB_times_1000 / (rA_times_1000 + 997 * amountAToSwap);
            newAmountA = amountA - amountAToSwap; // amountAToSwap <= amountA
            newAmountB = amountB + (reserveB - newReserveB); // newReserveB <= reserveB
            if (newAmountA * newReserveB >= newReserveA * newAmountB) {
                l = amountAToSwap;
            } else {
                r = amountAToSwap;
            }
        }
        return l;
    }

    // function _receiveToken(address tokenAddress, uint amount) internal {
    //     TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), amount);
    // }

    // function _approveTokenToRouterIfNecessary(address tokenAddress, uint amount) internal {
    //     if (IERC20(tokenAddress).allowance(address(this), _uniswapV2Router02Address) < amount) {
    //         TransferHelper.safeApprove(tokenAddress, _uniswapV2Router02Address, 2**256 - 1);
    //     }
    // }

    function emergencyWithdrawEther() external onlyOwner {
        (msg.sender).transfer(address(this).balance);
    }

    function emergencyWithdrawErc20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        TransferHelper.safeTransfer(tokenAddress, msg.sender, token.balanceOf(address(this)));
    }
}