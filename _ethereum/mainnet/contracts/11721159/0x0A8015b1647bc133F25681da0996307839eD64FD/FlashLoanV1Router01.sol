pragma solidity =0.6.6;


interface IFlashLoanV1Factory {
    event PoolCreated(address indexed token, address pool, uint);

    function feeInBips() external view returns (uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPool(address token) external view returns (address pool);
    function allPools(uint) external view returns (address pool);
    function allPoolsLength() external view returns (uint);

    function createPool(address token) external returns (address pool);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IFlashLoanV1Pool {
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

    event Mint(address indexed sender, uint amount);
    event Burn(address indexed sender, uint amount, address indexed to);
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint amount,
        uint premium
    );
    event Sync(uint reserve);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token() external view returns (address);
    function reserve() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount);
    function flashLoan(address target, uint amount, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

interface IFlashLoanV1Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address token,
        uint amount,
        address to,
        uint deadline
    ) external returns (uint liquidity);
    function addLiquidityETH(
        address to,
        uint deadline
    ) external payable returns (uint liquidity);
    function removeLiquidity(
        address token,
        uint liquidity,
        address to,
        uint deadline
    ) external returns (uint amount);
    function removeLiquidityETH(
        uint liquidity,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityWithPermit(
        address token,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amount);
    function removeLiquidityETHWithPermit(
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
    function flashLoan(
        address token,
        address target,
        uint amount,
        uint deadline,
        bytes calldata data
    ) external;
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library FlashLoanV1Library {
    using SafeMath for uint;

    // calculates the CREATE2 address for a pool without making any external calls
    function poolFor(address factory, address token) internal pure returns (address pool) {
        pool = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token)),
                hex'6c57ed802dc5d4d6ce04dc39f66e6d2a6cebf8b7efbc068ce7b0419f5ee4ade1' // init code hash
            ))));
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

contract FlashLoanV1Router01 is IFlashLoanV1Router01 {
    using SafeMath for uint;

    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'FlashLoanV1Router: EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH) public {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    function addLiquidity(
        address token,
        uint amount,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint liquidity) {
        if (IFlashLoanV1Factory(factory).getPool(token) == address(0)) {
            IFlashLoanV1Factory(factory).createPool(token);
        }
        address pool = FlashLoanV1Library.poolFor(factory, token);
        TransferHelper.safeTransferFrom(token, msg.sender, pool, amount);
        liquidity = IFlashLoanV1Pool(pool).mint(to);
    }
    function addLiquidityETH(
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint liquidity) {
        if (IFlashLoanV1Factory(factory).getPool(WETH) == address(0)) {
            IFlashLoanV1Factory(factory).createPool(WETH);
        }
        address pool = FlashLoanV1Library.poolFor(factory, WETH);
        IWETH(WETH).deposit{value: msg.value}();
        assert(IWETH(WETH).transfer(pool, msg.value));
        liquidity = IFlashLoanV1Pool(pool).mint(to);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address token,
        uint liquidity,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amount) {
        address pool = FlashLoanV1Library.poolFor(factory, token);
        IFlashLoanV1Pool(pool).transferFrom(msg.sender, pool, liquidity);
        amount = IFlashLoanV1Pool(pool).burn(to);
    }
    function removeLiquidityETH(
        uint liquidity,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        amountETH = removeLiquidity(WETH, liquidity, address(this), deadline);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }
    function removeLiquidityWithPermit(
        address token,
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amount) {
        address pool = FlashLoanV1Library.poolFor(factory, token);
        uint value = approveMax ? uint(-1) : liquidity;
        IFlashLoanV1Pool(pool).permit(msg.sender, address(this), value, deadline, v, r, s);
        amount = removeLiquidity(token, liquidity, to, deadline);
    }
    function removeLiquidityETHWithPermit(
        uint liquidity,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pool = FlashLoanV1Library.poolFor(factory, WETH);
        uint value = approveMax ? uint(-1) : liquidity;
        IFlashLoanV1Pool(pool).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETH(liquidity, to, deadline);
    }

    // **** FLASH LOAN ****
    function flashLoan(
        address token,
        address target,
        uint amount,
        uint deadline,
        bytes calldata data
    ) external virtual override ensure(deadline) {
        address pool = FlashLoanV1Library.poolFor(factory, token);
        IFlashLoanV1Pool(pool).flashLoan(target, amount, data);
    }
}