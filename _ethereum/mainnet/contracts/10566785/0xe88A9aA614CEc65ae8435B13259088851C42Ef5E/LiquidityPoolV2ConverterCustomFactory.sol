
// File: solidity/contracts/converter/interfaces/ITypedConverterCustomFactory.sol

pragma solidity 0.4.26;

/*
    Typed Converter Custom Factory interface
*/
contract ITypedConverterCustomFactory {
    function converterType() public pure returns (uint16);
}

// File: solidity/contracts/utility/Utils.sol

pragma solidity 0.4.26;

/**
  * @dev Utilities & Common Modifiers
*/
contract Utils {
    // verifies that a value is greater than zero
    modifier greaterThanZero(uint256 _value) {
        _greaterThanZero(_value);
        _;
    }

    // error message binary size optimization
    function _greaterThanZero(uint256 _value) internal pure {
        require(_value > 0, "ERR_ZERO_VALUE");
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        _validAddress(_address);
        _;
    }

    // error message binary size optimization
    function _validAddress(address _address) internal pure {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        _notThis(_address);
        _;
    }

    // error message binary size optimization
    function _notThis(address _address) internal view {
        require(_address != address(this), "ERR_ADDRESS_IS_SELF");
    }
}

// File: solidity/contracts/utility/SafeMath.sol

pragma solidity 0.4.26;

/**
  * @dev Library for basic math operations with overflow/underflow protection
*/
library SafeMath {
    /**
      * @dev returns the sum of _x and _y, reverts if the calculation overflows
      *
      * @param _x   value 1
      * @param _y   value 2
      *
      * @return sum
    */
    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev returns the difference of _x minus _y, reverts if the calculation underflows
      *
      * @param _x   minuend
      * @param _y   subtrahend
      *
      * @return difference
    */
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y, "ERR_UNDERFLOW");
        return _x - _y;
    }

    /**
      * @dev returns the product of multiplying _x by _y, reverts if the calculation overflows
      *
      * @param _x   factor 1
      * @param _y   factor 2
      *
      * @return product
    */
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        // gas optimization
        if (_x == 0)
            return 0;

        uint256 z = _x * _y;
        require(z / _x == _y, "ERR_OVERFLOW");
        return z;
    }

    /**
      * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
      *
      * @param _x   dividend
      * @param _y   divisor
      *
      * @return quotient
    */
    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_y > 0, "ERR_DIVIDE_BY_ZERO");
        uint256 c = _x / _y;
        return c;
    }
}

// File: solidity/contracts/utility/interfaces/IChainlinkPriceOracle.sol

pragma solidity 0.4.26;

/*
    Chainlink Price Oracle interface
*/
interface IChainlinkPriceOracle {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
}

// File: solidity/contracts/token/interfaces/IERC20Token.sol

pragma solidity 0.4.26;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {this;}
    function symbol() public view returns (string) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: solidity/contracts/utility/interfaces/IPriceOracle.sol

pragma solidity 0.4.26;



/*
    Price Oracle interface
*/
contract IPriceOracle {
    function latestRate(IERC20Token _tokenA, IERC20Token _tokenB) public view returns (uint256, uint256);
    function lastUpdateTime() public view returns (uint256);
    function latestRateAndUpdateTime(IERC20Token _tokenA, IERC20Token _tokenB) public view returns (uint256, uint256, uint256);

    function tokenAOracle() public view returns (IChainlinkPriceOracle) {this;}
    function tokenBOracle() public view returns (IChainlinkPriceOracle) {this;}
}

// File: solidity/contracts/utility/PriceOracle.sol

pragma solidity 0.4.26;

