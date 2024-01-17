// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "./IERC20Basic.sol";
import "./MoToken.sol";
import "./CurrencyOracle.sol";

/// @title Stable coin manager
/// @notice This handles all stable coin operations related to the token

contract StableCoin {
    /// @dev All assets are stored with 4 decimal shift
    uint8 public constant MO_DECIMALS = 4;

    /// @dev Mapping points to the address where the stablecoin contract is deployed on chain
    mapping(bytes32 => address) public contractAddressOf;

    /// @dev Mapping points to the pipe address where the stablecoins to be converted to fiat are transferred
    mapping(bytes32 => address) public pipeAddressOf;

    /// @dev Array of all stablecoins added to the contract
    bytes32[] private stableCoinsAssociated;

    /// @dev OraclePriceExchange Address contract associated with the stable coin
    address public currencyOracleAddress;

    /// @dev platform fee currency associated with tokens
    bytes32 public platformFeeCurrency = "USDC";

    /// @dev Accrued fee amount charged by the platform
    uint256 public accruedPlatformFee;

    /// @dev Implements RWA manager and whitelist access
    address public accessControlManagerAddress;

    event CurrencyOracleAddressSet(address indexed currencyOracleAddress);
    event StableCoinAdded(
        bytes32 indexed symbol,
        address indexed contractAddress,
        address indexed pipeAddress
    );
    event StableCoinDeleted(bytes32 indexed symbol);
    event AccessControlManagerSet(address indexed accessControlAddress);

    constructor(address _accessControlManager) {
        accessControlManagerAddress = _accessControlManager;
        emit AccessControlManagerSet(_accessControlManager);
    }

    /// @notice Access modifier to restrict access only to owner

    modifier onlyOwner() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isOwner(msg.sender), "NO");
        _;
    }

    /// @notice Access modifier to restrict access only to RWA manager addresses

    modifier onlyRWAManager() {
        AccessControlManager acm = AccessControlManager(
            accessControlManagerAddress
        );
        require(acm.isRWAManager(msg.sender), "NR");
        _;
    }

    /// @notice Setter for accessControlManagerAddress
    /// @param _accessControlManagerAddress Set accessControlManagerAddress to this address

    function setAccessControlManagerAddress(
        address _accessControlManagerAddress
    ) external onlyOwner {
        accessControlManagerAddress = _accessControlManagerAddress;
        emit AccessControlManagerSet(_accessControlManagerAddress);
    }

    /// @notice Allows setting currencyOracleAddress
    /// @param _currencyOracleAddress address of the currency oracle

    function setCurrencyOracleAddress(address _currencyOracleAddress)
        external
        onlyOwner
    {
        currencyOracleAddress = _currencyOracleAddress;
        emit CurrencyOracleAddressSet(currencyOracleAddress);
    }

    /// @notice Adds a new stablecoin
    /// @dev There can be no duplicate entries for same stablecoin symbol
    /// @param _symbol Stablecoin symbol
    /// @param _contractAddress Stablecoin contract address on chain
    /// @param _pipeAddress Pipe address associated with the stablecoin

    function addStableCoin(
        bytes32 _symbol,
        address _contractAddress,
        address _pipeAddress
    ) external onlyOwner {
        require(
            _symbol.length > 0 && contractAddressOf[_symbol] == address(0),
            "SCE"
        );
        contractAddressOf[_symbol] = _contractAddress;
        stableCoinsAssociated.push(_symbol);
        pipeAddressOf[_symbol] = _pipeAddress;
        emit StableCoinAdded(_symbol, _contractAddress, _pipeAddress);
    }

    /// @notice Deletes an existing stablecoin
    /// @param _symbol Stablecoin symbol

    function deleteStableCoin(bytes32 _symbol) external onlyOwner {
        require(contractAddressOf[_symbol] != address(0), "NC");
        delete contractAddressOf[_symbol];
        delete pipeAddressOf[_symbol];
        for (uint256 i = 0; i < stableCoinsAssociated.length; i++) {
            if (stableCoinsAssociated[i] == _symbol) {
                stableCoinsAssociated[i] = stableCoinsAssociated[
                    stableCoinsAssociated.length - 1
                ];
                stableCoinsAssociated.pop();
                break;
            }
        }
        emit StableCoinDeleted(_symbol);
    }

    /// @notice Getter for Stable coins associated
    /// @return bytes32[] Stable coins accepted by the token

    function getStableCoinsAssociated()
        external
        view
        returns (bytes32[] memory)
    {
        return stableCoinsAssociated;
    }

    /// @notice Get balance of the stablecoins in the wallet address
    /// @param _symbol Stablecoin symbol
    /// @param _address User address
    /// @return uint Returns the stablecoin balance

    function balanceOf(bytes32 _symbol, address _address)
        public
        view
        returns (uint256)
    {
        IERC20Basic ier = IERC20Basic(contractAddressOf[_symbol]);
        return ier.balanceOf(_address);
    }

    /// @notice Gets the decimals of the token
    /// @param _tokenSymbol Token symbol
    /// @return uint8 ERC20 decimals() value

    function decimals(bytes32 _tokenSymbol) public view returns (uint8) {
        IERC20Basic ier = IERC20Basic(contractAddressOf[_tokenSymbol]);
        return ier.decimals();
    }

    /// @notice Gets the total stablecoin balance associated with the MoToken
    /// @param _token Token address
    /// @param _fiatCurrency Fiat currency used
    /// @return balance Stablecoin balance

    function totalBalanceInFiat(address _token, bytes32 _fiatCurrency)
        public
        view
        returns (uint256 balance)
    {
        CurrencyOracle currencyOracle = CurrencyOracle(currencyOracleAddress);
        for (uint256 i = 0; i < stableCoinsAssociated.length; i++) {
            (uint64 stableToFiatConvRate, uint8 decimalsVal) = currencyOracle
                .getFeedLatestPriceAndDecimals(
                    stableCoinsAssociated[i],
                    _fiatCurrency
                );
            uint8 finalDecVal = decimalsVal +
                decimals(stableCoinsAssociated[i]) -
                MO_DECIMALS;
            balance +=
                (balanceOf(stableCoinsAssociated[i], _token) *
                    stableToFiatConvRate) /
                (10**finalDecVal);
            balance +=
                (balanceOf(
                    stableCoinsAssociated[i],
                    pipeAddressOf[stableCoinsAssociated[i]]
                ) * stableToFiatConvRate) /
                (10**finalDecVal);
        }
        balance -= accruedPlatformFee;
    }

    /// @notice Transfers tokens from an external address to the MoToken Address
    /// @param _token Token address
    /// @param _from Transfer tokens from this address
    /// @param _stableCoinAmount Amount to transfer
    /// @param _symbol Symbol of the tokens to transfer
    /// @return bool Boolean indicating transfer success/failure

    function initiateTransferFrom(
        address _token,
        address _from,
        uint256 _stableCoinAmount,
        bytes32 _symbol
    ) external returns (bool) {
        require(contractAddressOf[_symbol] != address(0), "NC");
        MoToken moToken = MoToken(_token);
        return (
            moToken.receiveStableCoins(
                contractAddressOf[_symbol],
                _from,
                _stableCoinAmount
            )
        );
    }

    /// @notice Transfers tokens from the MoToken address to the stablecoin pipe address
    /// @param _token Token address
    /// @param _stableCoinAmount Amount to transfer
    /// @param _symbol Symbol of the tokens to transfer
    /// @return bool Boolean indicating transfer success/failure

    function transferFundsToPipe(
        address _token,
        bytes32 _symbol,
        uint256 _stableCoinAmount
    ) external onlyRWAManager returns (bool) {
        checkForSufficientBalance(_token, _symbol, _stableCoinAmount);

        MoToken moToken = MoToken(_token);
        return (
            moToken.transferStableCoins(
                contractAddressOf[_symbol],
                pipeAddressOf[_symbol],
                _stableCoinAmount
            )
        );
    }

    /// @notice Check for sufficient balance
    /// @param _address Address holding the tokens
    /// @param _symbol Symbol of the token
    /// @param _amount amount to check

    function checkForSufficientBalance(
        address _address,
        bytes32 _symbol,
        uint256 _amount
    ) public view {
        uint256 balance = balanceOf(_symbol, _address);
        if (_symbol == platformFeeCurrency) {
            balance -= accruedPlatformFee;
        }
        require(_amount <= balance, "NF");
    }
}
