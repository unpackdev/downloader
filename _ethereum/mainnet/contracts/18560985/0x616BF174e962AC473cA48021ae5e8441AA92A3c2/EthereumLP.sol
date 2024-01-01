// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity 0.8.19;

import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Proxied.sol";

import "./IToSTBTLp.sol";

// This contract will provide atomic STBT swapping service from other stable coins
//
// When it has enough stable coins, it will send them to the STBT minter contract for non-atomic T+1 STBT minting.
//
// When moving a liquidity provider's STBT to this contract:
//
// 1. ToSTBTLp's owner adds this liquidity provider to its whitelist
// 2. This liquidity provider approves STBT to this ToSTBTLp contract
// 3. The owner of this ToSTBTLp contract calls the 'depositSTBT' function
//
// The ToSTBTLp contract's owner is a TimeLock contract. The TimeLock contract's proposers and executors are all cactus accounts.

interface IRegistry {
    function isRegistered(address addr) external view returns (bool);
}

interface IStbtMinter {
    function mint(
        address token,
        uint depositAmount,
        uint minProposedAmount,
        bytes32 salt,
        bytes calldata extraData
    ) external;
}

contract EthereumLP is IToSTBTLp, Proxied, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum OverflowAction {
        MINT_STBT, // mint to STBT
        WITHDRAW // withdraw to receiver
    }

    struct TokenConfig {
        uint64 mul; // assuming all supported tokens have <= 18 decimal points
        uint64 endOfService;
        uint96 balanceCap;
        uint16 feeBps;
        uint16 rewardBps;
        bool paused;
        OverflowAction overflowAction;
        address receiver;
    }

    struct TokenConfigParams {
        uint64 endOfService;
        uint96 balanceCap;
        uint16 feeBps;
        uint16 rewardBps;
        bool paused;
        OverflowAction overflowAction;
    }

    // immutable
    address public stbt; // 0x530824DA86689C9C17CdC2871Ff29B058345b44a
    address public stbtMinter; // 0xdAC17F958D2ee523a2206206994597C13D831ec7
    address public usdvMinterProxy;

    // configurable
    address public operator;
    address public lp;
    mapping(address => TokenConfig) public tokenConfigs;
    EnumerableSet.AddressSet private tokens;
    uint private constant MAX_REWARD_BPS = 100;
    uint private constant MAX_FEE_BPS = 100;

    event MintSTBTOnOverflow(address indexed fromToken, uint amount);
    event SwapToSTBT(address indexed caller, address indexed fromToken, uint amountIn, uint amountOut);
    event WithdrawToken(address indexed token, uint amount, address target);
    event DepositSTBT(uint amount, address source);
    event SetLp(address lp);
    event SetOperator(address operator);
    event AddToken(address token, address _receiver, TokenConfigParams params);
    event RemoveToken(address token);
    event SetTokenConfig(address token, TokenConfigParams params);

    //When this contract is upgraded, the new implementation's constructor must init the same immutables
    function initialize(
        address _lp,
        address _operator,
        address _stbt,
        address _stbtMinter,
        address _minterProxy
    ) external proxied initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        lp = _lp;
        operator = _operator;

        stbt = _stbt;
        stbtMinter = _stbtMinter;
        usdvMinterProxy = _minterProxy;
    }

    // 1. Verify that the caller (msg.sender) is registered in MinterProxy.
    modifier onlyMinter() {
        require(IRegistry(usdvMinterProxy).isRegistered(msg.sender), "STBTLP: NOT_MINTER");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "STBTLP: NOT_OPERATOR");
        _;
    }

    // ======================== OWNER interfaces ========================

    // set lp
    // TimelockController need a long delay before calling this function
    function setLp(address _lp) external onlyOwner {
        lp = _lp;
        emit SetLp(_lp);
    }

    function addToken(address _token, address _receiver, TokenConfigParams calldata _params) external onlyOwner {
        require(_params.rewardBps <= MAX_REWARD_BPS, "STBTLP: REWARDBPS_TOO_LARGE");
        require(_params.feeBps <= MAX_FEE_BPS, "STBTLP: FEEBPS_TOO_LARGE");

        require(_token != address(0) && _token != stbt, "STBTLP: INVALID_TOKEN");
        // don't check if token is added here and allow owner to update the config

        // set conversion rate
        uint8 decimals = IERC20Metadata(_token).decimals();
        require(decimals <= 18, "STBTLP: INVALID_DECIMALS");

        tokenConfigs[_token] = TokenConfig({
            mul: uint64(10 ** (18 - decimals)),
            endOfService: _params.endOfService,
            balanceCap: _params.balanceCap,
            feeBps: _params.feeBps,
            rewardBps: _params.rewardBps,
            paused: _params.paused,
            overflowAction: _params.overflowAction,
            receiver: _receiver
        });

        tokens.add(_token);
        emit AddToken(_token, _receiver, _params);
    }

    function removeToken(address _token) external onlyOwner {
        require(tokens.contains(_token), "STBTLP: TOKEN_NOT_EXISTS");
        tokens.remove(_token);
        delete tokenConfigs[_token];
        emit RemoveToken(_token);
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
        emit SetOperator(_operator);
    }

    // only to lp
    // can withdraw any token
    function withdrawToken(address _token, uint _amount) external onlyOwner {
        IERC20(_token).safeTransfer(lp, _amount);
        emit WithdrawToken(_token, _amount, lp);
    }

    // ======================== OPERATOR interfaces ========================

    // only from lp. require approval first
    function depositSTBT(uint _amount) external onlyOperator {
        IERC20(stbt).safeTransferFrom(lp, address(this), _amount);
        emit DepositSTBT(_amount, lp);
    }

    function setTokenConfig(address _token, TokenConfigParams calldata _params) external onlyOperator {
        require(_params.rewardBps <= MAX_REWARD_BPS, "STBTLP: REWARDBPS_TOO_LARGE");
        require(_params.feeBps <= MAX_FEE_BPS, "STBTLP: FEEBPS_TOO_LARGE");

        TokenConfig storage cfg = tokenConfigs[_token];
        require(cfg.mul != 0, "STBTLP: token not added");

        cfg.endOfService = _params.endOfService;
        cfg.balanceCap = _params.balanceCap;
        cfg.feeBps = _params.feeBps;
        cfg.rewardBps = _params.rewardBps;
        cfg.paused = _params.paused;
        cfg.overflowAction = _params.overflowAction;
        emit SetTokenConfig(_token, _params);
    }

    function setPaused(bool _p) external onlyOperator {
        _p ? _pause() : _unpause();
    }

    // ======================== Swap interfaces ========================
    /// @dev function should revert if minAmount is not reached
    function swapToSTBT(
        address _fromToken,
        uint256 _fromTokenAmount,
        uint256 _minAmountOut
    ) external override whenNotPaused onlyMinter nonReentrant returns (uint requestedOut, uint rewardOut) {
        TokenConfig memory cfg = tokenConfigs[_fromToken];
        _sanityCheck(cfg);

        (requestedOut, rewardOut) = _swap(_fromToken, _fromTokenAmount, cfg);

        uint stbtOut = requestedOut + rewardOut;
        require(stbtOut >= _minAmountOut, "STBTLP: NOT_ENOUGH_STBT_OUT");

        // finally, transfer to msg.sender
        require(IERC20(stbt).balanceOf(address(this)) >= stbtOut, "STBTLP: NOT_ENOUGH_STBT");
        IERC20(stbt).safeTransfer(msg.sender, stbtOut);
        emit SwapToSTBT(msg.sender, _fromToken, _fromTokenAmount, stbtOut);
    }

    function _sanityCheck(TokenConfig memory _cfg) internal view {
        require(_cfg.mul != 0, "STBTLP: TOKEN_NOT_SUPPORTED");
        require(!_cfg.paused, "STBTLP: TOKEN_PAUSED");
        require(_cfg.endOfService == 0 || block.timestamp < _cfg.endOfService, "STBTLP: END_OF_SERVICE");
    }

    function _swap(
        address _token,
        uint _amount,
        TokenConfig memory _cfg
    ) internal returns (uint requestedOut, uint rewardOut) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        (requestedOut, rewardOut) = _getSTBTAmountOut(_amount, _cfg);

        if (_cfg.overflowAction == OverflowAction.MINT_STBT) {
            _mintSTBTIfOverflow(_token, _cfg);
        } else if (_cfg.overflowAction == OverflowAction.WITHDRAW) {
            _withdrawIfOverflow(_token, _cfg);
        } else {
            revert("STBTLP: INVALID_OVERFLOW_ACTION");
        }
    }

    // evoke stbt mint when token is over the threshold
    // the batch processing is to make accounting easier
    function _mintSTBTIfOverflow(address _token, TokenConfig memory _cfg) internal {
        uint tokenBalance = IERC20(_token).balanceOf(address(this));
        if (tokenBalance > _cfg.balanceCap) {
            // mint all
            IERC20(_token).forceApprove(stbtMinter, tokenBalance);
            IStbtMinter(stbtMinter).mint(_token, tokenBalance, tokenBalance * _cfg.mul, bytes32(tokenBalance), "");
            emit MintSTBTOnOverflow(_token, tokenBalance);
        }
    }

    // evoke token withdraw when token is over the threshold
    function _withdrawIfOverflow(address _token, TokenConfig memory _cfg) internal {
        uint tokenBalance = IERC20(_token).balanceOf(address(this));
        if (tokenBalance > _cfg.balanceCap && _cfg.receiver != address(0)) {
            // transfer all
            IERC20(_token).safeTransfer(_cfg.receiver, tokenBalance);
            emit WithdrawToken(_token, tokenBalance, _cfg.receiver);
        }
    }

    function _getSTBTAmountOut(
        uint _amount,
        TokenConfig memory _cfg
    ) internal pure returns (uint requestedOut, uint rewardOut) {
        requestedOut = _amount * _cfg.mul;
        if (_cfg.rewardBps > 0) {
            rewardOut = (requestedOut * _cfg.rewardBps) / 10000;
        }
        if (_cfg.feeBps > 0) {
            requestedOut -= (requestedOut * _cfg.feeBps) / 10000;
        }
    }

    function getSupportedTokens() external view override returns (address[] memory supported) {
        supported = tokens.values();
        uint index = 0;

        for (uint i = 0; i < supported.length; i++) {
            address token = supported[i];
            TokenConfig memory cfg = tokenConfigs[token];
            if (cfg.paused || (cfg.endOfService != 0 && block.timestamp >= cfg.endOfService)) continue;
            supported[index++] = token;
        }
        assembly {
            mstore(supported, index)
        }
    }

    function getAllTokens() external view returns (address[] memory allTokens) {
        allTokens = tokens.values();
    }

    function getSwapToSTBTAmountOut(
        address _fromToken,
        uint _fromTokenAmount
    ) external view override returns (uint requestedOut, uint rewardOut) {
        TokenConfig memory cfg = tokenConfigs[_fromToken];
        _sanityCheck(cfg);
        (requestedOut, rewardOut) = _getSTBTAmountOut(_fromTokenAmount, cfg);
        require(IERC20(stbt).balanceOf(address(this)) >= requestedOut + rewardOut, "STBTLP: NOT_ENOUGH_STBT");
    }
}
