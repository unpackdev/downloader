// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity 0.8.19;

import "./IERC20Metadata.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./IOFT.sol";

import "./IUSDV.sol";
import "./IMinter.sol";
import "./IMinterProxy.sol";
import "./IToSTBTLp.sol";
import "./IVaultManager.sol";

contract Minter is IMinter, Ownable {
    using SafeERC20 for IERC20;

    uint8 internal constant USDV_DECIMALS = 6;

    IVaultManager public immutable vault;
    address public immutable minterProxy;
    uint public immutable usdv2stbtRate;

    address public immutable stbt;
    address public immutable usdv;

    mapping(address toSTBTLp => mapping(address fromToken => bool)) public approved;
    mapping(address => bool) public blacklisted;

    uint32 public color;
    uint16 public rewardToUserBps;

    constructor(uint32 _color, address _stbt, address _vault, address _minterProxy) {
        stbt = _stbt;
        usdv = IMinterProxy(_minterProxy).usdv();

        IUSDV(usdv).setDefaultColor(address(this), _color);
        color = _color;

        minterProxy = _minterProxy;

        vault = IVaultManager(_vault);
        IERC20(_stbt).safeApprove(_vault, type(uint).max); // to support mint
        (, usdv2stbtRate, ) = vault.assetInfoOf(_stbt);
    }

    // ------------------ modifier ------------------
    modifier onlyMinterProxy() {
        if (msg.sender != minterProxy) revert OnlyMinterProxy();
        _;
    }

    modifier notBlacklisted(address _user) {
        if (blacklisted[_user]) revert Blacklisted();
        _;
    }

    // ------------------ onlyOwner ------------------
    /// @dev to support swapToSTBT, only max approves
    function approve(address _toSTBTLp, address[] calldata _tokens) external onlyOwner {
        for (uint i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (!approved[_toSTBTLp][token]) {
                approved[_toSTBTLp][token] = true;
                IERC20(token).safeApprove(_toSTBTLp, type(uint).max);
                emit ApprovedToken(_toSTBTLp, token);
            }
        }
    }

    function disapprove(address _toSTBTLp, address[] calldata _tokens) external onlyOwner {
        for (uint i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (approved[_toSTBTLp][token]) {
                approved[_toSTBTLp][token] = false;
                IERC20(token).safeApprove(_toSTBTLp, 0);
                emit DisapprovedToken(_toSTBTLp, token);
            }
        }
    }

    function blacklist(address _user, bool _isBlacklisted) external onlyOwner {
        blacklisted[_user] = _isBlacklisted;
        emit BlacklistedUser(_user, _isBlacklisted);
    }

    function setRewardToUserBps(uint16 _rewardToUserBps) external onlyOwner {
        rewardToUserBps = _rewardToUserBps;
        emit SetRewardToUserBps(_rewardToUserBps);
    }

    function withdrawToken(address _token, address _to, uint _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit WithdrawToken(_token, _to, _amount);
    }

    // ------------------ external ------------------
    function swapToUSDV(
        address _sender,
        address _toSTBTLp,
        SwapParam calldata _param,
        address _usdvReceiver
    ) external notBlacklisted(_sender) onlyMinterProxy returns (uint usdvOut) {
        usdvOut = _swapToUSDV(_toSTBTLp, _param.fromToken, _param.fromTokenAmount, _param.minUSDVOut, _usdvReceiver);
    }

    function swapToUSDVAndSend(
        address _sender,
        address _toSTBTLp,
        SwapParam calldata _param,
        bytes32 _usdvReceiver,
        uint32 _dstEid,
        bytes calldata _extraOptions,
        MessagingFee calldata _msgFee,
        address payable _refundAddress
    ) external payable notBlacklisted(_sender) onlyMinterProxy returns (uint usdvOut) {
        usdvOut = _swapToUSDV(_toSTBTLp, _param.fromToken, _param.fromTokenAmount, _param.minUSDVOut, address(this));
        IUSDV(usdv).send{value: msg.value}(
            IOFT.SendParam(_usdvReceiver, usdvOut, usdvOut, _dstEid),
            _extraOptions,
            _msgFee,
            _refundAddress,
            ""
        );
    }

    // ------------------ view ------------------
    /// @dev get supported tokens of lpToSTBT and filter out unapproved tokens
    function getSupportedFromTokens(address _toSTBTLp) external view returns (address[] memory tokens) {
        tokens = IToSTBTLp(_toSTBTLp).getSupportedTokens();

        uint index = 0;
        for (uint i = 0; i < tokens.length; i++) {
            if (approved[_toSTBTLp][tokens[i]]) {
                tokens[index++] = tokens[i]; // index strictly smaller or equals to i, in place update
            }
        }
        assembly {
            mstore(tokens, index)
        }
    }

    function getSwapToUSDVAmountOut(
        address _toSTBTLp,
        address _fromToken,
        uint _fromTokenAmount
    ) external view returns (uint usdvOut) {
        // get requested and reward amount
        (uint stbtOut, uint rewardOut) = IToSTBTLp(_toSTBTLp).getSwapToSTBTAmountOut(_fromToken, _fromTokenAmount);
        // apply reward
        if (rewardOut > 0) {
            uint rewardToUser = (rewardOut * rewardToUserBps) / 10000; // e.g. get 5bps reward. if push 1bps to users, the rewardToUserBps = 2000
            stbtOut += rewardToUser;
        }
        // convert to usdv
        usdvOut = stbtOut / usdv2stbtRate;
        if (usdvOut > type(uint64).max) revert ExceedsUInt64();
    }

    function getSwapToUSDVAmountOutVerbose(
        address _toSTBTLp,
        address _fromToken,
        uint _fromTokenAmount
    ) external view returns (uint usdvOut, uint fee, uint reward) {
        uint8 tokenDecimals = IERC20Metadata(_fromToken).decimals();
        require(tokenDecimals >= USDV_DECIMALS, "BridgeRecolor: token decimals must >= 6");
        uint usdvRequested = _fromTokenAmount / (10 ** (tokenDecimals - USDV_DECIMALS));

        // get swapped and reward amount
        (uint requestedSTBTOut, uint rewardSTBTOut) = IToSTBTLp(_toSTBTLp).getSwapToSTBTAmountOut(
            _fromToken,
            _fromTokenAmount
        );
        usdvOut = requestedSTBTOut / usdv2stbtRate;
        // fee charged by lp
        fee = usdvRequested - usdvOut;

        // apply reward
        if (rewardSTBTOut > 0) {
            reward = (rewardSTBTOut * rewardToUserBps) / 10000 / usdv2stbtRate; // reward to user
            usdvOut += reward; // e.g. get 5bps reward. if push 1bps to users, the rewardToUserBps = 2000
        }
        if (usdvOut > type(uint64).max) revert ExceedsUInt64();
    }

    // ------------------ internal ------------------
    function _swapToUSDV(
        address _toSTBTLp,
        address _fromToken,
        uint _fromTokenAmount,
        uint64 _minUSDVOut,
        address _usdvReceiver
    ) internal returns (uint usdvOut) {
        if (!approved[_toSTBTLp][_fromToken]) revert TokenNotSupported();

        uint minSTBTOut = _minUSDVOut * usdv2stbtRate;
        // get requested and reward amount
        (uint stbtOut, uint rewardOut) = IToSTBTLp(_toSTBTLp).swapToSTBT(_fromToken, _fromTokenAmount, minSTBTOut);
        // apply reward
        if (rewardOut > 0) {
            uint rewardToUser = (rewardOut * rewardToUserBps) / 10000; // e.g. get 5bps reward. if push 1bps to users, the rewardToUserBps = 2000
            stbtOut += rewardToUser;
        }
        // check slippage
        if (stbtOut < minSTBTOut) revert SlippageTooHigh();
        // convert to usdv
        usdvOut = stbtOut / usdv2stbtRate;
        if (usdvOut > type(uint64).max) revert ExceedsUInt64();
        // mint requested to user and leave stbt reward in vault
        vault.mint(stbt, _usdvReceiver, uint64(usdvOut), color, "");
    }
}