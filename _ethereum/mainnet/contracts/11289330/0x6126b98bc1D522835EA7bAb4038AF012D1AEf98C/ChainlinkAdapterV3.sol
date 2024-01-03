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

// File: contracts/interfaces/AggregatorV3Interface.sol

pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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

// File: contracts/ChainlinkAdapterV3.sol

pragma solidity ^0.6.6;







contract ChainlinkAdapterV3 is Ownable, IOracleAdapter {
    using SafeMath for uint256;
    using StringUtils for string;

    mapping(bytes32 => mapping(bytes32 => address)) public aggregators;

    event SetAggregator(bytes32 _symbolA, bytes32 _symbolB, address _aggregator);
    event RemoveAggregator(bytes32 _symbolA, bytes32 _symbolB, address _aggregator);

    function symbolToBytes32(string calldata _symbol) external pure returns (bytes32) {
        return _symbol.toBytes32();
    }

    function setAggregator(
        bytes32 _symbolA,
        bytes32 _symbolB,
        address _aggregator
    ) external override onlyOwner {
        require(_aggregator != address(0), "ChainLinkAdapter/Aggregator 0x0 is not valid");
        require(aggregators[_symbolA][_symbolB] == address(0), "ChainLinkAdapter/Aggregator is already set");

        aggregators[_symbolA][_symbolB] = _aggregator;
        emit SetAggregator(
            _symbolA,
            _symbolB,
            _aggregator
        );
    }

    function removeAggregator(
        bytes32 _symbolA,
        bytes32 _symbolB
    ) external override onlyOwner {
        address remAggregator = aggregators[_symbolA][_symbolB];
        require(remAggregator != address(0), "ChainLinkAdapter/Aggregator not set");

        aggregators[_symbolA][_symbolB] = address(0);
        emit RemoveAggregator(
            _symbolA,
            _symbolB,
            remAggregator
        );
    }

    function latestTimestamp(bytes32[] calldata path) external override view returns (uint256 lastTimestamp)  {
        uint256 prevTimestamp;
        for (uint i; i < path.length - 1; i++) {
            (bytes32 input, bytes32 output) = (path[i], path[i + 1]);
            (uint256 timestamp0) = getLatestTimestamp(input, output);
            lastTimestamp = timestamp0 < prevTimestamp || prevTimestamp == 0  ? timestamp0 : prevTimestamp;
            prevTimestamp = lastTimestamp;
        }
    }

    function getLatestTimestamp(bytes32 _symbolA, bytes32 _symbolB) public view returns (uint256 lastTimestamp)  {
        address aggregator = aggregators[_symbolA][_symbolB];

        if (aggregator == address(0)) {
            aggregator = aggregators[_symbolB][_symbolA];
            require(aggregator != address(0), "ChainLinkAdapter/Aggregator not set, path not resolved");
        }
        (,,,lastTimestamp,) = AggregatorV3Interface(aggregator).latestRoundData();
    }

    function getRate(bytes32[] calldata path) external override view returns (uint256 combinedRate, uint256 decimals)  {
        uint256 prevRate;
        uint256 prevDec;
        for (uint i; i < path.length - 1; i++) {
            (bytes32 input, bytes32 output) = (path[i], path[i + 1]);
            (combinedRate, decimals) = _getPairRate(input, output);
            combinedRate = prevRate > 0 ? _getCombined(prevRate, combinedRate, prevDec) : combinedRate;
            prevRate = combinedRate;
            prevDec = decimals;
        }
    }

    function getPairLastRate(bytes32 _symbolA, bytes32 _symbolB) public view returns (uint256 answer, uint256 decimals)  {
        AggregatorV3Interface aggregator = AggregatorV3Interface(aggregators[_symbolA][_symbolB]);
        (,int256 rate,,,) = aggregator.latestRoundData();
        require(rate > 0, "ChainLinkAdapter/Rate lower or equal to 0");
        answer = uint256(rate);
        decimals = uint256(aggregator.decimals());
    }

    function _getPairRate(bytes32 _input, bytes32 _output) private view returns (uint256 rate, uint256 decimals) {
        address aggregator = aggregators[_input][_output];

        if (aggregator == address(0)) {
            aggregator = aggregators[_output][_input];
            require(aggregator != address(0), "ChainLinkAdapter/Aggregator not set, path not resolved");
            (rate, decimals) = getPairLastRate(_output, _input);
            rate = (10**(uint256(decimals)*2)).div(rate);
        } else {
            (rate, decimals) = getPairLastRate(_input, _output);     
        }
    }

    function _getCombined(uint256 rate0, uint256 rate1, uint256 _decimal) private pure returns (uint256 combinedRate) {
        combinedRate = rate0.mult(rate1).div(10 ** _decimal);
    }
}