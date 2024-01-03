pragma solidity >=0.6.6;

import "./IERC20.sol";
import "./IxEXCV.sol";
import "./IxCAVO.sol";
import "./IExcavoFactory.sol";
import "./IExcavoCallee.sol";
import "./IExcavoPair.sol";
import "./Math.sol";
import "./UQ112x112.sol";
import "./PairLibrary.sol";
import "./BaseExcavoPair.sol";

contract ExcavoPair is IExcavoPair, BaseExcavoPair {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    event Compound(address indexed owner, uint liquidityGrowth);

    struct SwapDetails {
        uint balance0;
        uint balance1;
        address _token0;
        address _token1;
        uint balance0Adjusted;
        uint balance1Adjusted;
    }

    uint public constant override MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'Excavo: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getReserves() public view override returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = data.reserve0;
        _reserve1 = data.reserve1;
        _blockTimestampLast = data.blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory _data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (_data.length == 0 || abi.decode(_data, (bool))), 'Excavo: TRANSFER_FAILED');
    }

    constructor() public {
        data.factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, address _router) external override lock {
        data.initialize(_token0, _token1, _router);
    }       

    function setCAVO(address _CAVO, address _xCAVO) external override lock {
        data.setCAVO(_CAVO, _xCAVO);
    }

    function setxEXCV(address _xEXCV) external override lock {
        data.setxEXCV(_xEXCV);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'Excavo: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - data.blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            data.price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            data.price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        data.reserve0 = uint112(balance0);
        data.reserve1 = uint112(balance1);
        data.blockTimestampLast = blockTimestamp;
        emit Sync(data.reserve0, data.reserve1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock override returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(data.token0).balanceOf(address(this));
        uint balance1 = IERC20(data.token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);
        uint _totalSupply = data.totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        uint _liquidity = Math.sqrt(amount0.mul(amount1));
        if (_totalSupply == 0) {
            liquidity = _liquidity.sub(MINIMUM_LIQUIDITY);
            _mint(address(0), MINIMUM_LIQUIDITY, MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            require(liquidity > 0, 'Excavo: INSUFFICIENT_LIQUIDITY_MINTED');
            _mint(to, liquidity, liquidity);
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
            require(liquidity > 0, 'Excavo: INSUFFICIENT_LIQUIDITY_MINTED');
            _mint(to, liquidity, _liquidity);
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) public override lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = data.token0;                                // gas savings
        address _token1 = data.token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        uint liquidity = data.balanceOf[address(this)];
        uint _totalSupply = data.totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'Excavo: INSUFFICIENT_LIQUIDITY_BURNED');

        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata _data, uint discount) external override lock {
        require(msg.sender == data.router, "Excavo: FORBIDDEN");
        SwapDetails memory details;
        require(amount0Out > 0 || amount1Out > 0, 'Excavo: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'Excavo: INSUFFICIENT_LIQUIDITY');

        { // scope for _token{0,1}, avoids stack too deep errors
        details._token0 = data.token0;
        details._token1 = data.token1;
        require(to != details._token0 && to != details._token1, 'Excavo: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(details._token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(details._token1, to, amount1Out); // optimistically transfer tokens
        if (_data.length > 0) IExcavoCallee(to).ExcavoCall(msg.sender, amount0Out, amount1Out, _data);
        details.balance0 = IERC20(details._token0).balanceOf(address(this));
        details.balance1 = IERC20(details._token1).balanceOf(address(this));
        }
        uint amount0In = details.balance0 > _reserve0 - amount0Out ? details.balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = details.balance1 > _reserve1 - amount1Out ? details.balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'Excavo: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        details.balance0Adjusted = details.balance0.mul(10000).sub(amount0In.mul(4 * discount));
        details.balance1Adjusted = details.balance1.mul(10000).sub(amount1In.mul(4 * discount));
        require(details.balance0Adjusted.mul(details.balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(10000**2), 'Excavo: K');
        }
        
        if (data.CAVO != address(0)) {
            uint prevPriceCumulativeLast = data.token0 == data.CAVO ? data.price0CumulativeLast : data.price1CumulativeLast;
            uint prevBlockTimestampLast = data.blockTimestampLast;
            _update(details.balance0, details.balance1, _reserve0, _reserve1);
            // call mint first call per block 
            if (data.blockTimestampLast != prevBlockTimestampLast) {
                uint priceCumulativeLast = data.token0 == data.CAVO ? data.price0CumulativeLast : data.price1CumulativeLast;
                IxCAVO(data.xCAVO).mint((priceCumulativeLast - prevPriceCumulativeLast) / (data.blockTimestampLast - prevBlockTimestampLast));
            }
        } else {
            _update(details.balance0, details.balance1, _reserve0, _reserve1);
        }
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external override lock {
        address _token0 = data.token0; // gas savings
        address _token1 = data.token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(data.reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(data.reserve1));
    }

    // force reserves to match balances
    function sync() external override lock {
        _update(IERC20(data.token0).balanceOf(address(this)), IERC20(data.token1).balanceOf(address(this)), data.reserve0, data.reserve1);
    }

    function factory() external view override returns (address) {
        return data.factory;
    }

    function token0() external view override returns (address) {
        return data.token0;
    }

    function token1() external view override returns (address) {
        return data.token1;
    }

    function router() external view override returns (address) {
        return data.router;
    }

    function accumulatedUnclaimedLiquidity() external view override returns (uint) {
        return data.accumulatedUnclaimedLiquidity;
    }

    function price0CumulativeLast() external view override returns (uint) {
        return data.price0CumulativeLast;
    }

    function price1CumulativeLast() external view override returns (uint) {
        return data.price1CumulativeLast;
    }

    function claimLiquidity(address account, uint256 amount) external override lock returns (uint) {
        return data.claimLiquidity(account, amount);
    }

    function claimAllLiquidity(address account) external override lock returns (uint) {
        return data.claimAllLiquidity(account);
    }

    function accumulatedLiquidityGrowth() external view override returns (uint) {
        return data.accumulatedLiquidityGrowth();
    }

    function unclaimedLiquidityOf(address account) external view override returns (uint) {
        return data.unclaimedLiquidityOf(account);
    }

    function compoundLiquidity() external override lock {
        emit Compound(msg.sender, data.compoundLiquidity());
    }

    function _mint(address to, uint value, uint k) private {
        data.mint(to, value, k);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) private {
        data.burn(from, value);
        emit Transfer(from, address(0), value);
    }

    function _transfer(address from, address to, uint value) internal virtual override {
        data.transfer(from, to, value);
        emit Transfer(from, to, value);
    }
}