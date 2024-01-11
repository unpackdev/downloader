pragma solidity ^0.7.0;



import "./UniswapV2Pair.sol";
import "./IERC20.sol";

/// @author ZKSwap L2 Labs
/// @author Stars Labs
contract UniswapV2Factory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    address public zkSyncAddress;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor() {}

    function initialize(bytes calldata data) external {}

    function setZkSyncAddress(address _zksyncAddress) external {
        require(zkSyncAddress == address(0), "szsa1");
        zkSyncAddress = _zksyncAddress;
    }

    /// @notice PairManager contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external {}

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB, bytes32 _salt) external view returns (address pair) {
        require(msg.sender == zkSyncAddress, 'fcp2');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, _salt));

        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                keccak256(bytecode)
            ))));
    }

    function createPair(address tokenA, address tokenB, bytes32 _salt) external returns (address pair) {
        require(msg.sender == zkSyncAddress, 'fcp1');
        require(tokenA != tokenB ||
                keccak256(abi.encodePacked(IERC20(tokenA).symbol())) == keccak256(abi.encodePacked("EGS")),
                'UniswapV2: IDENTICAL_ADDRESSES');

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, _salt));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        require(zkSyncAddress != address(0), 'wzk');
        UniswapV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function mint(address pair, address to, uint256 amount) external {
        require(msg.sender == zkSyncAddress, 'fmt1');
        UniswapV2Pair(pair).mint(to, amount);
    }

    function burn(address pair, address to, uint256 amount) external {
        require(msg.sender == zkSyncAddress, 'fbr1');
        UniswapV2Pair(pair).burn(to, amount);
    }
}
