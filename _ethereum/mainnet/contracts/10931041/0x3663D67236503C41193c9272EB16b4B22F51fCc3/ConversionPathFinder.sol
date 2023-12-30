
// File: solidity/contracts/token/interfaces/IERC20Token.sol

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.6.12;

/*
    ERC20 Standard Token interface
*/
interface IERC20Token {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

// File: solidity/contracts/IConversionPathFinder.sol


pragma solidity 0.6.12;


/*
    Conversion Path Finder interface
*/
interface IConversionPathFinder {
    function findPath(IERC20Token _sourceToken, IERC20Token _targetToken) external view returns (address[] memory);
}

// File: solidity/contracts/utility/interfaces/IOwned.sol


pragma solidity 0.6.12;

/*
    Owned contract interface
*/
interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
}

// File: solidity/contracts/utility/Owned.sol


pragma solidity 0.6.12;

/**
  * @dev Provides support and utilities for contract ownership
*/
contract Owned is IOwned {
    address public override owner;
    address public newOwner;

    /**
      * @dev triggered when the owner is updated
      *
      * @param _prevOwner previous owner
      * @param _newOwner  new owner
    */
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

    /**
      * @dev initializes a new Owned instance
    */
    constructor() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        _ownerOnly();
        _;
    }

    // error message binary size optimization
    function _ownerOnly() internal view {
        require(msg.sender == owner, "ERR_ACCESS_DENIED");
    }

    /**
      * @dev allows transferring the contract ownership
      * the new owner still needs to accept the transfer
      * can only be called by the contract owner
      *
      * @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public override ownerOnly {
        require(_newOwner != owner, "ERR_SAME_OWNER");
        newOwner = _newOwner;
    }

    /**
      * @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() override public {
        require(msg.sender == newOwner, "ERR_ACCESS_DENIED");
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// File: solidity/contracts/utility/Utils.sol


pragma solidity 0.6.12;

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

// File: solidity/contracts/utility/interfaces/IContractRegistry.sol


pragma solidity 0.6.12;

/*
    Contract Registry interface
*/
interface IContractRegistry {
    function addressOf(bytes32 _contractName) external view returns (address);
}

// File: solidity/contracts/utility/ContractRegistryClient.sol


pragma solidity 0.6.12;

/**
  * @dev Base contract for ContractRegistry clients
*/
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant BANCOR_FORMULA = "BancorFormula";
    bytes32 internal constant CONVERTER_FACTORY = "ConverterFactory";
    bytes32 internal constant CONVERSION_PATH_FINDER = "ConversionPathFinder";
    bytes32 internal constant CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";
    bytes32 internal constant CHAINLINK_ORACLE_WHITELIST = "ChainlinkOracleWhitelist";

    IContractRegistry public registry;      // address of the current contract-registry
    IContractRegistry public prevRegistry;  // address of the previous contract-registry
    bool public onlyOwnerCanUpdateRegistry; // only an owner can update the contract-registry

    /**
      * @dev verifies that the caller is mapped to the given contract name
      *
      * @param _contractName    contract name
    */
    modifier only(bytes32 _contractName) {
        _only(_contractName);
        _;
    }

    // error message binary size optimization
    function _only(bytes32 _contractName) internal view {
        require(msg.sender == addressOf(_contractName), "ERR_ACCESS_DENIED");
    }

    /**
      * @dev initializes a new ContractRegistryClient instance
      *
      * @param  _registry   address of a contract-registry contract
    */
    constructor(IContractRegistry _registry) internal validAddress(address(_registry)) {
        registry = IContractRegistry(_registry);
        prevRegistry = IContractRegistry(_registry);
    }

    /**
      * @dev updates to the new contract-registry
     */
    function updateRegistry() public {
        // verify that this function is permitted
        require(msg.sender == owner || !onlyOwnerCanUpdateRegistry, "ERR_ACCESS_DENIED");

        // get the new contract-registry
        IContractRegistry newRegistry = IContractRegistry(addressOf(CONTRACT_REGISTRY));

        // verify that the new contract-registry is different and not zero
        require(newRegistry != registry && address(newRegistry) != address(0), "ERR_INVALID_REGISTRY");

        // verify that the new contract-registry is pointing to a non-zero contract-registry
        require(newRegistry.addressOf(CONTRACT_REGISTRY) != address(0), "ERR_INVALID_REGISTRY");

        // save a backup of the current contract-registry before replacing it
        prevRegistry = registry;

        // replace the current contract-registry with the new contract-registry
        registry = newRegistry;
    }

    /**
      * @dev restores the previous contract-registry
    */
    function restoreRegistry() public ownerOnly {
        // restore the previous contract-registry
        registry = prevRegistry;
    }

    /**
      * @dev restricts the permission to update the contract-registry
      *
      * @param _onlyOwnerCanUpdateRegistry  indicates whether or not permission is restricted to owner only
    */
    function restrictRegistryUpdate(bool _onlyOwnerCanUpdateRegistry) public ownerOnly {
        // change the permission to update the contract-registry
        onlyOwnerCanUpdateRegistry = _onlyOwnerCanUpdateRegistry;
    }

    /**
      * @dev returns the address associated with the given contract name
      *
      * @param _contractName    contract name
      *
      * @return contract address
    */
    function addressOf(bytes32 _contractName) internal view returns (address) {
        return registry.addressOf(_contractName);
    }
}

