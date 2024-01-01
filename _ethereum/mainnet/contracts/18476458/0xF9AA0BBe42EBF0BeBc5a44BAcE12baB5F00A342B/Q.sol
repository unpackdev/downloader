// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IAccount.sol";
import "./Errors.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./Clones.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";
import "./IOperator.sol";
import "./Commands.sol";

contract Q is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice nonce for users
    mapping(address => uint256) public nonces;
    address public operator;
    bytes32 public constant EXECUTE_TYPEHASH = keccak256("executeData(bytes data,address user,uint256 nonce)");
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private immutable _hashedName = keccak256(bytes("ozo"));
    bytes32 private immutable _hashedVersion = keccak256(bytes("1"));
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event InitQ(address indexed operator, bytes32 indexed domainSeparator, bytes32 indexed executeTypehash);
    event Deposit(
        address indexed trader,
        address indexed traderAccount,
        address indexed token,
        uint96 amount,
        uint256 returnAmount
    );
    event Withdraw(address indexed trader, address indexed traderAccount, address indexed token, uint96 amount);
    event Execute(bytes indexed data, uint256 msgValue);
    event CreateTraderAccount(address indexed trader, address indexed traderAccount);
    event CrossChainTrade(address indexed traderAccount, uint256 msgValue, bytes data, bytes signature);

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR/MODIFIERS
    //////////////////////////////////////////////////////////////*/

    constructor(address _operator) {
        operator = _operator;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedChainId = block.chainid;
        _cachedThis = address(this);
        emit InitQ(_operator, _cachedDomainSeparator, EXECUTE_TYPEHASH);
    }

    modifier onlyAdmin() {
        address admin = IOperator(operator).getAddress("ADMIN");
        if (msg.sender != admin) revert Errors.NotAdmin();
        _;
    }

    modifier onlyPlugin() {
        bool isPlugin = IOperator(operator).getPlugin(msg.sender);
        if (!isPlugin) revert Errors.NotPlugin();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit multiple tokens to your account.
    /// @param tokens The addresses of the tokens to be deposited.
    /// @param amounts The amounts of the tokens to be deposited.
    function deposit(
        address[] calldata tokens,
        uint96[] calldata amounts,
        bytes[] calldata exchangeData,
        bytes[] calldata signature
    ) external payable {
        uint256 tLen = tokens.length;
        uint256 i;
        if (tLen != amounts.length) revert Errors.LengthMismatch();
        for (; i < tLen;) {
            deposit(tokens[i], amounts[i], exchangeData[i], signature[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Deposits token to your account.
    /// @param token The address of the token to be deposited.
    /// @param amount The amount of the token to be deposited.
    /// @param exchangeData data to transfer the token to the defaultStableCoin
    function deposit(address token, uint96 amount, bytes calldata exchangeData, bytes calldata signature)
        public
        payable
        nonReentrant
    {
        if (amount == 0) revert Errors.ZeroAmount();
        address defaultToken = IOperator(operator).getAddress("DEFAULTSTABLECOIN");

        if (token == address(0)) {
            if (msg.value != amount) revert Errors.InputMismatch();
        } else {
            uint256 tokenBalance = IERC20(token).balanceOf(msg.sender);
            if (amount > tokenBalance) revert Errors.BalanceLessThanAmount();
        }

        address account = IOperator(operator).getTraderAccount(msg.sender);
        if (account == address(0)) account = _createAccount(msg.sender);

        uint256 returnAmount;
        if (token != defaultToken) {
            if (exchangeData.length == 0) revert Errors.ExchangeDataMismatch();
            _verifyData(exchangeData, signature);
            address exchangeRouter = IOperator(operator).getAddress("ONEINCHROUTER");
            uint256 balanceBefore = IERC20(defaultToken).balanceOf(account);
            if (token != address(0)) {
                IERC20(token).safeTransferFrom(msg.sender, account, amount);
                bytes memory approveData = abi.encodeWithSelector(IERC20.approve.selector, exchangeRouter, amount);
                IAccount(account).execute(token, approveData, 0);
                IAccount(account).execute(exchangeRouter, exchangeData, 0);
            } else {
                IAccount(account).execute{value: amount}(exchangeRouter, exchangeData, amount);
            }
            uint256 balanceAfter = IERC20(defaultToken).balanceOf(account);
            if (balanceAfter <= balanceBefore) revert Errors.BalanceLessThanAmount();
            returnAmount = balanceAfter - balanceBefore;
        } else {
            if (exchangeData.length != 0) revert Errors.ExchangeDataMismatch();
            IERC20(defaultToken).safeTransferFrom(msg.sender, account, amount);
        }
        emit Deposit(msg.sender, account, token, amount, returnAmount);
    }

    /// @notice withdraw any number of tokens from the `Account` contract
    /// @param token address of the token to be swapped
    /// @param amount total amount of `defaultStableCoin` to be withdrawn
    /// @param exchangeData calldata to swap from the dex
    /// @param signature signature of the exchangeData by the admin
    function withdraw(address token, uint96 amount, bytes calldata exchangeData, bytes calldata signature) external {
        if (amount == 0) revert Errors.ZeroAmount();
        address account = IOperator(operator).getTraderAccount(msg.sender);
        if (account == address(0)) revert Errors.NotInitialised();

        address defaultStableCoin = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        uint256 tokenBalance = IERC20(defaultStableCoin).balanceOf(account);
        if (amount > tokenBalance) revert Errors.BalanceLessThanAmount();

        if (token == defaultStableCoin) {
            if (exchangeData.length != 0) revert Errors.ExchangeDataMismatch();
            bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount);
            IAccount(account).execute(defaultStableCoin, transferData, 0);
        } else {
            _verifyData(exchangeData, signature);
            address exchangeRouter = IOperator(operator).getAddress("ONEINCHROUTER");
            bytes memory approvalData = abi.encodeWithSignature("approve(address,uint256)", exchangeRouter, amount);
            IAccount(account).execute(defaultStableCoin, approvalData, 0);
            uint256 defaultStableCoinBalanceBefore = IERC20(defaultStableCoin).balanceOf(account);
            IAccount(account).execute(exchangeRouter, exchangeData, 0);
            uint256 defaultStableCoinBalanceAfter = IERC20(defaultStableCoin).balanceOf(account);
            if (defaultStableCoinBalanceBefore - defaultStableCoinBalanceAfter != amount) {
                revert Errors.ExchangeDataMismatch();
            }
        }

        emit Withdraw(msg.sender, account, token, amount);
    }

    /// @notice Deposit & execute a trade in one transaction.
    /// @param token The address of the token to be deposited.
    /// @param amount The amount of the token to be deposited.
    /// @param exchangeData data to transfer the token to the defaultStableCoin
    /// @param data The data to be executed.
    /// @param signature The signature of the data.
    function depositAndExecute(
        address token,
        uint96 amount,
        bytes calldata exchangeData,
        bytes calldata data,
        bytes calldata signature,
        bytes calldata exchangeDataSignature
    ) external payable {
        _verifyData(data, signature);
        deposit(token, amount, exchangeData, exchangeDataSignature);
        address perpTrade = IOperator(operator).getAddress("PERPTRADE");
        (bool success,) = perpTrade.call{value: msg.value}(data);
        if (!success) revert Errors.CallFailed(data);
        emit Execute(data, msg.value);
    }

    /// @notice execute the type of trade
    /// @dev can only be called by the `admin`
    /// @param command the command of the ddex protocol from `Commands` library
    /// @param data encoded data of parameters depending on the ddex
    /// @param isOpen bool to check if its an increase or decrease trade
    function execute(uint256 command, bytes calldata data, bool isOpen) public payable onlyAdmin {
        bytes memory tradeData = abi.encodeWithSignature("execute(uint256,bytes,bool)", command, data, isOpen);
        address perpTrade = IOperator(operator).getAddress("PERPTRADE");
        (bool success,) = perpTrade.call{value: msg.value}(tradeData);
        if (!success) revert Errors.CallFailed(tradeData);
        emit Execute(data, msg.value);
    }

    /// @notice executes many trades in a single function
    /// @dev can only be called by the `admin`
    /// @param commands array of commands of the ddex protocol from `Commands` library
    /// @param data array of encoded data of parameters depending on the ddex
    /// @param msgValue msg.value for each command which has to be transfered when executing the position
    /// @param isOpen array of bool to check if its an increase or decrease trade
    function multiExecute(
        uint256[] calldata commands,
        bytes[] calldata data,
        uint256[] calldata msgValue,
        bool[] calldata isOpen
    ) public payable onlyAdmin {
        if (data.length != msgValue.length) revert Errors.LengthMismatch();
        address perpTrade = IOperator(operator).getAddress("PERPTRADE");
        uint256 i;
        for (; i < data.length;) {
            uint256 command = commands[i];
            bytes calldata tradeData = data[i];
            uint256 value = msgValue[i];
            bool openOrClose = isOpen[i];

            bytes memory perpTradeData =
                abi.encodeWithSignature("execute(uint256,bytes,bool)", command, tradeData, openOrClose);
            (bool success,) = perpTrade.call{value: value}(perpTradeData);
            if (!success) revert Errors.CallFailed(perpTradeData);

            emit Execute(tradeData, value);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Creates a new account for the trader.
    /// @dev can only be called by a plugin
    /// @param trader The address of the trader.
    function createAccount(address trader) public onlyPlugin returns (address newAccount) {
        address traderAccount = IOperator(operator).getTraderAccount(trader);
        if (traderAccount != address(0)) revert Errors.AccountAlreadyExists();
        newAccount = _createAccount(trader);
        emit CreateTraderAccount(trader, newAccount);
    }

    /// @notice Trade on a exchange using lifi
    /// @dev The function should be called by lifi
    /// @param data The payload to be passed to the perpTrade contract
    /// @dev "user" is the address of the trader, so to get account we have to query traderAccount[user]
    function crossChainTradeReciever(bytes memory data, bytes memory signature) public payable nonReentrant {
        bool success;
        // EIP-712
        _verifyData(data, signature);

        (address token, address user, uint96 amount, bytes memory payload) =
            abi.decode(data, (address, address, uint96, bytes));

        address tradeAccount = IOperator(operator).getTraderAccount(user);
        if (tradeAccount == address(0)) tradeAccount = _createAccount(user);
        if (token != address(0)) _depositTo(token, tradeAccount, amount);

        address perpTrade = IOperator(operator).getAddress("PERPTRADE");
        (success, payload) = perpTrade.call{value: msg.value}(payload);
        if (!success) revert Errors.CallFailed(payload);

        emit CrossChainTrade(tradeAccount, msg.value, data, signature);
    }

    function sgReceive(uint16, bytes memory, uint256, address, uint256 amountLD, bytes memory payload)
        external
        payable
    {
        // Check the caller is stargate router
        address stargateRouter = IOperator(operator).getAddress("STARGATE");
        if (msg.sender != stargateRouter) revert Errors.NoAccess();

        // Verify that the payload is signed by the admin
        (bytes memory data, bytes memory signature) = abi.decode(payload, (bytes, bytes));
        bool success;
        _verifyData(data, signature);

        (address token, address user, uint96 amount, bytes memory payload) =
            abi.decode(data, (address, address, uint96, bytes));

        // transfer the token amount to the user
        address tradeAccount = IOperator(operator).getTraderAccount(user);
        if (tradeAccount == address(0)) tradeAccount = _createAccount(user);
        if (token != address(0)) IERC20(token).transfer(tradeAccount, amountLD);

        // Execute the trade
        address perpTrade = IOperator(operator).getAddress("PERPTRADE");
        (success, payload) = perpTrade.call{value: msg.value}(payload);
        if (!success) revert Errors.CallFailed(payload);

        emit CrossChainTrade(tradeAccount, msg.value, data, signature);
    }

    function swap(address account, address tradeToken, bytes[] memory exchangeData) external onlyAdmin {
        address exchangeRouter = IOperator(operator).getAddress("ONEINCHROUTER");
        address defaultStableCoin = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        uint256 balanceBefore = IERC20(defaultStableCoin).balanceOf(account);
        uint256 ethBalance = account.balance;

        if (ethBalance > 0) IAccount(account).execute(exchangeRouter, exchangeData[0], ethBalance);
        if (tradeToken != address(0)) {
            uint256 tokenInBalance = IERC20(tradeToken).balanceOf(account);
            bytes memory tokenApprovalData =
                abi.encodeWithSignature("approve(address,uint256)", exchangeRouter, tokenInBalance);
            IAccount(account).execute(tradeToken, tokenApprovalData, 0);
            IAccount(account).execute(exchangeRouter, exchangeData[1], 0);
        }

        uint256 balanceAfter = IERC20(defaultStableCoin).balanceOf(account);
        if (balanceAfter <= balanceBefore) revert Errors.BalanceLessThanAmount();
    }

    function changeTraderAccount(address newTrader) external {
        if (newTrader == address(0)) revert Errors.ZeroAddress();
        address traderAccount = IOperator(operator).getTraderAccount(msg.sender);
        IOperator(operator).setTraderAccount(newTrader, traderAccount);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _createAccount(address trader) internal returns (address newAccount) {
        bytes32 salt = keccak256(abi.encodePacked(trader));
        address accountImplementation = IOperator(operator).getAddress("ACCOUNT");
        newAccount = Clones.cloneDeterministic(accountImplementation, salt);
        IOperator(operator).setTraderAccount(trader, newAccount);
    }

    /*
    
        * `TradeRemote` is a function that will only be called by lifi
        * It will be called when a trader wants to trade on a remote exchange
        
        FLOW:
            * TradeRemote called by lifi
            * DepositRemote fucntion is called from inside TradeRemote
                - it decodes msg.sender from the payload
                - it creates a new account for the trader, if not already exists
                - It transferFrom the tokens from the lifi to the Trader Account
            * Trade Remote Pass the payload to the perpTrade contract
            * perpTrade contract will execute the trade on the remote exchange
    */

    function _depositTo(address token, address user, uint256 amount) internal {
        if (amount == 0) revert Errors.ZeroAmount();

        uint256 tokenBalance = IERC20(token).balanceOf(msg.sender);
        if (amount > tokenBalance) revert Errors.BalanceLessThanAmount();

        IERC20(token).safeTransferFrom(msg.sender, user, amount);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    function _verifyData(bytes memory data, bytes memory signature) internal {
        bytes32 structHash = keccak256(abi.encode(EXECUTE_TYPEHASH, keccak256(data), msg.sender, nonces[msg.sender]++));
        bytes32 signedData = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR(), structHash);
        address signer = ECDSA.recover(signedData, signature);
        address admin = IOperator(operator).getAddress("ADMIN");
        if (signer != admin) revert Errors.NotAdmin();
    }
}