/**
  * @dev Provides the off-chain rate between two tokens
  *
  * The price oracle uses chainlink oracles internally to get the rates of the two tokens
  * with respect to a common denominator, and then returns the rate between them, which
  * is equivalent to the rate of TokenA / TokenB
*/
contract PriceOracle is IPriceOracle, Utils {
    using SafeMath for uint256;

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint8 private constant ETH_DECIMALS = 18;

    IERC20Token public tokenA;                  // token A the oracle supports
    IERC20Token public tokenB;                  // token B the oracle supports
    mapping (address => uint8) public tokenDecimals; // token -> token decimals

    IChainlinkPriceOracle public tokenAOracle;  // token A chainlink price oracle
    IChainlinkPriceOracle public tokenBOracle;  // token B chainlink price oracle
    mapping (address => IChainlinkPriceOracle) public tokensToOracles;  // token -> price oracle for easier access

    /**
      * @dev initializes a new PriceOracle instance
      * note that the oracles must have the same common denominator (USD, ETH etc.)
      *
      * @param  _tokenA         first token to support
      * @param  _tokenB         second token to support
      * @param  _tokenAOracle   first token price oracle
      * @param  _tokenBOracle   second token price oracle
    */
    constructor(IERC20Token _tokenA, IERC20Token _tokenB, IChainlinkPriceOracle _tokenAOracle, IChainlinkPriceOracle _tokenBOracle)
        public
        validUniqueAddresses(_tokenA, _tokenB)
        validUniqueAddresses(_tokenAOracle, _tokenBOracle)
    {
        tokenA = _tokenA;
        tokenB = _tokenB;
        tokenDecimals[_tokenA] = decimals(_tokenA);
        tokenDecimals[_tokenB] = decimals(_tokenB);

        tokenAOracle = _tokenAOracle;
        tokenBOracle = _tokenBOracle;
        tokensToOracles[_tokenA] = _tokenAOracle;
        tokensToOracles[_tokenB] = _tokenBOracle;
    }

    // ensures that the provided addresses are unique valid
    modifier validUniqueAddresses(address _address1, address _address2) {
        _validUniqueAddresses(_address1, _address2);
        _;
    }

    // error message binary size optimization
    function _validUniqueAddresses(address _address1, address _address2) internal pure {
        _validAddress(_address1);
        _validAddress(_address2);
        require(_address1 != _address2, "ERR_SAME_ADDRESS");
    }

    // ensures that the provides tokens are supported by the oracle
    modifier supportedTokens(IERC20Token _tokenA, IERC20Token _tokenB) {
        _supportedTokens(_tokenA, _tokenB);
        _;
    }

    // error message binary size optimization
    function _supportedTokens(IERC20Token _tokenA, IERC20Token _tokenB) internal view {
        _validUniqueAddresses(_tokenA, _tokenB);
        require(tokensToOracles[_tokenA] != address(0) && tokensToOracles[_tokenB] != address(0), "ERR_UNSUPPORTED_TOKEN");
    }

    /**
      * @dev returns the latest known rate between the two given tokens
      * for a given pair of tokens A and B, returns the rate of A / B
      * (the number of B units equivalent to a single A unit)
      * the rate is returned as a fraction (numerator / denominator) for accuracy
      *
      * @param  _tokenA token to get the rate of 1 unit of
      * @param  _tokenB token to get the rate of 1 `_tokenA` against
      *
      * @return numerator
      * @return denominator
    */
    function latestRate(IERC20Token _tokenA, IERC20Token _tokenB)
        public
        view
        supportedTokens(_tokenA, _tokenB)
        returns (uint256, uint256)
    {
        uint256 rateTokenA = uint256(tokensToOracles[_tokenA].latestAnswer());
        uint256 rateTokenB = uint256(tokensToOracles[_tokenB].latestAnswer());
        uint8 decimalsTokenA = tokenDecimals[_tokenA];
        uint8 decimalsTokenB = tokenDecimals[_tokenB];

        // the normalization works as follows:
        //   - token A with decimals of dA and price of rateA per one token (e.g., for 10^dA weiA)
        //   - token B with decimals of dB < dA and price of rateB per one token (e.g., for 10^dB weiB)
        // then the normalized rate, representing the rate between 1 weiA and 1 weiB is rateA / (rateB * 10^(dA - dB)).
        //
        // for example:
        //   - token A with decimals of 5 and price of $10 per one token (e.g., for 100,000 weiA)
        //   - token B with decimals of 2 and price of $2 per one token (e.g., for 100 weiB)
        // then the normalized rate would be: 5 / (2 * 10^3) = 0.0025, which is the correct rate since
        // 1 weiA costs $0.00005, 1 weiB costs $0.02, and weiA / weiB is 0.0025.

        if (decimalsTokenA > decimalsTokenB) {
            rateTokenB = rateTokenB.mul(uint256(10) ** (decimalsTokenA - decimalsTokenB));
        }
        else if (decimalsTokenA < decimalsTokenB) {
            rateTokenA = rateTokenA.mul(uint256(10) ** (decimalsTokenB - decimalsTokenA));
        }

        return (rateTokenA, rateTokenB);
    }

    /**
      * @dev returns the timestamp of the last price update the rates are returned as numerator (token1) and denominator
      * (token2) for accuracy
      *
      * @return timestamp
    */
    function lastUpdateTime()
        public
        view
        returns (uint256) {
        // returns the oldest timestamp between the two
        uint256 timestampA = tokenAOracle.latestTimestamp();
        uint256 timestampB = tokenBOracle.latestTimestamp();

        return  timestampA < timestampB ? timestampA : timestampB;
    }

    /**
      * @dev returns both the rate and the timestamp of the last update in a single call (gas optimization)
      *
      * @param  _tokenA token to get the rate of 1 unit of
      * @param  _tokenB token to get the rate of 1 `_tokenA` against
      *
      * @return numerator
      * @return denominator
      * @return timestamp of the last update
    */
    function latestRateAndUpdateTime(IERC20Token _tokenA, IERC20Token _tokenB)
        public
        view
        returns (uint256, uint256, uint256)
    {
        (uint256 numerator, uint256 denominator) = latestRate(_tokenA, _tokenB);

        return (numerator, denominator, lastUpdateTime());
    }

    /** @dev returns the decimals of a given token */
    function decimals(IERC20Token _token) private view returns (uint8) {
        if (_token == ETH_ADDRESS) {
            return ETH_DECIMALS;
        }

        return _token.decimals();
    }
}

// File: solidity/contracts/converter/types/liquidity-pool-v2/LiquidityPoolV2ConverterCustomFactory.sol

pragma solidity 0.4.26;

/*
    LiquidityPoolV2ConverterCustomFactory Factory
*/
contract LiquidityPoolV2ConverterCustomFactory is ITypedConverterCustomFactory {
    /**
      * @dev returns the converter type the factory is associated with
      *
      * @return converter type
    */
    function converterType() public pure returns (uint16) {
        return 2;
    }

    /**
      * @dev creates a new price oracle
      * note that the oracles must have the same common denominator (USD, ETH etc.)
      *
      * @param  _primaryReserveToken    primary reserve token address
      * @param  _secondaryReserveToken  secondary reserve token address
      * @param  _primaryReserveOracle   primary reserve oracle address
      * @param  _secondaryReserveOracle secondary reserve oracle address
    */
    function createPriceOracle(
        IERC20Token _primaryReserveToken,
        IERC20Token _secondaryReserveToken,
        IChainlinkPriceOracle _primaryReserveOracle,
        IChainlinkPriceOracle _secondaryReserveOracle)
        public
        returns (IPriceOracle)
    {
        return new PriceOracle(_primaryReserveToken, _secondaryReserveToken, _primaryReserveOracle, _secondaryReserveOracle);
    }
}
