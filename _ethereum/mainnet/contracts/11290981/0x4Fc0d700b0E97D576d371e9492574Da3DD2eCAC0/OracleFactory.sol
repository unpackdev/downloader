// File: contracts/commons/Ownable.sol

pragma solidity ^0.6.6;


contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/utils/StringUtils.sol

pragma solidity ^0.6.6;


library StringUtils {
    function toBytes32(string memory _a) internal pure returns (bytes32 b) {
        require(bytes(_a).length <= 32, "string too long");

        assembly {
            let bi := mul(mload(_a), 8)
            b := and(mload(add(_a, 32)), shl(sub(256, bi), sub(exp(2, bi), 1)))
        }
    }
}

// File: contracts/diaspore/RateOracle.sol

pragma solidity ^0.6.6;


/**
    @dev Defines the interface of a standard Diaspore RCN Oracle,
    The contract should also implement it's ERC165 interface: 0xa265d8e0
    @notice Each oracle can only support one currency
    @author Agustin Aguilar
*/
abstract contract RateOracle {
    uint256 public constant VERSION = 5;
    bytes4 internal constant RATE_ORACLE_INTERFACE = 0xa265d8e0;
    
    /**
        3 or 4 letters symbol of the currency, Ej: ETH
    */
    function baseToken() external virtual view returns (string memory);


    /**
        3 or 4 letters symbol of the currency, Ej: ETH
    */
    function symbol() external virtual view returns (string memory);

    /**
        Descriptive name of the currency, Ej: Ethereum
    */
    function name() external virtual view returns (string memory);

    /**
        The number of decimals of the currency represented by this Oracle,
            it should be the most common number of decimal places
    */
    function decimals() external virtual view returns (uint256);

    /**
        The base token on which the sample is returned
            should be the RCN Token address.
    */
    function token() external virtual view returns (address);

    /**
        The currency symbol encoded on a UTF-8 Hex
    */
    function currency() external virtual view returns (bytes32);

    /**
        The name of the Individual or Company in charge of this Oracle
    */
    function maintainer() external virtual view returns (string memory);

    /**
        Returns the url where the oracle exposes a valid "oracleData" if needed
    */
    function url() external virtual view returns (string memory);

    /**
        Returns a sample on how many token() are equals to how many currency()
    */
    function readSample(bytes calldata _data) external virtual view returns (uint256 _tokens, uint256 _equivalent);
}

// File: contracts/interfaces/IOracleAdapter.sol

pragma solidity ^0.6.6;


interface IOracleAdapter {

  function setAggregator(
    bytes32 _symbolA,
    bytes32 _symbolB,
    address _aggregator
  ) external;

  function removeAggregator(bytes32 _symbolA, bytes32 _symbolB) external;
  function getRate (bytes32[] calldata path) external view returns (uint256, uint256);
  function latestTimestamp (bytes32[] calldata path) external view returns (uint256);

  event RemoveAggregator(bytes32 _symbolA, bytes32 _symbolB, address _aggregator);
  event SetAggregator(bytes32 _symbolA, bytes32 _symbolB, address _aggregator);
}

// File: contracts/utils/SafeMath.sol

pragma solidity ^0.6.6;


library SafeMath {
    using SafeMath for uint256;

    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub overflow");
        return x - y;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z/x == y, "Mult overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        return x / y;
    }

    function multdiv(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        require(z != 0, "div by zero");
        return x.mult(y) / z;
    }
}

// File: contracts/interfaces/PausedProvided.sol

pragma solidity ^0.6.6;


interface PausedProvided {
    function isPaused() external view returns (bool);
}

// File: contracts/commons/Pausable.sol

pragma solidity ^0.6.6;



contract Pausable is Ownable {
    mapping(address => bool) public canPause;
    bool public paused;

    event Paused();
    event Started();
    event CanPause(address _pauser, bool _enabled);

    function setPauser(address _pauser, bool _enabled) external onlyOwner {
        canPause[_pauser] = _enabled;
        emit CanPause(_pauser, _enabled);
    }

    function pause() external {
        require(!paused, "already paused");

        require(
            msg.sender == _owner ||
            canPause[msg.sender],
            "not authorized to pause"
        );

        paused = true;
        emit Paused();
    }

    function start() external onlyOwner {
        require(paused, "not paused");
        paused = false;
        emit Started();
    }
}

