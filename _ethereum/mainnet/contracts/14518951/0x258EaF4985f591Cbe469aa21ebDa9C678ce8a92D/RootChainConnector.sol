// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

import "./ISaver.sol";
import "./ISaverExtended.sol";
import "./IRootChainManager.sol";
import "./IWormhole.sol";
import "./ISwapper.sol";
import "./Structs.sol";

contract RootChainConnector is Initializable, AccessControlUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct WithdrawOperation {
        IERC20 token;
        uint256 amount;
        uint256 requestedAmount;
    }

    event AddToken(address token);
    event RemoveToken(address token);
    event SetAddresses(address transferBuffer, address ust, address swapper);
    event SetSlippage(uint256 slippageNumerator, uint256 extraSlippageNumerator);
    event Deposit(address token, uint256 amount, uint256 ustAmount);
    event Withdraw(uint32 index, address token, uint256 amount, uint256 requestedUstAmount, uint32 nonce, uint64 sequence);
    event WithdrawFinalized(uint32 index, uint256 ustAmount, address token, uint256 amount);
    event WithdrawToContract(IERC20 token, uint256 amount);
    event DepositAsUst(IERC20 token, uint256 amount, uint256 ustAmount);

    modifier only(bytes32 role) {
        require(hasRole(role, msg.sender), "INSUFFICIENT_PERMISSIONS");
        _;
    }

    modifier withToken(IERC20 token) {
        require(tokens[token] == true, "token not added");
        _;
    }

    IRootChainManager private rootChainManager;
    address private tokenPredicate;
    ISaver private saver;
    IWormhole private wormhole;

    mapping(IERC20 => bool) private tokens;
    mapping(uint32 => bool) private processedMessages;

    address private transferBuffer;

    IERC20 private ust;
    ISwapper private swapper;

    mapping(uint32 => WithdrawOperation) private withdrawOperations;
    uint32 private woLeftPointer;
    uint32 private woRightPointer;

    uint256 private _default_slippage_numerator;
    uint256 private _default_extra_slippage_numerator;
    uint256 constant _default_denominator = 100_000;

    function initialize(
        address rootChainManagerProxy,
        address tokenPredicateProxy,
        address saverProxy,
        address wormholeProxy
    ) public initializer {
        rootChainManager = IRootChainManager(rootChainManagerProxy);
        tokenPredicate = tokenPredicateProxy;
        saver = ISaver(saverProxy);
        wormhole = IWormhole(wormholeProxy);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*
        ------------------------------------------------------------------------------------------------
                                        CONFIGURATION FUNCTIONS
        ------------------------------------------------------------------------------------------------
    */

    function addToken(IERC20 token) external only(DEFAULT_ADMIN_ROLE) {
        require(tokens[token] == false, "token already added");

        tokens[token] = true;

        emit AddToken(address(token));
    }

    function removeToken(IERC20 token) external only(DEFAULT_ADMIN_ROLE) withToken(token) {
        delete tokens[token];

        emit RemoveToken(address(token));
    }

    function setSlippage(uint256 slippageNumerator, uint256 extraSlippageNumerator) external only(DEFAULT_ADMIN_ROLE) {
        _default_slippage_numerator = slippageNumerator;
        _default_extra_slippage_numerator = extraSlippageNumerator;

        emit SetSlippage(slippageNumerator, extraSlippageNumerator);
    }

    function setAddresses(address transferBufferAddress, address ustAddress, address swapperAddress) external only(DEFAULT_ADMIN_ROLE) {
        transferBuffer = transferBufferAddress;
        ust = IERC20(ustAddress);
        swapper = ISwapper(swapperAddress);

        emit SetAddresses(transferBufferAddress, ustAddress, swapperAddress);
    }

    /*
    ------------------------------------------------------------------------------------------------
                                        ADMIN FUNCTIONS
    ------------------------------------------------------------------------------------------------
    */

    function withdrawToContract(IERC20 token, uint256 amount) external only(DEFAULT_ADMIN_ROLE) withToken(token) {
        saver.withdraw(token, amount);
        emit WithdrawToContract(token, amount);
    }

    function depositAsUst(IERC20 token, uint256 amount) external only(DEFAULT_ADMIN_ROLE) withToken(token) {
        uint256 balanceBefore = ust.balanceOf(address(this));
        token.safeApprove(address(swapper), amount);
        swapper.swapToken(address(token), address(ust), amount, applySlippage(adjustDecimals(token, ust, amount)), address(this));
        uint256 swapped = ust.balanceOf(address(this)).sub(balanceBefore);

        ust.safeApprove(address(saver), swapped);
        saver.deposit(ust, swapped);

        emit DepositAsUst(token, amount, swapped);
    }

    /*
        ------------------------------------------------------------------------------------------------
                                        DEPOSIT/WITHDRAW FUNCTIONS
        ------------------------------------------------------------------------------------------------
    */

    function deposit(IERC20 token, bytes calldata proof) external withToken(token) {
        uint256 balanceBefore = token.balanceOf(address(this));
        rootChainManager.exit(proof);
        uint256 deposited = token.balanceOf(address(this)).sub(balanceBefore);
        require(deposited > 0, "no funds exited");

        uint256 swapped;
        if (token == ust) {
            swapped = deposited; // no need to swap UST to UST
        } else {
            uint256 ustBalanceBefore = ust.balanceOf(address(this));
            token.safeApprove(address(swapper), deposited);
            swapper.swapToken(address(token), address(ust), deposited, applySlippage(adjustDecimals(token, ust, deposited)), address(this));
            swapped = ust.balanceOf(address(this)).sub(ustBalanceBefore);
        }

        ust.safeApprove(address(saver), swapped);
        saver.deposit(ust, swapped);

        emit Deposit(address(token), deposited, swapped);
    }

    function withdraw(bytes calldata signedVaa) external {
        (Structs.VM memory vm, bool valid, string memory reason) = wormhole.parseAndVerifyVM(signedVaa);
        require(valid, reason);
        require(processedMessages[vm.nonce] == false, "message already processed");
        require(bytes32(uint256(uint160(address(this)))) == vm.emitterAddress, "incorrect emitterAddress");

        (address tokenAddress, uint256 amount) = abi.decode(vm.payload, (address, uint256));
        IERC20 token = IERC20(tokenAddress);
        uint256 ustAmount = adjustDecimals(token, ust, amount);
        require(tokens[token], "token not added");
        require(ustAmount > 0, "zero withdraw amount");

        uint256 requestedUstAmount = applyExtraSlippage(ustAmount);
        withdrawOperations[woRightPointer] = WithdrawOperation(token, amount, requestedUstAmount);

        processedMessages[vm.nonce] = true;
        saver.withdraw(ust, requestedUstAmount);

        emit Withdraw(woRightPointer++, tokenAddress, amount, requestedUstAmount, vm.nonce, vm.sequence);
    }

    function finalizeWithdraws() external {
        require(transferBuffer != address(0), "transferBuffer not set");
        require(canFinalizeWithdraw(), "withdraw finalization not available");

        while(canFinalizeWithdraw()) {
            WithdrawOperation memory withdrawOperation = withdrawOperations[woLeftPointer];
            IERC20 token = withdrawOperation.token;
            uint256 requestedUstAmountAfterFee = applyShuttleFee(ust, withdrawOperation.requestedAmount);

            uint256 swapped;
            if (token == ust) {
                swapped = requestedUstAmountAfterFee; // no need to swap UST to UST
            } else {
                uint256 balanceBefore = token.balanceOf(address(this));
                ust.safeApprove(address(swapper), requestedUstAmountAfterFee);
                uint256 minOutputAmount = applySlippage(adjustDecimals(ust, token, requestedUstAmountAfterFee));
                swapper.swapToken(address(ust), address(token), requestedUstAmountAfterFee, minOutputAmount, address(this));
                swapped = token.balanceOf(address(this)).sub(balanceBefore);
            }

            require(swapped >= withdrawOperation.amount, "insufficient swap from UST");
            token.safeApprove(tokenPredicate, swapped);
            rootChainManager.depositFor(transferBuffer, address(token), abi.encodePacked(swapped));

            emit WithdrawFinalized(woLeftPointer++, requestedUstAmountAfterFee, address(token), swapped);
        }
    }

    /*
        ------------------------------------------------------------------------------------------------
                                        GET FUNCTIONS
        ------------------------------------------------------------------------------------------------
    */

    function isTokenRegistered(IERC20 token) public view returns (bool) {
        return tokens[token];
    }

    function isMessageProcessed(bytes calldata signedVaa) public view returns (bool) {
        (Structs.VM memory vm,,) = wormhole.parseAndVerifyVM(signedVaa);
        return processedMessages[vm.nonce];
    }

    function canFinalizeWithdraw() public view returns (bool) {
        if (woLeftPointer >= woRightPointer) return false;

        WithdrawOperation memory withdrawOperation = withdrawOperations[woLeftPointer];

        return ust.balanceOf(address(this)) >= applyShuttleFee(ust, withdrawOperation.requestedAmount);
    }

    function getAddresses() public view returns (
        address _rootChainManager,
        address _tokenPredicate,
        address _saver,
        address _wormhole,
        address _transferBuffer,
        address _ust,
        address _swapper
    ) {
        _rootChainManager = address(rootChainManager);
        _tokenPredicate = tokenPredicate;
        _saver = address(saver);
        _wormhole = address(wormhole);
        _transferBuffer = transferBuffer;
        _ust = address(ust);
        _swapper = address(swapper);
    }

    function applySlippage(uint256 amount) public view returns (uint256) {
        return amount.sub(amount.mul(_default_slippage_numerator).div(_default_denominator));
    }

    function applyExtraSlippage(uint256 amount) public view returns (uint256) {
        return amount.add(amount.mul(_default_extra_slippage_numerator).div(_default_denominator));
    }

    function applyShuttleFee(IERC20 token, uint256 amount) public view returns (uint256) {
        return amount.sub(ISaverExtended(address(saver)).get_withdraw_fee(token, amount));
    }

    function adjustDecimals(IERC20 srcToken, IERC20 destToken, uint256 amount) public view returns (uint256) {
        uint8 srcDecimals = IERC20Metadata(address(srcToken)).decimals();
        uint8 destDecimals = IERC20Metadata(address(destToken)).decimals();

        if (srcDecimals < destDecimals) {
            return amount.mul(10 ** (destDecimals - srcDecimals));
        } else {
            return amount.div(10 ** (srcDecimals - destDecimals));
        }
    }
}
