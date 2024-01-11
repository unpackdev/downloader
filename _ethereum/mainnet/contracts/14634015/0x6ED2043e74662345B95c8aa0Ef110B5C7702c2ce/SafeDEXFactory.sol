pragma solidity =0.5.16;

import "./ISafeDEXFactory.sol";
import "./SafeDEXPair.sol";
import "./Ownable.sol";

contract SafeDEXFactory is ISafeDEXFactory, Ownable {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(SafeDEXPair).creationCode));

    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public getPair;
    mapping(address => bool) internal whitelisted;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event Whitelisted(address[] addresses, bool whitelisted);

    constructor(address _feeToSetter, address[] memory _initialWhitelists) public {
        feeToSetter = _feeToSetter;

        for(uint i = 0; i < _initialWhitelists.length; i++) {
            whitelisted[_initialWhitelists[i]] = true;
        }
        whitelisted[msg.sender] = true;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'SafeDEX: IDENTICAL_ADDRESSES');
        require(whitelisted[msg.sender], "SafeDEX: NOT_WHITELISTED");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SafeDEX: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'SafeDEX: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(SafeDEXPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        ISafeDEXPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'SafeDEX: FORBIDDEN');
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'SafeDEX: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setWhitelist(address[] calldata _addresses) external onlyOwner {
        for(uint i = 0; i < _addresses.length; i++) {
            whitelisted[_addresses[i]] = true;
        }

        emit Whitelisted(_addresses, true);
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return whitelisted[_address];
    }

    function removeWhitelist(address[] calldata _addresses) external onlyOwner {
        for(uint i = 0; i < _addresses.length; i++) {
            if(_addresses[i] != msg.sender) whitelisted[_addresses[i]] = false;
        }

        emit Whitelisted(_addresses, false);
    }
}
