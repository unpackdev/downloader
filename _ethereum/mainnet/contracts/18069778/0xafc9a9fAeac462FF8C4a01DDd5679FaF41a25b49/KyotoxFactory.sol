pragma solidity >=0.5.16;

import "./IKyotoxFactory.sol";
import "./KyotoxPair.sol";

contract KyotoxFactory {
    address private owner;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    uint32 public defaultFee = 50; // 0.5%

    mapping(address => bool) public canCreatePair;
    bool public freePairCreation = false;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    event OwnerChanged(address indexed oldowner, address indexed newOwner);

    event FreePairCreationUpdated(bool value);
    event CanCreatePairUpdated(address indexed account, bool value);

    event DefaultFeeUpdated(uint32 value);

    constructor(address _owner) public {
        require(_owner != address(0), 'Owner should be non-zero');
        owner = _owner;
    }

    modifier onlyOwner() {
        require(tx.origin == owner, 'Kyotox: NOT_ALLOWED');
        _;
    }

    modifier canCreate() {
        require(freePairCreation || canCreatePair[tx.origin], 'Kyotox: CREATE_NOT_ALLOWED');
        _;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external canCreate returns (address pair) {
        require(tokenA != tokenB, 'Kyotox: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Kyotox: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'Kyotox: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(KyotoxPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IKyotoxPair(pair).initialize(token0, token1, defaultFee, owner); // fee sent to owner
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function getInitHash() public pure returns (bytes32) {
        bytes memory bytecode = type(KyotoxPair).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), 'Owner should be non-zero');
        owner = newOwner;
        emit OwnerChanged(tx.origin, newOwner);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    /**
     * @notice Allows the contract owner to enable or disable free pair creation
     * @dev Only callable by the contract owner
     * @param value The new state of the free pair creation
     */
    function setFreePairCreation(bool value) external onlyOwner {
        require(freePairCreation != value, 'Kyotox: FREE_CREATION_ALREADY_SET');
        freePairCreation = value;
        emit FreePairCreationUpdated(value);
    }

    /**
     * @notice Allows the contract owner to enable or disable pair creation for an account
     * @dev Only callable by the contract owner
     * @param account The account for which to enable or disable pair creation
     * @param value The new state of the pair creation
     */
    function setCanCreatePair(address account, bool value) external onlyOwner {
        require(canCreatePair[account] != value, 'Kyotox: CREATE_PAIR_ALREADY_SET');
        canCreatePair[account] = value;
        emit CanCreatePairUpdated(account, value);
    }

    /**
     * @notice Allows the contract owner to set the default fee for new pairs
     * @dev Only callable by the contract owner
     * @param value The new default fee
     */
    function setDefaultFee(uint32 value) external onlyOwner {
        require(value <= 5_00, 'Kyotox: FEE_TOO_HIGH');
        defaultFee = value;
        emit DefaultFeeUpdated(value);
    }
}