// File: contracts/diaspore/MultiSourceOracle.sol

pragma solidity ^0.6.6;









contract MultiSourceOracle is RateOracle, Ownable, Pausable {
    using StringUtils for string;
    using SafeMath for uint256;

    RateOracle public upgrade;

    uint256 public ibase;
    bytes32[] public path;
    IOracleAdapter public oracleAdapter;
    PausedProvided public pausedProvided;


    string private isymbol;
    string private iname;
    uint256 private idecimals;
    address private itoken;
    string private ibaseToken;
    bytes32 private icurrency;
    string private imaintainer;

    constructor(
        IOracleAdapter _oracleAdapter,
        string memory _baseToken,
        uint256 _base,
        string memory _symbol,
        string memory _name,
        uint256 _decimals,
        address _token,
        string memory _maintainer,
        bytes32[] memory _path
    ) public {
        oracleAdapter = _oracleAdapter;
        ibaseToken = _baseToken;
        // Create legacy bytes32 currency
        bytes32 currency = _symbol.toBytes32();
        // Save Oracle metadata
        isymbol = _symbol;
        iname = _name;
        idecimals = _decimals;
        itoken = _token;
        icurrency = currency;
        imaintainer = _maintainer;
        path = _path;
        ibase = _base;
        pausedProvided = PausedProvided(msg.sender);
    }

    /**
        3 or 4 letters symbol of the currency, Ej: ETH
    */
    function baseToken() external override virtual view returns (string memory) {
        return ibaseToken;
    }

    /**
     * @return metadata, 3 or 4 letter symbol of the currency provided by this oracle
     *   (ej: ARS)
     * @notice Defined by the RCN RateOracle interface
     */
    function symbol() external override view returns (string memory) {
        return isymbol;
    }

    /**
     * @return metadata, full name of the currency provided by this oracle
     *   (ej: Argentine Peso)
     * @notice Defined by the RCN RateOracle interface
     */
    function name() external override view returns (string memory) {
        return iname;
    }

    /**
     * @return metadata, decimals to express the common denomination
     *   of the currency provided by this oracle
     * @notice Defined by the RCN RateOracle interface
     */
    function decimals() external override view returns (uint256) {
        return idecimals;
    }

    /**
     * @return metadata, token address of the currency provided by this oracle
     * @notice Defined by the RCN RateOracle interface
     */
    function token() external override view returns (address) {
        return itoken;
    }

    /**
     * @return metadata, bytes32 code of the currency provided by this oracle
     * @notice Defined by the RCN RateOracle interface
     */
    function currency() external override view returns (bytes32) {
        return icurrency;
    }

    /**
     * @return metadata, human readable name of the entity maintainer of this oracle
     * @notice Defined by the RCN RateOracle interface
     */
    function maintainer() external override view returns (string memory) {
        return imaintainer;
    }

    /**
     * @dev Returns the URL required to retrieve the auxiliary data
     *   as specified by the RateOracle spec, no auxiliary data is required
     *   so it returns an empty string.
     * @return An empty string, because the auxiliary data is not required
     * @notice Defined by the RCN RateOracle interface
     */
    function url() external override view returns (string memory) {
        return "";
    }

    /**
     * @dev Updates the medatada of the oracle
     * @param _name Name of the oracle currency
     * @param _decimals Decimals for the common representation of the currency
     * @param _maintainer Name of the maintainer entity of the Oracle
     * @param _token, token address of the currency provided by this oracle
     * @param _path, path to get the currency rate
     */
    function setMetadata(
        string calldata _name,
        uint256 _decimals,
        string calldata _maintainer,
        address _token,
        bytes32[] calldata _path
    ) external onlyOwner {
        iname = _name;
        idecimals = _decimals;
        imaintainer = _maintainer;
        itoken = _token;
        path = _path;
    }

    /**
     * @dev Updates the Oracle contract, all subsequent calls to `readSample` will be forwareded to `_upgrade`
     * @param _upgrade Contract address of the new updated oracle
     * @notice If the `upgrade` address is set to the address `0` the Oracle is considered not upgraded
     */
    function setUpgrade(RateOracle _upgrade) external onlyOwner {
        upgrade = _upgrade;
    }

    /**
     * @dev Reads the rate provided by the Oracle
     *   this being the result of the resolved path by the oracle-adapter
     * @param _oracleData Oracle auxiliar data defined in the RCN Oracle spec
     *   not used for this oracle, but forwarded in case of upgrade.
     * @return _tokens _equivalent `_equivalent` is the median of the values provided by the signer
     *   `_tokens` are equivalent to `_equivalent` in the currency of the Oracle
     */
    function readSample(bytes memory _oracleData) public override view returns (uint256 _tokens, uint256 _equivalent) {
        // Check if paused
        require(!paused && !pausedProvided.isPaused(), "contract paused");

        // Check if Oracle contract has been upgraded
        RateOracle _upgrade = upgrade;
        if (address(_upgrade) != address(0)) {
            return _upgrade.readSample(_oracleData);
        }

        // Tokens is always base ;
        (uint256 rate, uint256 dec) = oracleAdapter.getRate(path);
        _tokens = ibase.mult(10 ** dec);
        _equivalent = rate.mult(10 ** idecimals);
    }

    /**
     * @dev Reads the rate provided by the Oracle
     *   this being the result of the resolved path by the oracle-adapter
     * @return _tokens _equivalent `_equivalent` is the median of the values provided by the signer
     *   `_tokens` are equivalent to `_equivalent` in the currency of the Oracle
     * @notice This Oracle accepts reading the sample without auxiliary data
     */
    function readSample() external view returns (uint256 _tokens, uint256 _equivalent) {
        (_tokens, _equivalent) = readSample(new bytes(0));
    }

    /**
     * @dev Reads the last timestamp when the oracle was updated
     * @return timestamp last updated
     * @notice If the sample rate is get from many oracles , the latest timestamp returns the older one
     */
    function latestTimestamp() external view returns (uint256 timestamp) {
        timestamp = oracleAdapter.latestTimestamp(path);
    }
}

