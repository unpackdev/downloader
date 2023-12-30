pragma solidity =0.6.6;


interface IMostERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event LogRebase(uint indexed epoch, uint totalSupply);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function epoch() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function oracle() external view returns (address);
    function rebaseSetter() external view returns (address);
    function creator() external view returns (address);
    function initialize(address) external;
    function rebase() external returns (uint);
    function setRebaseSetter(address) external;
    function setCreator(address) external;
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

interface IMostOracle {
    function PERIOD() external pure returns (uint);

    function pair() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function mostToken() external view returns (address);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function blockTimestampLast() external view returns (uint32);
    function update() external;
    function consult(address token, uint amountIn) external view returns (uint amountOut);
    function consultNow(uint amountIn) external view returns (uint amountOut, int256 supplyDelta, uint totalSupply);
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

    function abs(int a) internal pure returns (int) {
        require(a != int256(1) << 255, 'ds-math-mul-overflow');
        return a < 0 ? -a : a;
    }
}

contract MostERC20 is IMostERC20 {
    using SafeMath for uint;
    using SafeMath for int;

    string public constant override name = 'mBTC';
    string public constant override symbol = 'mBTC';
    uint8 public constant override decimals = 9;
    uint public override totalSupply;
    uint public override epoch;
    mapping(address => uint) private gonBalanceOf;
    mapping(address => mapping(address => uint)) public override allowance;

    uint private constant MAX_UINT256 = ~uint256(0);
    uint private constant INITIAL_FRAGMENTS_SUPPLY = 42 * 10**4 * 10**uint(decimals); // 420K mBTC
    uint8 private constant RATE_BASE = 100;
    uint8 private constant UPPER_BOUND = 106;
    uint8 private constant LOWER_BOUND = 96;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint private constant MAX_SUPPLY = 1 * 10**9 * 10**uint(decimals);  // 1 billion mBTC

    uint private gonsPerFragment;

    address public override oracle;
    address public override rebaseSetter;
    address public override creator;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event LogRebase(uint indexed epoch, uint totalSupply);

    constructor() public {
        creator = msg.sender;

        totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        gonBalanceOf[msg.sender] = TOTAL_GONS;
        gonsPerFragment = TOTAL_GONS / totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function initialize(address _oracle) external override {
        require(msg.sender == creator, 'MOST: FORBIDDEN'); // sufficient check

        oracle = _oracle;
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        uint gonValue = value.mul(gonsPerFragment);
        gonBalanceOf[from] = gonBalanceOf[from].sub(gonValue);
        gonBalanceOf[to] = gonBalanceOf[to].add(gonValue);
        emit Transfer(from, to, value);
    }

    function balanceOf(address owner) external view override returns (uint) {
        return gonBalanceOf[owner] / gonsPerFragment;
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function rebase() external override returns (uint) {
        require(msg.sender == rebaseSetter, 'MOST: FORBIDDEN'); // sufficient check

        IMostOracle mostOracle = IMostOracle(oracle);
        mostOracle.update();

        epoch = epoch.add(1);

        uint priceAverage = mostOracle.consult(address(this), 10**uint(decimals));

        uint tokenBRemaining;
        if (address(this) == mostOracle.token0()) {
            tokenBRemaining = 10 ** uint(IERC20(mostOracle.token1()).decimals() - 5);
        } else {
            tokenBRemaining = 10 ** uint(IERC20(mostOracle.token0()).decimals() - 5);
        }
        uint unitBase = RATE_BASE * tokenBRemaining;
        int256 supplyDelta;
        if (priceAverage > UPPER_BOUND * tokenBRemaining) {
            supplyDelta = 0 - int(totalSupply.mul(priceAverage.sub(unitBase)) / priceAverage);
        } else if (priceAverage < LOWER_BOUND * tokenBRemaining) {
            supplyDelta = int(totalSupply.mul(unitBase.sub(priceAverage)) / unitBase);
        } else {
            supplyDelta = 0;
        }

        supplyDelta = supplyDelta / 10;

        if (supplyDelta == 0) {
            emit LogRebase(epoch, totalSupply);
            return totalSupply;
        }

        if (supplyDelta < 0) {
            totalSupply = totalSupply.sub(uint256(supplyDelta.abs()));
        } else {
            totalSupply = totalSupply.add(uint256(supplyDelta));
        }

        if (totalSupply > MAX_SUPPLY) {
            totalSupply = MAX_SUPPLY;
        }

        gonsPerFragment = TOTAL_GONS / totalSupply;

        // From this point forward, gonsPerFragment is taken as the source of truth.
        // We recalculate a new totalSupply to be in agreement with the gonsPerFragment
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (totalSupply^2)/(TOTAL_GONS - totalSupply).
        //
        // In the case of totalSupply <= MAX_UINT128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.
        // totalSupply = TOTAL_GONS / gonsPerFragment

        emit LogRebase(epoch, totalSupply);
        return totalSupply;
    }

    function setRebaseSetter(address _rebaseSetter) external override {
        require(msg.sender == creator, 'MOST: FORBIDDEN');
        rebaseSetter = _rebaseSetter;
    }

    function setCreator(address _creator) external override {
        require(msg.sender == creator, 'MOST: FORBIDDEN');
        creator = _creator;
    }
}