// File: solidity/contracts/utility/interfaces/ITokenHolder.sol


pragma solidity 0.6.12;



/*
    Token Holder interface
*/
interface ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) external;
}

// File: solidity/contracts/converter/interfaces/IConverterAnchor.sol


pragma solidity 0.6.12;



/*
    Converter Anchor interface
*/
interface IConverterAnchor is IOwned, ITokenHolder {
}

// File: solidity/contracts/utility/interfaces/IWhitelist.sol


pragma solidity 0.6.12;

/*
    Whitelist interface
*/
interface IWhitelist {
    function isWhitelisted(address _address) external view returns (bool);
}

// File: solidity/contracts/converter/interfaces/IConverter.sol


pragma solidity 0.6.12;





/*
    Converter interface
*/
interface IConverter is IOwned {
    function converterType() external pure returns (uint16);
    function anchor() external view returns (IConverterAnchor);
    function isActive() external view returns (bool);

    function targetAmountAndFee(IERC20Token _sourceToken, IERC20Token _targetToken, uint256 _amount) external view returns (uint256, uint256);
    function convert(IERC20Token _sourceToken,
                     IERC20Token _targetToken,
                     uint256 _amount,
                     address _trader,
                     address payable _beneficiary) external payable returns (uint256);

    function conversionWhitelist() external view returns (IWhitelist);
    function conversionFee() external view returns (uint32);
    function maxConversionFee() external view returns (uint32);
    function reserveBalance(IERC20Token _reserveToken) external view returns (uint256);
    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;
    function acceptAnchorOwnership() external;
    function setConversionFee(uint32 _conversionFee) external;
    function setConversionWhitelist(IWhitelist _whitelist) external;
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) external;
    function withdrawETH(address payable _to) external;
    function addReserve(IERC20Token _token, uint32 _ratio) external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);
    function transferTokenOwnership(address _newOwner) external;
    function acceptTokenOwnership() external;
    function connectors(IERC20Token _address) external view returns (uint256, uint32, bool, bool, bool);
    function getConnectorBalance(IERC20Token _connectorToken) external view returns (uint256);
    function connectorTokens(uint256 _index) external view returns (IERC20Token);
    function connectorTokenCount() external view returns (uint16);
}

// File: solidity/contracts/converter/interfaces/IConverterRegistry.sol


pragma solidity 0.6.12;

interface IConverterRegistry {
    function getAnchorCount() external view returns (uint256);
    function getAnchors() external view returns (address[] memory);
    function getAnchor(uint256 _index) external view returns (IConverterAnchor);
    function isAnchor(address _value) external view returns (bool);

    function getLiquidityPoolCount() external view returns (uint256);
    function getLiquidityPools() external view returns (address[] memory);
    function getLiquidityPool(uint256 _index) external view returns (IConverterAnchor);
    function isLiquidityPool(address _value) external view returns (bool);

    function getConvertibleTokenCount() external view returns (uint256);
    function getConvertibleTokens() external view returns (address[] memory);
    function getConvertibleToken(uint256 _index) external view returns (IERC20Token);
    function isConvertibleToken(address _value) external view returns (bool);

    function getConvertibleTokenAnchorCount(IERC20Token _convertibleToken) external view returns (uint256);
    function getConvertibleTokenAnchors(IERC20Token _convertibleToken) external view returns (address[] memory);
    function getConvertibleTokenAnchor(IERC20Token _convertibleToken, uint256 _index) external view returns (IConverterAnchor);
    function isConvertibleTokenAnchor(IERC20Token _convertibleToken, address _value) external view returns (bool);
}

// File: solidity/contracts/ConversionPathFinder.sol


pragma solidity 0.6.12;

