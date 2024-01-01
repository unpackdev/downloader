// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IVault.sol";
import "./Errors.sol";
import "./BytesCheck.sol";
import "./VaultEvents.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IAccount.sol";
import "./IStvAccount.sol";
import "./IQ.sol";
import "./Generate.sol";
import "./Trade.sol";
import "./IOperator.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";

/// @title Vault
/// @notice Contract to handle STFX logic
contract Vault is ReentrancyGuard, IVault, VaultEvents {
    using SafeERC20 for IERC20;
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the operator
    address public operator;
    /// @notice max funcraising period for an stv
    uint40 public maxFundraisingPeriod;
    /// @notice nonce for users
    mapping(address => uint256) public nonces;
    /// @notice typehash for the current chain
    bytes32 public constant EXECUTE_TYPEHASH = keccak256("executeData(bytes data,address user,uint256 nonce)");
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private immutable _hashedName = keccak256(bytes("vault"));
    bytes32 private immutable _hashedVersion = keccak256(bytes("1"));
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR/MODIFIERS
    //////////////////////////////////////////////////////////////*/

    constructor(address _operator, uint40 _maxFundraisingPeriod) {
        operator = _operator;
        maxFundraisingPeriod = _maxFundraisingPeriod;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedChainId = block.chainid;
        _cachedThis = address(this);
        emit InitVault(_operator, _maxFundraisingPeriod, _cachedDomainSeparator, EXECUTE_TYPEHASH);
    }

    modifier onlyOwner() {
        address owner = IOperator(operator).getAddress("OWNER");
        if (msg.sender != owner) revert Errors.NotOwner();
        _;
    }

    modifier onlyAdmin() {
        address admin = IOperator(operator).getAddress("ADMIN");
        if (msg.sender != admin) revert Errors.NotAdmin();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                        GETTERS/SETTERS
    //////////////////////////////////////////////////////////////*/

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
    /// @notice Get the address of Q contract
    /// @return address q

    function getQ() external view returns (address) {
        address q = IOperator(operator).getAddress("Q");
        return q;
    }

    /// @notice Get the stv info
    /// @param stvId address of the stv
    function getStvInfo(address stvId) public view returns (StvInfo memory) {
        return IStvAccount(stvId).stvInfo();
    }

    /// @notice Get the stv's accounting details
    /// @param stvId address of the stv
    function getStvBalance(address stvId) public view returns (StvBalance memory) {
        return IStvAccount(stvId).stvBalance();
    }

    /// @notice Get the investor's details in a particular stv
    /// @param investor address of the investor
    /// @param stvId address of the stv
    function getInvestorInfo(address investor, address stvId) public view returns (InvestorInfo memory) {
        return IStvAccount(stvId).investorInfo(investor);
    }

    /// @notice Get all the addresses invested in the stv
    /// @param stvId address of the stv
    function getInvestors(address stvId) public view returns (address[] memory) {
        return IStvAccount(stvId).getInvestors();
    }

    /// @notice Set the max fundraising period which is used when creating an stv
    /// @dev can only be called by the `owner`
    /// @param _maxFundraisingPeriod the max fundraising period in seconds
    function setMaxFundraisingPeriod(uint40 _maxFundraisingPeriod) external onlyOwner {
        if (_maxFundraisingPeriod == 0) revert Errors.ZeroAmount();
        maxFundraisingPeriod = _maxFundraisingPeriod;
        emit MaxFundraisingPeriod(_maxFundraisingPeriod);
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice creates a new stv by deploying a clone of `StvAccount` contract
    /// @dev the payload has to be signed by the `admin` before sending it as calldata
    /// @param capacityOfStv capacity of the stv
    /// @param metadataHash hash of the metadata
    /// @return stvId address of the stv
    function createStv(
        uint96 capacityOfStv,
        uint96 subscriptionFundLimit,
        bytes32 metadataHash,
        bytes calldata signature
    ) external returns (address stvId) {
        if (subscriptionFundLimit > capacityOfStv) revert Errors.InputMismatch();
        bytes memory data = abi.encode(capacityOfStv, metadataHash);
        _verifyData(data, signature);

        address op = operator;
        address managerAccount = IOperator(op).getTraderAccount(msg.sender);
        address q = IOperator(op).getAddress("Q");
        if (managerAccount == address(0)) IQ(q).createAccount(msg.sender);

        StvInfo memory stv = Generate.generate(capacityOfStv, msg.sender, op, maxFundraisingPeriod);
        stvId = stv.stvId;
        IStvAccount(stvId).createStv(stv);
        emit CreateStv(metadataHash, stv.stvId, stv.manager, stv.endTime, stv.capacityOfStv);

        if (subscriptionFundLimit > 0) {
            _investSubscribers(stvId, op, subscriptionFundLimit);
        }
    }

    /// @notice creates a new stv by deploying a clone of `StvAccount` contract
    /// @dev the payload has to be signed by the `admin` before sending it as calldata
    /// @param capacityOfStv capacity of the stv
    /// @param metadataHash hash of the metadata
    /// @param token address of the token the manager wants to use to deposit
    /// @param amount amount of the token the manager wants to deposit into the stv
    /// @param exchangeData data from `1inch` API
    /// @param signature signature from the `admin`
    /// @return stvId address of the stv
    function createStvWithDeposit(
        uint96 capacityOfStv,
        uint96 subscriptionFundLimit,
        bytes32 metadataHash,
        address token,
        uint96 amount,
        bytes memory exchangeData,
        bytes calldata signature
    ) external payable nonReentrant returns (address stvId) {
        bytes memory validateData = abi.encode(capacityOfStv, metadataHash, exchangeData);
        _verifyData(validateData, signature);

        address op = operator;
        address traderAccount;
        {
            traderAccount = IOperator(op).getTraderAccount(msg.sender);
            address q = IOperator(op).getAddress("Q");
            if (traderAccount == address(0)) traderAccount = IQ(q).createAccount(msg.sender);
        }
        {
            StvInfo memory stv = Generate.generate(capacityOfStv, msg.sender, op, maxFundraisingPeriod);
            stvId = stv.stvId;
            IStvAccount(stvId).createStv(stv);
            emit CreateStv(metadataHash, stvId, stv.manager, stv.endTime, stv.capacityOfStv);
        }
        {
            uint96 totalDepositWithSubscription;
            if (subscriptionFundLimit > 0) {
                totalDepositWithSubscription = _investSubscribers(stvId, op, subscriptionFundLimit);
            }
            uint256 returnAmount = _swap(token, stvId, amount, exchangeData, traderAccount);
            if (totalDepositWithSubscription + uint96(returnAmount) > capacityOfStv) {
                revert Errors.TotalRaisedMoreThanCapacity();
            }
            IStvAccount(stvId).deposit(traderAccount, uint96(returnAmount), true);
            emit Deposit(stvId, msg.sender, msg.sender, uint96(returnAmount));
        }
    }

    /// @notice deposits into the stv's contract from the trader's account contract
    /// @param stvId address of the stv
    /// @param amount amount of `defaultStableCoin` to deposit from the trader's Account contract
    function deposit(address stvId, uint96 amount) external nonReentrant {
        address account = IOperator(operator).getTraderAccount(msg.sender);
        StvInfo memory stv = getStvInfo(stvId);
        StvBalance memory sBalance = getStvBalance(stvId);
        InvestorInfo memory investorInfo = getInvestorInfo(account, stvId);
        address defaultStableCoin = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        uint256 accountBalance = IERC20(defaultStableCoin).balanceOf(account);
        uint256 minDepositAmount = 10 ** IERC20(defaultStableCoin).decimals();

        if (amount < minDepositAmount) revert Errors.BelowMinStvDepositAmount(); // 1 unit
        if (account == address(0)) revert Errors.AccountNotExists();
        if (accountBalance < amount) revert Errors.BalanceLessThanAmount();
        if (stv.manager == address(0)) revert Errors.StvDoesNotExist();
        if (uint40(block.timestamp) > stv.endTime) revert Errors.FundraisingPeriodEnded();
        if (stv.status != StvStatus.NOT_OPENED) revert Errors.AlreadyOpened();
        if (sBalance.totalRaised + amount > stv.capacityOfStv) {
            revert Errors.TotalRaisedMoreThanCapacity();
        }
        if (investorInfo.depositAmount == 0) IStvAccount(stvId).deposit(account, amount, true);
        else IStvAccount(stvId).deposit(account, amount, false);

        bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)", stvId, amount);
        IAccount(payable(account)).execute(defaultStableCoin, transferData, 0);
        emit Deposit(stvId, msg.sender, msg.sender, amount);
    }

    /// @notice deposits into the stv's contract without an Account create
    /// @notice creates an Account contract for `to`
    /// @dev `to` can be `msg.sender` when its the investor
    /// @dev `to` can be trader's address when its called in through a crosschain protocol
    /// @param to address of the trader
    /// @param stvId address of the stv
    /// @param amount amount of the token the investor wants to deposit into the stv
    /// @param token address of the token the investor wants to use to deposit
    /// @param exchangeData data from `1inch` API
    /// @param signature signature from the `admin`
    function depositTo(
        address to,
        address stvId,
        uint96 amount,
        address token,
        bytes memory exchangeData,
        bytes calldata signature
    ) external payable nonReentrant {
        _verifyData(exchangeData, signature);
        address account = IOperator(operator).getTraderAccount(to);
        address q = IOperator(operator).getAddress("Q");
        if (account == address(0)) account = IQ(q).createAccount(to);

        StvInfo memory stv = getStvInfo(stvId);
        StvBalance memory sBalance = getStvBalance(stvId);
        InvestorInfo memory investorInfo = getInvestorInfo(account, stvId);

        if (token == address(0)) {
            if (msg.value != amount) revert Errors.InputMismatch();
        } else {
            uint256 accountBalance = IERC20(token).balanceOf(msg.sender);
            if (amount > accountBalance) revert Errors.BalanceLessThanAmount();
        }

        if (stv.manager == address(0)) revert Errors.StvDoesNotExist();
        if (uint40(block.timestamp) > stv.endTime) revert Errors.FundraisingPeriodEnded();
        if (stv.status != StvStatus.NOT_OPENED) revert Errors.AlreadyOpened();
        amount = uint96(_swap(token, stvId, amount, exchangeData, account));
        if (sBalance.totalRaised + amount > stv.capacityOfStv) {
            revert Errors.TotalRaisedMoreThanCapacity();
        }
        if (investorInfo.depositAmount == 0) IStvAccount(stvId).deposit(account, amount, true);
        else IStvAccount(stvId).deposit(account, amount, false);

        emit Deposit(stvId, msg.sender, to, amount);
    }

    /// @notice changes the status of the stv to `LIQUIDATED`
    /// @dev can only be called by the `admin`
    /// @param stvId address of the stv
    function liquidate(address stvId) external onlyAdmin {
        IStvAccount(stvId).liquidate();
        emit Liquidate(stvId, uint8(IVault.StvStatus.LIQUIDATED));
    }

    /// @notice execute the type of trade
    /// @dev `totalReceived` will be 0 for perps and will be more than 0 for spot
    /// @dev can only be called by the `admin`
    /// @param command the command of the ddex protocol from `Commands` library
    /// @param data encoded data of parameters depending on the ddex
    /// @param isOpen bool to check if its an increase or decrease trade
    /// @return tradeToken address of the token which is used for spot execution
    /// @return totalReceived tokens received after trading a spot position
    function execute(uint256 command, bytes calldata data, bool isOpen)
        external
        payable
        onlyAdmin
        returns (address tradeToken, uint256 totalReceived)
    {
        (address stvId, uint256 amount) = _getAmountAndStvId(data);
        StvInfo memory stv = getStvInfo(stvId);
        StvBalance memory sBalance = getStvBalance(stvId);
        if (amount == 0) revert Errors.ZeroAmount();
        if (sBalance.totalRaised < 1) revert Errors.ZeroTotalRaised();
        if (stv.status != IVault.StvStatus.NOT_OPENED && stv.status != IVault.StvStatus.OPEN) {
            revert Errors.StvStatusMismatch();
        }

        if (BytesCheck.checkFirstDigit0x1(uint8(command))) {
            tradeToken = _getTradeToken(data);
            if (!isOpen) {
                if (
                    IStvAccount(stvId).totalTradeTokenUsedForClose(tradeToken) + amount
                        > IStvAccount(stvId).totalTradeTokenReceivedAfterOpen(tradeToken)
                ) {
                    revert Errors.MoreThanTotalRaised();
                }
            }
            totalReceived = Trade.execute(command, data, isOpen, operator);
        } else {
            address perpTrade = IOperator(operator).getAddress("PERPTRADE");
            bytes memory perpTradeData = abi.encodeWithSignature("execute(uint256,bytes,bool)", command, data, isOpen);
            (bool success,) = perpTrade.call{value: msg.value}(perpTradeData);
            if (!success) revert Errors.CallFailed(perpTradeData);
        }

        IStvAccount(stvId).execute(amount, tradeToken, totalReceived, isOpen);

        emit Execute(stvId, amount, totalReceived, command, data, msg.value, isOpen);
    }

    /// @notice executes many trades in a single function
    /// @dev `totalReceived` will be 0 for perps and will be more than 0 for spot
    /// @dev can only be called by the `admin`
    /// @param commands array of commands of the ddex protocol from `Commands` library
    /// @param data array of encoded data of parameters depending on the ddex
    /// @param msgValue msg.value for each command which has to be transfered when executing the position
    /// @param isOpen array of bool to check if its an increase or decrease trade
    function multiExecute(
        uint256[] memory commands,
        bytes[] calldata data,
        uint256[] memory msgValue,
        bool[] memory isOpen
    ) external payable onlyAdmin {
        uint256 length = commands.length;
        if (length != data.length) revert Errors.LengthMismatch();
        if (length != msgValue.length) revert Errors.LengthMismatch();

        uint256 i;
        address tradeToken;
        uint256 amountReceived;

        for (; i < length;) {
            uint256 command = commands[i];
            bytes calldata tradeData = data[i];
            uint256 value = msgValue[i];
            bool openOrClose = isOpen[i];
            (address stvId, uint256 amount) = _getAmountAndStvId(tradeData);
            StvInfo memory stv = getStvInfo(stvId);
            StvBalance memory sBalance = getStvBalance(stvId);

            if (amount == 0) revert Errors.ZeroAmount();
            if (sBalance.totalRaised < 1) revert Errors.ZeroTotalRaised();
            if (stv.status != IVault.StvStatus.NOT_OPENED && stv.status != IVault.StvStatus.OPEN) {
                revert Errors.StvStatusMismatch();
            }

            if (BytesCheck.checkFirstDigit0x1(uint8(command))) {
                tradeToken = _getTradeToken(tradeData);
                if (!openOrClose) {
                    if (
                        IStvAccount(stvId).totalTradeTokenUsedForClose(tradeToken) + amount
                            > IStvAccount(stvId).totalTradeTokenReceivedAfterOpen(tradeToken)
                    ) {
                        revert Errors.MoreThanTotalRaised();
                    }
                }
                amountReceived = Trade.execute(command, tradeData, openOrClose, operator);
            } else {
                address perpTrade = IOperator(operator).getAddress("PERPTRADE");
                bytes memory perpTradeData =
                    abi.encodeWithSignature("execute(uint256,bytes,bool)", command, tradeData, openOrClose);
                (bool success,) = perpTrade.call{value: value}(perpTradeData);
                if (!success) revert Errors.CallFailed(perpTradeData);
            }

            IStvAccount(stvId).execute(amount, tradeToken, amountReceived, openOrClose);
            emit Execute(stvId, amount, amountReceived, command, tradeData, value, openOrClose);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice distributes the fees to the manager and protocol and the remaining in the stv's contract to the investors
    /// @dev can only be called by the admin
    /// @param stvId address of the stv
    /// @param command command of the ddex protocol
    /// @param totalDepositTokenUsed total deposit token used in defaultStableCoin decimals
    /// @param managerFees manager fees in 1e18 decimals
    /// @param protocolFees protocol fees in 1e18 decimals
    /// @param tradeTokens addresss of the trade tokens to swap
    /// @param exchangeData exchange data to swap, 0 - eth swap, 1 - tradeToken swap
    function distribute(
        address stvId,
        uint256 command,
        uint96 totalDepositTokenUsed,
        uint96 managerFees,
        uint96 protocolFees,
        address[] calldata tradeTokens,
        bytes[] calldata exchangeData
    ) external onlyAdmin {
        //  TODO solve stack too deep by making the input params as a struct ??
        uint256 c = command; // to avoid stack too deep
        {
            StvInfo memory stv = getStvInfo(stvId);
            if (stv.status != StvStatus.OPEN) revert Errors.StvNotOpen();
        }

        (uint96 totalRemainingAfterDistribute, uint96 mFee, uint96 pFee) = Trade.distribute(
            stvId, c, totalDepositTokenUsed, managerFees, protocolFees, tradeTokens, exchangeData, operator
        );

        IStvAccount(stvId).distribute(totalRemainingAfterDistribute, mFee, pFee);

        emit Distribute(stvId, totalRemainingAfterDistribute, mFee, pFee, c);
    }

    /// @notice same as `distribute`, but is only called if `distribute` runs out of gas
    function distributeOut(address stvId, bool isCancel, uint256 indexFrom, uint256 indexTo) external onlyAdmin {
        IStvAccount(stvId).distributeOut(isCancel, indexFrom, indexTo);
    }

    /// @notice cancels the stv and transfers the tokens back to the investors
    /// @param stvId address of the stv
    function cancelStv(address stvId) external {
        StvInfo memory stv = getStvInfo(stvId);
        StvBalance memory sBalance = getStvBalance(stvId);
        address admin = IOperator(operator).getAddress("ADMIN");

        if (stv.status != StvStatus.NOT_OPENED) revert Errors.AlreadyOpened();
        if (msg.sender == admin) {
            if (uint40(block.timestamp) <= stv.endTime) revert Errors.BelowMinEndTime();
            if (sBalance.totalRaised == 0) {
                IStvAccount(stvId).updateStatus(StvStatus.CANCELLED_WITH_ZERO_RAISE);
            } else {
                IStvAccount(stvId).updateStatus(StvStatus.CANCELLED_WITH_NO_FILL);
            }
        } else if (msg.sender == stv.manager) {
            IStvAccount(stvId).updateStatus(StvStatus.CANCELLED_BY_MANAGER);
        } else {
            revert Errors.NoAccess();
        }

        IStvAccount(stvId).cancel();

        emit Cancel(stvId, uint8(stv.status));
    }

    /// @notice claims rewards from eligible ddex protocols
    /// @dev can only be called by the admin
    /// @param data array of encoded data to claim rewards from each ddex
    function claimStvTradingReward(uint256[] calldata commands, bytes[] calldata data) external onlyAdmin {
        address perpTrade = IOperator(operator).getAddress("PERPTRADE");
        uint256 i;
        for (; i < data.length;) {
            uint256 command = commands[i];
            bytes memory rewardData = data[i];
            bytes memory perpTradeData =
                abi.encodeWithSignature("execute(uint256,bytes,bool)", command, rewardData, false);
            (bool success,) = perpTrade.call(perpTradeData);
            if (!success) revert Errors.CallFailed(perpTradeData);
            (address stvId,) = _getAmountAndStvId(data[i]);
            emit ClaimRewards(stvId, command, rewardData);
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _investSubscribers(address stvId, address op, uint96 subscriptionFundLimit)
        internal
        returns (uint96 totalDepositWithSubscription)
    {
        address defaultStableCoin = IOperator(op).getAddress("DEFAULTSTABLECOIN");
        address[] memory subscribers = IOperator(op).getAllSubscribers(msg.sender);
        (bytes[] memory users, uint256 ratio) =
            _getSubscriptionRatio(subscribers, subscriptionFundLimit, defaultStableCoin, op);

        uint256 i;
        for (; i < users.length;) {
            (address traderAccount, uint96 amountToUse) = abi.decode(users[i], (address, uint96));
            uint96 amountAfterRatio = uint96(uint256(amountToUse) * ratio / 1e18);
            if (amountAfterRatio > 0) {
                totalDepositWithSubscription += amountAfterRatio;
                IStvAccount(stvId).deposit(traderAccount, amountAfterRatio, true);
                bytes memory transferData =
                    abi.encodeWithSignature("transfer(address,uint256)", stvId, amountAfterRatio);
                IAccount(payable(traderAccount)).execute(defaultStableCoin, transferData, 0);
                emit DepositWithSubscription(stvId, msg.sender, traderAccount, amountAfterRatio);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice pure function to get the first two params of the calldata
    /// @dev the first 2 params will always be the address and the amount
    function _getAmountAndStvId(bytes calldata data) internal pure returns (address stvId, uint256 amount) {
        assembly {
            stvId := calldataload(data.offset)
            amount := calldataload(add(data.offset, 0x20))
        }
    }

    /// @notice pure function to get the third param of the calldata which is the `tradeToken` for Spot execute
    /// @dev the third param for spot execution will always be `tradeToken`
    function _getTradeToken(bytes calldata data) internal pure returns (address tradeToken) {
        assembly {
            tradeToken := calldataload(add(data.offset, 0x40))
        }
    }

    function _getSubscriptionRatio(address[] memory subscribers, uint96 capacity, address defaultStableCoin, address op)
        internal
        view
        returns (bytes[] memory, uint256)
    {
        uint256 totalLiquidity;
        uint256 i;
        uint256 ratio;
        bytes[] memory users = new bytes[](subscribers.length);
        for (; i < subscribers.length;) {
            address subscriber = subscribers[i];
            uint96 maxLimit = IOperator(op).getSubscriptionAmount(msg.sender, subscriber);
            uint96 traderAccountBalance = uint96(IERC20(defaultStableCoin).balanceOf(subscriber));
            uint256 amountToUse = traderAccountBalance < maxLimit ? traderAccountBalance : maxLimit;
            users[i] = abi.encode(subscriber, amountToUse);
            totalLiquidity += amountToUse;
            unchecked {
                ++i;
            }
        }
        if (totalLiquidity > 0) {
            uint256 capacityToSubscriptions = uint256(capacity) * 1e18 / uint256(totalLiquidity);
            ratio = capacityToSubscriptions < 1e18 ? capacityToSubscriptions : 1e18;
        }
        return (users, ratio);
    }

    /// @notice internal function to swap the amount of token
    /// @param token address of the token to be swapped
    /// @param to address of the receipient
    /// @param amount amount of tokens to be swapped
    /// @param exchangeData calldata to swap
    /// @param traderAccount address of the account contract
    function _swap(address token, address to, uint96 amount, bytes memory exchangeData, address traderAccount)
        internal
        returns (uint256 returnAmount)
    {
        address defaultStableCoin = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        if (token != defaultStableCoin) {
            if (exchangeData.length == 0) revert Errors.ExchangeDataMismatch();
            address exchangeRouter = IOperator(operator).getAddress("ONEINCHROUTER");
            if (token != address(0)) {
                IERC20(token).safeTransferFrom(msg.sender, to, amount);
                bytes memory approveData = abi.encodeWithSelector(IERC20.approve.selector, exchangeRouter, amount);
                IStvAccount(to).execute(token, approveData, 0);
            }
            uint256 balanceBefore = IERC20(defaultStableCoin).balanceOf(to);
            IStvAccount(to).execute{value: msg.value}(exchangeRouter, exchangeData, msg.value);
            uint256 balanceAfter = IERC20(defaultStableCoin).balanceOf(to);
            if (balanceAfter <= balanceBefore) revert Errors.BalanceLessThanAmount();
            returnAmount = balanceAfter - balanceBefore;
            if (token != address(0) && (IERC20(token).allowance(to, exchangeRouter) != 0)) {
                revert Errors.InputMismatch();
            }
        } else {
            if (exchangeData.length != 0) revert Errors.ExchangeDataMismatch();
            uint96 traderAccountBalance = uint96(IERC20(defaultStableCoin).balanceOf(traderAccount));
            if (traderAccountBalance >= amount) {
                bytes memory transferData = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
                IAccount(payable(traderAccount)).execute(defaultStableCoin, transferData, 0);
            } else {
                IERC20(defaultStableCoin).transferFrom(msg.sender, to, amount);
            }
            returnAmount = amount;
        }

        uint256 minDepositAmount = 10 ** IERC20(defaultStableCoin).decimals();
        if (returnAmount < minDepositAmount) revert Errors.BelowMinStvDepositAmount(); // 1 unit
    }

    /// @notice internal function to verify if the calldata is signed by the `admin` or not
    /// @dev the data has to be signed by the `admin`
    function _verifyData(bytes memory data, bytes calldata signature) internal {
        bytes32 structHash = keccak256(abi.encode(EXECUTE_TYPEHASH, keccak256(data), msg.sender, nonces[msg.sender]++));
        bytes32 signedData = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR(), structHash);
        address signer = ECDSA.recover(signedData, signature);
        address admin = IOperator(operator).getAddress("ADMIN");
        if (signer != admin) revert Errors.NotAdmin();
    }
}
