// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC20.sol";

import "./IWETH.sol";
import "./IPriceOracle.sol";

import "./RLPReader.sol";
import "./Errors.sol";
import "./RToken.sol";

import "./Version1.sol";

import "./IBridgeCosignerManager.sol";
import "./IBridgeTokenManager.sol";
import "./IFeeManager.sol";
import "./IRelayerManager.sol";

import "./IBridgeToken.sol";
import "./IBridgeRouter.sol";
import "./IExitReceiver.sol";
import "./IOwnable.sol";

contract BridgeRouter is
    Version1,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IBridgeRouter
{
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;
    using RToken for RToken.Token;

    mapping(address => uint256) private _nonces;
    mapping(bytes32 => bool) private _commitments;

    // ===== initialize override =====
    uint256 private _chainId;
    IERC20 public weth9;

    IBridgeCosignerManager public cosignerManager;
    IBridgeTokenManager public tokenManager;
    IFeeManager public feeManager;
    IPriceOracle public priceOracle;
    IRelayerManager public relayerManager;

    // ===== proxy =====

    uint256[45] private __gap;

    // ===== fallbacks =====

    receive() external payable {}

    // ===== events =====

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _emitEnter(
        address token,
        address to,
        uint256 amount,
        uint256 amountMin,
        uint256 deadline,
        uint256 targetChainId,
        bytes calldata callData
    ) private {
        address from = _msgSender();
        emit Enter(
            token,
            to,
            from,
            address(this),
            amount,
            amountMin,
            deadline,
            _nonces[from],
            _chainId,
            targetChainId,
            callData
        );
        _nonces[from]++;
    }

    function _emitExit(
        address token,
        address to,
        address executor,
        bytes32 commitment,
        uint256 amount,
        uint256 extChainId
    ) private {
        emit Exit(
            token,
            to,
            executor,
            amount,
            commitment,
            _chainId,
            extChainId
        );
    }

    // ===== functionality to update =====

    /**
     * @notice Set the weth9 contract address
     * @dev This should be the contract responsible for wrapped of native token logic
     * @param newWeth9 address of weth9 smart contract
     */
    function setWETH9(address newWeth9) external onlyOwner {
        require(newWeth9 != address(0), Errors.B_ZERO_ADDRESS);
        weth9 = IERC20(newWeth9);
    }

    /**
     * @notice Set the token manager, callable only by cosigners
     * @dev This should be the contract responsible for checking and add tokens to crosschain mapping
     * @param newTokenManager address of token manager contract
     */
    function setTokenManager(address newTokenManager) external onlyOwner {
        require(newTokenManager != address(0), Errors.B_ZERO_ADDRESS);
        tokenManager = IBridgeTokenManager(newTokenManager);
    }

    /**
     * @notice Set the cosigner manager, callable only by cosigners
     * @dev This should be the contract responsible for sign by behalf of the payloads
     * @param newCosignerManager address of cosigner manager contract
     */
    function setCosignerManager(address newCosignerManager) external onlyOwner {
        require(newCosignerManager != address(0), Errors.B_ZERO_ADDRESS);
        cosignerManager = IBridgeCosignerManager(newCosignerManager);
    }

    /**
     * @notice Set the fee manager, for relayer fee detection
     * @dev This should be the contract responsible for calculation processing fee of relay
     * @param newFeeManager address of fee manager contract
     */
    function setFeeManager(address newFeeManager) external onlyOwner {
        require(newFeeManager != address(0), Errors.B_ZERO_ADDRESS);
        feeManager = IFeeManager(newFeeManager);
    }

    /**
     * @notice Set the relayer manager, for relayer fee detection
     * @dev This should be the contract responsible for fetching executional relayer
     * @param newRelayerManager address of relayer manager contract
     */
    function setRelayerManager(address newRelayerManager) external onlyOwner {
        require(newRelayerManager != address(0), Errors.B_ZERO_ADDRESS);
        relayerManager = IRelayerManager(newRelayerManager);
    }

    /**
     * @notice Set the price oracle, callable only for price estimation
     * @dev This should be the contract responsible for recalculate fee price in required token
     * @param newPriceOracle address of price oracle contract
     */
    function setPriceOracle(address newPriceOracle) external onlyOwner {
        require(newPriceOracle != address(0), Errors.B_ZERO_ADDRESS);
        priceOracle = IPriceOracle(newPriceOracle);
    }

    /**
     * @notice Update token info in case of mistake or name re-branding
     * @dev This token should be bridged in order to do this
     * @param token address of bridged token
     * @param newName a new name of token
     * @param newSymbol a new symbol of token
     * @param newDecimals a new decimal of token
     */
    function updateTokenInfo(
        address token,
        string calldata newName,
        string calldata newSymbol,
        uint8 newDecimals
    ) external onlyOwner {
        IBridgeToken(token).updateTokenInfo(newName, newSymbol, newDecimals);
    }

    /**
     * @notice Update token ownership (bor token upgrade and maintenance)
     * @dev This token should be ownable in order to do this
     * @param token address of bridged token
     * @param newOwner new token owner
     */
    function transferTokenOwnership(
        address token,
        address newOwner
    ) external onlyOwner {
        IOwnable(token).transferOwnership(newOwner);
    }

    // ----- tx relayer readers -------
    function getTxFees(
        address token,
        uint256 dataLength
    ) public view returns (uint256 fee) {
        fee = feeManager.getFees(relayerManager.appId(), _chainId, dataLength);
        if (token != address(weth9) && token != address(0)) {
            fee = priceOracle.getAmountOut(address(weth9), token, fee);
        }
        return fee;
    }

    function getTxRelayer(bytes32 commitment) external view returns (address) {
        return relayerManager.pickRelayer(commitment);
    }

    function getRelayerSubmitInfoFromData(
        bytes calldata data,
        uint256 slippage
    ) external view returns (uint256) {
        RLPReader.RLPItem[] memory logRLPList = data.toRlpItem().toList();
        RLPReader.RLPItem[] memory logTopicRLPList = logRLPList[1].toList(); // topics

        require(
            bytes32(logTopicRLPList[0].toUint()) == Enter.selector, // topic0 is event sig
            Errors.B_INVALID_EVENT
        );

        RToken.Token memory token = tokenManager.getLocal(
            logTopicRLPList[1].toAddress(),
            logRLPList[7].toUint(),
            logRLPList[8].toUint()
        );
        require(token.exist, Errors.B_NOT_LISTED);

        return
            (getTxFees(token.addr, data.length) * (10000 - slippage)) / 10000;
    }

    // Initialize function for proxy constructor. Must be used atomically
    function initialize(
        IERC20 weth9_,
        IBridgeCosignerManager cosignerManager_,
        IBridgeTokenManager tokenManager_,
        IFeeManager feeManager_,
        IRelayerManager relayerManager_,
        IPriceOracle priceOracle_
    ) public initializer {
        weth9 = weth9_;
        cosignerManager = cosignerManager_;
        tokenManager = tokenManager_;
        feeManager = feeManager_;
        relayerManager = relayerManager_;
        priceOracle = priceOracle_;
        assembly {
            sstore(_chainId.slot, chainid())
        }

        // proxy inits
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
    }

    function _limitOverflowCheck(address tokenAddr, uint256 amt) internal view {
        uint256 currentLimit = tokenManager.limits(tokenAddr);
        // 0 means infinite or no limit set up
        if (currentLimit == 0) {
            return;
        }
        uint256 totalBalance = IERC20(tokenAddr).balanceOf(address(this));
        // as weth9 and native token is the same, we should take into account both balances
        if (tokenAddr == address(weth9)) {
            totalBalance += address(this).balance;
        }
        require(totalBalance + amt <= currentLimit, Errors.BR_LIMIT_OVERFLOW);
    }

    // enter amount of tokens to protocol
    function enter(
        address token,
        uint256 amount,
        uint256 amountMin,
        uint256 deadline,
        uint256 targetChainId,
        address to,
        bytes calldata callData
    ) external override whenNotPaused {
        require(token != address(0), Errors.B_ZERO_ADDRESS);
        require(amount != 0, Errors.B_ZERO_AMOUNT);
        require(amountMin <= amount, Errors.BR_AMOUNT_OVERFLOW);
        require(deadline >= block.timestamp, Errors.B_EXPIRED);

        RToken.Token memory localToken = tokenManager.getLocal(
            token,
            _chainId,
            targetChainId
        );

        _limitOverflowCheck(localToken.addr, amount);

        _emitEnter(
            localToken.addr,
            to,
            amount,
            amountMin,
            deadline,
            targetChainId,
            callData
        );

        localToken.enter(_msgSender(), address(this), amount);
    }

    // enter amount of system currency to protocol
    function enterETH(
        uint256 amountMin,
        uint256 deadline,
        uint256 targetChainId,
        address to,
        bytes calldata callData
    ) external payable override whenNotPaused {
        require(msg.value != 0, Errors.B_ZERO_AMOUNT);
        require(amountMin <= msg.value, Errors.BR_AMOUNT_OVERFLOW);
        require(deadline >= block.timestamp, Errors.B_EXPIRED);

        RToken.Token memory localToken = tokenManager.getLocal(
            address(weth9),
            _chainId,
            targetChainId
        );
        require(localToken.exist, Errors.B_ENTITY_NOT_EXIST);

        // zero as msg.value already was added to a contract balance
        _limitOverflowCheck(localToken.addr, 0);

        _emitEnter(
            localToken.addr,
            to,
            msg.value,
            amountMin,
            deadline,
            targetChainId,
            callData
        );
    }

    // exit amount of tokens from protocol with/out relayer
    function exit(
        bytes calldata data,
        bytes[] calldata signatures,
        ProcessorParams calldata params
    ) external override whenNotPaused {
        uint256 startGas = gasleft();

        RLPReader.RLPItem[] memory logRLPList = data.toRlpItem().toList();
        RLPReader.RLPItem[] memory logTopicRLPList = logRLPList[1].toList(); // topics

        require(
            bytes32(logTopicRLPList[0].toUint()) == Enter.selector, // topic0 is event sig
            Errors.B_INVALID_EVENT
        );

        ExitData memory edata = ExitData(
            logTopicRLPList[1].toAddress(),
            logTopicRLPList[2].toAddress(),
            logTopicRLPList[3].toAddress(),
            logRLPList[2].toAddress(),
            _msgSender(),
            logRLPList[3].toUint(),
            logRLPList[4].toUint(),
            logRLPList[5].toUint(),
            logRLPList[8].toUint(),
            logRLPList[7].toUint(),
            logRLPList[9].toBytes()
        );

        require(edata.amount != 0, Errors.B_ZERO_AMOUNT);
        require(edata.amountMin <= edata.amount, Errors.BR_AMOUNT_OVERFLOW);
        require(edata.extChainId != _chainId, Errors.BR_WRONG_SOURCE_CHAIN);
        require(edata.localChainId == _chainId, Errors.BR_WRONG_TARGET_CHAIN);
        require(edata.exitor != address(this), Errors.B_PROTECTED_ADDRESS);

        // protected from replay on another network
        bytes32 commitment = keccak256(data);

        require(!_commitments[commitment], Errors.BR_COMMITMENT_KNOWN);
        _commitments[commitment] = true;
        require(
            cosignerManager.verify(commitment, edata.extChainId, signatures),
            Errors.BR_INVALID_SIGNATURES
        );

        RToken.Token memory token = tokenManager.getLocal(
            edata.extTokenAddr,
            edata.extChainId,
            edata.localChainId
        );

        if (params.useRelay) {
            (uint256 fee, address relayer) = _relayCharge(
                token,
                commitment,
                data.length
            );
            require(
                params.minFee == 0 || params.minFee <= fee,
                Errors.BR_FEE_TOO_LOW
            );
            require(
                edata.amountMin + fee <= edata.amount,
                Errors.BR_FEE_OVERFLOW
            );
            edata.amount -= fee;
            edata.executor = relayer;
        }

        token.exit(address(this), edata.exitor, edata.amount);
        // if (edata.exitor.code.length > 0) {
        //     // NOTE: Add gas limitation someday later (in case if we want to have a controlled gas usage)
        //     (bool success, bytes memory returnData) = edata.exitor.call(
        //         abi.encodeWithSelector(
        //             IExitReceiver.onExit.selector,
        //             edata.amount,
        //             token.addr,
        //             edata.originSender,
        //             edata.extChainId,
        //             edata.callData
        //         )
        //     );
        //     // if fallback executed ok, check for result, otherwise ignore
        //     if (success) {
        //         bool ok = abi.decode(returnData, (bool));
        //         require(ok, Errors.BR_EXECUTION_FAILED);
        //     }
        // }

        // could be used by relayer to prevent gas cost contracts on fallbacks
        require(
            params.gasLimit == 0 || params.gasLimit >= startGas - gasleft(),
            Errors.B_GAS_OVERFLOW
        );

        _emitExit(
            token.addr,
            edata.exitor,
            edata.executor,
            commitment,
            edata.amount,
            edata.extChainId
        );
    }

    function _relayCharge(
        RToken.Token memory token,
        bytes32 commitment,
        uint256 dataLength
    ) private returns (uint256 fee, address relayer) {
        fee = feeManager.getFees(relayerManager.appId(), _chainId, dataLength);
        require(fee > 0, Errors.B_ZERO_AMOUNT);
        if (token.addr != address(weth9)) {
            fee = priceOracle.getAmountOut(address(weth9), token.addr, fee);
        }
        relayer = relayerManager.pickRelayer(commitment);
        require(relayer == _msgSender(), Errors.BR_WRONG_EXECUTOR);
        token.exit(address(this), relayer, fee);
    }
}
