pragma solidity >=0.5.16;

import "./IKyotoxPair.sol";
import "./KyotoxERC20.sol";
import "./Math.sol";
import "./UQ112x112.sol";
import "./IERC20.sol";
import "./IKyotoxFactory.sol";
import "./IKyotoxCallee.sol";

contract KyotoxPair is KyotoxERC20 {
    using SafeMath for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;
    uint public constant MAX_FEE = 5_00;
    uint public constant FEE_BASE = 100_00;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0; // uses single storage slot, accessible via getReserves
    uint112 private reserve1; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint32 public fee;
    address public feeReceiver;
    uint public scheduledChange;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Kyotox: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Kyotox: TRANSFER_FAILED');
    }

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
    event FeeParamsChanged(uint32 fee, address feeReceiver);

    constructor() public {
        factory = msg.sender;
    }

    modifier onlyOwner() {
        require(IKyotoxFactory(factory).getOwner() == msg.sender, 'Kyotox: FORBIDDEN');
        _;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, uint32 _fee, address _feeReceiver) external {
        require(msg.sender == factory, 'Kyotox: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        feeReceiver = _feeReceiver;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Kyotox: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'Kyotox: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        uint _totalSupply = totalSupply;
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Kyotox: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function _feeAmount(uint amount) internal view returns (uint feeAmount) {
        feeAmount = (amount * fee) / (FEE_BASE - fee);
    }

    function _totalAmount(uint amount) internal view returns (uint totalAmount) {
        totalAmount = amount + _feeAmount(amount);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'Kyotox: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings

        require(
            _totalAmount(amount0Out) < _reserve0 && _totalAmount(amount1Out) < _reserve1,
            'Kyotox: INSUFFICIENT_LIQUIDITY'
        );

        uint balance0;
        uint balance1;

        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, 'Kyotox: INVALID_TO');

            if (amount0Out > 0) {
                // assume that enough amountIn was provided to cover both fee and amountOut
                _safeTransfer(_token0, feeReceiver, _feeAmount(amount0Out)); // optimistically transfer fee
                _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            }
            if (amount1Out > 0) {
                // assume that enough amountIn was provided to cover both fee and amountOut
                _safeTransfer(_token1, feeReceiver, _feeAmount(amount1Out)); // optimistically transfer fee
                _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            }
            if (data.length > 0) IKyotoxCallee(to).KyotoxCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }

        uint amount0In = balance0 > _reserve0 - _totalAmount(amount0Out)
            ? balance0 - (_reserve0 - _totalAmount(amount0Out))
            : 0;
        uint amount1In = balance1 > _reserve1 - _totalAmount(amount1Out)
            ? balance1 - (_reserve1 - _totalAmount(amount1Out))
            : 0;

        require(amount0In > 0 || amount1In > 0, 'Kyotox: INSUFFICIENT_INPUT_AMOUNT');
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
            uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
            require(
                balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000 ** 2),
                'Kyotox: K'
            );
        }

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function scheduleFeeChange() external onlyOwner {
        scheduledChange = block.timestamp + 86_400;
    }

    function setFeeData(uint32 _fee, address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), 'Kyotox: ZERO_FEE_RECEIPIENT');
        require(_fee < MAX_FEE, 'Kyotox: FEE_TOO_LARGE');
        require(scheduledChange < block.timestamp, 'Kyotox: TIMEOUT_NOT_REACHED');
        require(scheduledChange > 0, 'Kyotox: ACTION_NOT_SCHEDULED');
        scheduledChange = 0;
        fee = _fee;
        feeReceiver = _feeReceiver;
        emit FeeParamsChanged(fee, feeReceiver);
    }
}
