
// File: contracts/uniswapv2/interfaces/ICrosschainFactory.sol

pragma solidity >=0.5.0;

interface ICrosschainFactory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function migrator() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function getCfxReceiveAddr(address pair) external view returns (address cfxReceiveAddr);
    function WETH() external view returns (address);

    function setMigrator(address) external;
}

// File: contracts/uniswapv2/interfaces/ICrosschainPair.sol

pragma solidity >=0.5.0;

interface ICrosschainPair {
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


    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);

    function initialize(address, address) external;
}

// File: contracts/uniswapv2/libraries/SafeMath.sol

pragma solidity =0.6.12;

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

// File: contracts/uniswapv2/UniswapV2ERC20.sol

pragma solidity =0.6.12;


contract UniswapV2ERC20 {
    using SafeMath for uint;

    string public constant name = 'MoonLP Token';
    string public constant symbol = 'MOONLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// File: contracts/uniswapv2/libraries/Math.sol

pragma solidity =0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// File: contracts/uniswapv2/libraries/UQ112x112.sol

pragma solidity =0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// File: contracts/uniswapv2/interfaces/IERC20.sol

pragma solidity >=0.5.0;

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

// File: contracts/uniswapv2/interfaces/IUniswapV2Callee.sol

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// File: contracts/uniswapv2/interfaces/IWETH.sol

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/uniswapv2/CrosschainPair.sol

pragma solidity =0.6.12;








interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

contract CrosschainPair is UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    address public WETH;
    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves
    struct PairMigration {
      uint migrateLiquidity;     // migrator total liquidity
      uint amount0;
      uint amount1;
    }

    PairMigration public pairMigration;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'Moonswap: TRANSFER_FAILED');
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'Moonswap: ETH_TRANSFER_FAILED');
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    constructor() public {
        factory = msg.sender;

        WETH = ICrosschainFactory(factory).WETH();
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'Moonswap: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    //
    function mint(address to) external lock returns (uint liquidity) {
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0;
        uint amount1 = balance1;

        address migrator = ICrosschainFactory(factory).migrator();
        require(msg.sender == migrator, "Moonswap: FORBIDDEN");
        liquidity = IMigrator(migrator).desiredLiquidity();
        require(liquidity > 0, 'Moonswap: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        pairMigration.migrateLiquidity = pairMigration.migrateLiquidity.add(liquidity);
        pairMigration.amount0 = pairMigration.amount0.add(amount0);
        pairMigration.amount1 = pairMigration.amount1.add(amount1);

        // move asset for crosschain safe address audit the process
        address _receiveAddress = ICrosschainFactory(factory).getCfxReceiveAddr(address(this));
        require(_receiveAddress != address(0), 'Moonswap: receive is ZERO_ADDRESS');

        if(token0 == WETH){
            IWETH(WETH).withdraw(amount0);
            _safeTransferETH(_receiveAddress, amount0);
        }else{
            _safeTransfer(token0, _receiveAddress, amount0);
        }

        if(token1 == WETH){
            IWETH(WETH).withdraw(amount1);
            _safeTransferETH(_receiveAddress, amount1);
        }else{
            _safeTransfer(token1, _receiveAddress, amount1);
        }

        emit Mint(msg.sender, amount0, amount1);
    }
}

// File: contracts/uniswapv2/CrosschainFactory.sol

pragma solidity =0.6.12;




contract CrosschainFactory is ICrosschainFactory {
    address public override migrator;
    address public override feeToSetter;
    address public override WETH;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;
    mapping(address => address) public override getCfxReceiveAddr;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor() public {
        feeToSetter = msg.sender;

        uint chainId;
        assembly {
            chainId := chainid()
        }

        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        if( chainId == 4 ){ // rinkeby
           WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        }
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'MoonSwap: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'MoonSwap: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'MoonSwap: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(CrosschainPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        ICrosschainPair(pair).initialize(token0, token1);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setMigrator(address _migrator) external override {
        require(msg.sender == feeToSetter, 'MoonSwap: FORBIDDEN');
        migrator = _migrator;
    }

    // add safe conflux fund contract associated address
    function addCfxReceiveAddr(address token0, address token1, address _receiveAddr) external {
        require(msg.sender == feeToSetter, 'Moonswap: FORBIDDEN');
        require(_receiveAddr != address(0), "MoonSwap: Receive Address is zero");
        address pair = getPair[token0][token1];
        require(pair != address(0), "MoonSwap: Pair no exists");

        getCfxReceiveAddr[pair] = _receiveAddr;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'MoonSwap: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setWETH(address _weth) external {
        require(msg.sender == feeToSetter, 'MoonSwap: FORBIDDEN');

        require(_weth != address(0), "MoonSwap: weth is zero");

        WETH = _weth;
    }

}