// File: contracts/diaspore/OracleFactory.sol

pragma solidity ^0.6.6;





contract OracleFactory is Ownable, Pausable, PausedProvided {
    mapping(string => address) public symbolToOracle;
    mapping(address => string) public oracleToSymbol;

    event NewOracle(
        address _oracleAdapter,
        string _symbol,
        address _oracle,
        string _name,
        uint256 _decimals,
        address _token,
        string _maintainer,
        bytes32[] _path
    );

    event Upgraded(
        address indexed _oracle,
        address _new
    );

    event UpdatedMetadata(
        address indexed _oracle,
        string _name,
        uint256 _decimals,
        string _maintainer,
        address _token,
        bytes32[] _path
    );

    event OraclePaused(
        address indexed _oracle,
        address _pauser
    );

    event OracleStarted(
        address indexed _oracle
    );

    string public baseToken;
    uint256 public baseDecimals;

    constructor(
        string memory _baseToken,
        uint256 _decimals
    ) public {
        baseToken = _baseToken;
        baseDecimals = 10 ** _decimals;
    }

    /**
     * @dev Creates a new Oracle contract for a given `_symbol`
     * @param _symbol metadata symbol for the currency of the oracle to create
     * @param _name metadata name for the currency of the oracle
     * @param _decimals metadata number of decimals to express the common denomination of the currency
     * @param _token metadata token address of the currency
     *   (if the currency has no token, it should be the address 0)
     * @param _maintainer metadata maintener human readable name
     * @notice Only one oracle by symbol can be created
     */
    function newOracle(
        IOracleAdapter _oracleAdapter,
        string calldata _symbol,
        string calldata _name,
        uint256 _decimals,
        address _token,
        string calldata _maintainer,
        bytes32[] calldata _path
    ) external onlyOwner {
        // Check for duplicated oracles
        require(symbolToOracle[_symbol] == address(0), "Oracle already exists");
        // Create oracle contract
        address oracle;
        {
        oracle = _createOracle(
            _oracleAdapter,
            _symbol,
            _name,
            _decimals,
            _token,
            _maintainer,
            _path
        );
        }
        // Sanity check new oracle
        assert(bytes(oracleToSymbol[address(oracle)]).length == 0);
        // Save Oracle in registry
        symbolToOracle[_symbol] = address(oracle);
        oracleToSymbol[address(oracle)] = _symbol;
        // Emit events
        _emitNewOracle(
            address(_oracleAdapter),
            _symbol,
            address(oracle),
            _name,
            _decimals,
            _token,
            _maintainer,
            _path
        );
    }

    /**
     * @return true if the Oracle ecosystem is paused
     * @notice Used by PausedProvided and readed by the Oracles on each `readSample()`
     */
    function isPaused() external override view returns (bool) {
        return paused;
    }

    /**
     * @dev Pauses the given `_oracle`
     * @param _oracle oracle address to be paused
     * @notice Acts as a proxy of `_oracle.pause`
     */
    function pauseOracle(address _oracle) external {
        require(
            canPause[msg.sender] ||
            msg.sender == _owner,
            "not authorized to pause"
        );

        MultiSourceOracle(_oracle).pause();
        emit OraclePaused(_oracle, msg.sender);
    }

    /**
     * @dev Starts the given `_oracle`
     * @param _oracle oracle address to be started
     * @notice Acts as a proxy of `_oracle.start`
     */
    function startOracle(address _oracle) external onlyOwner {
        MultiSourceOracle(_oracle).start();
        emit OracleStarted(_oracle);
    }

    /**
     * @dev Updates the Oracle contract, all subsequent calls to `readSample` will be forwareded to `_upgrade`
     * @param _oracle oracle address to be upgraded
     * @param _upgrade contract address of the new updated oracle
     * @notice Acts as a proxy of `_oracle.setUpgrade`
     */
    function setUpgrade(address _oracle, address _upgrade) external onlyOwner {
        MultiSourceOracle(_oracle).setUpgrade(RateOracle(_upgrade));
        emit Upgraded(_oracle, _upgrade);
    }

    /**
     * @dev Updates the medatada of the oracle
     * @param _oracle oracle address to update its metadata
     * @param _name Name of the oracle currency
     * @param _decimals Decimals for the common representation of the currency
     * @param _maintainer Name of the maintainer entity of the Oracle
     * @notice Acts as a proxy of `_oracle.setMetadata`
     */
    function setMetadata(
        address _oracle,
        string calldata _name,
        uint256 _decimals,
        string calldata _maintainer,
        address _token,
        bytes32[] calldata _path
    ) external onlyOwner {
        MultiSourceOracle(_oracle).setMetadata(
            _name,
            _decimals,
            _maintainer,
            _token,
            _path
        );

        emit UpdatedMetadata(
            _oracle,
            _name,
            _decimals,
            _maintainer,
            _token,
            _path
        );
    }

    function _createOracle(
        IOracleAdapter _oracleAdapter,
        string memory _symbol,
        string memory _name,
        uint256 _decimals,
        address _token,
        string memory _maintainer,
        bytes32[] memory _path
    ) private returns(address oracle)
    {
        oracle = address(
            new MultiSourceOracle(
            _oracleAdapter,
            baseToken,
            baseDecimals,
            _symbol,
            _name,
            _decimals,
            _token,
            _maintainer,
            _path
        ));
    }

    function _emitNewOracle(
        address _oracleAdapter,
        string memory _symbol,
        address oracle,
        string memory _name,
        uint256 _decimals,
        address _token,
        string memory _maintainer,
        bytes32[] memory _path
    ) private
    {
        emit NewOracle(
            _oracleAdapter,
            _symbol,
            oracle,
            _name,
            _decimals,
            _token,
            _maintainer,
            _path
        );
    }
}