/**
  * @dev The ConversionPathFinder contract allows generating a conversion path between any token pair in the Bancor Network.
  * The path can then be used in various functions in the BancorNetwork contract.
  *
  * See the BancorNetwork contract for conversion path format.
*/
contract ConversionPathFinder is IConversionPathFinder, ContractRegistryClient {
    IERC20Token public anchorToken;

    /**
      * @dev initializes a new ConversionPathFinder instance
      *
      * @param _registry address of a contract registry contract
    */
    constructor(IContractRegistry _registry) ContractRegistryClient(_registry) public {
    }

    /**
      * @dev updates the anchor token
      *
      * @param _anchorToken address of the anchor token
    */
    function setAnchorToken(IERC20Token _anchorToken) public ownerOnly {
        anchorToken = _anchorToken;
    }

    /**
      * @dev generates a conversion path between a given pair of tokens in the Bancor Network
      *
      * @param _sourceToken address of the source token
      * @param _targetToken address of the target token
      *
      * @return a path from the source token to the target token
    */
    function findPath(IERC20Token _sourceToken, IERC20Token _targetToken) external view override returns (address[] memory) {
        IConverterRegistry converterRegistry = IConverterRegistry(addressOf(CONVERTER_REGISTRY));
        address[] memory sourcePath = getPath(_sourceToken, converterRegistry);
        address[] memory targetPath = getPath(_targetToken, converterRegistry);
        return getShortestPath(sourcePath, targetPath);
    }

    /**
      * @dev generates a conversion path between a given token and the anchor token
      *
      * @param _token               address of the token
      * @param _converterRegistry   address of the converter registry
      *
      * @return a path from the input token to the anchor token
    */
    function getPath(IERC20Token _token, IConverterRegistry _converterRegistry) private view returns (address[] memory) {
        if (_token == anchorToken)
            return getInitialArray(address(_token));

        address[] memory anchors;
        if (_converterRegistry.isAnchor(address(_token)))
            anchors = getInitialArray(address(_token));
        else
            anchors = _converterRegistry.getConvertibleTokenAnchors(_token);

        for (uint256 n = 0; n < anchors.length; n++) {
            IConverter converter = IConverter(payable(IConverterAnchor(anchors[n]).owner()));
            uint256 connectorTokenCount = converter.connectorTokenCount();
            for (uint256 i = 0; i < connectorTokenCount; i++) {
                IERC20Token connectorToken = converter.connectorTokens(i);
                if (connectorToken != _token) {
                    address[] memory path = getPath(connectorToken, _converterRegistry);
                    if (path.length > 0)
                        return getExtendedArray(address(_token), anchors[n], path);
                }
            }
        }

        return new address[](0);
    }

    /**
      * @dev merges two paths with a common suffix into one
      *
      * @param _sourcePath address of the source path
      * @param _targetPath address of the target path
      *
      * @return merged path
    */
    function getShortestPath(address[] memory _sourcePath, address[] memory _targetPath) private pure returns (address[] memory) {
        if (_sourcePath.length > 0 && _targetPath.length > 0) {
            uint256 i = _sourcePath.length;
            uint256 j = _targetPath.length;
            while (i > 0 && j > 0 && _sourcePath[i - 1] == _targetPath[j - 1]) {
                i--;
                j--;
            }

            address[] memory path = new address[](i + j + 1);
            for (uint256 m = 0; m <= i; m++)
                path[m] = _sourcePath[m];
            for (uint256 n = j; n > 0; n--)
                path[path.length - n] = _targetPath[n - 1];

            uint256 length = 0;
            for (uint256 p = 0; p < path.length; p += 1) {
                for (uint256 q = p + 2; q < path.length - p % 2; q += 2) {
                    if (path[p] == path[q])
                        p = q;
                }
                path[length++] = path[p];
            }

            return getPartialArray(path, length);
        }

        return new address[](0);
    }

    /**
      * @dev creates a new array containing a single item
      *
      * @param _item item
      *
      * @return initial array
    */
    function getInitialArray(address _item) private pure returns (address[] memory) {
        address[] memory array = new address[](1);
        array[0] = _item;
        return array;
    }

    /**
      * @dev prepends two items to the beginning of an array
      *
      * @param _item0 first item
      * @param _item1 second item
      * @param _array initial array
      *
      * @return extended array
    */
    function getExtendedArray(address _item0, address _item1, address[] memory _array) private pure returns (address[] memory) {
        address[] memory array = new address[](2 + _array.length);
        array[0] = _item0;
        array[1] = _item1;
        for (uint256 i = 0; i < _array.length; i++)
            array[2 + i] = _array[i];
        return array;
    }

    /**
      * @dev extracts the prefix of a given array
      *
      * @param _array given array
      * @param _length prefix length
      *
      * @return partial array
    */
    function getPartialArray(address[] memory _array, uint256 _length) private pure returns (address[] memory) {
        address[] memory array = new address[](_length);
        for (uint256 i = 0; i < _length; i++)
            array[i] = _array[i];
        return array;
    }
}
