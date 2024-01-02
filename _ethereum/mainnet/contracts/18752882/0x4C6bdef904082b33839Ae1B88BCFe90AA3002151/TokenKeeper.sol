// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ITokenKeeper.sol";

import "./SafeERC20.sol";
import "./Ownable2Step.sol";
import "./IERC20.sol";

import "./Error.sol";

contract TokenKeeper is Ownable2Step, ITokenKeeper {
    using SafeERC20 for IERC20;

    address public zap;
    address public stargateReceiver;

    // account address => token address => balance
    mapping(address => mapping(address => uint256)) public balances;

    constructor(address _owner) Ownable(_owner) { }

    /*///////////////////////////////////////////////////////////////
                            SETTER FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITokenKeeper
    function setZapAndStargateReceiver(address _zap, address _receiver) external onlyOwner {
        _setZap(_zap);
        _setStargateReceiver(_receiver);
    }

    /// @inheritdoc ITokenKeeper
    function setZap(address _zap) external onlyOwner {
        _setZap(_zap);
    }

    /// @inheritdoc ITokenKeeper
    function setStargateReceiver(address _receiver) external onlyOwner {
        _setStargateReceiver(_receiver);
    }

    /*///////////////////////////////////////////////////////////////
                        MUTATIVE FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    /// @inheritdoc ITokenKeeper
    function transferFromStargateReceiver(address _account, address _token, uint256 _amount) external {
        if (msg.sender != stargateReceiver) revert Error.Unauthorized();
        if (_account == address(0)) revert Error.ZeroAddress();
        if (_token == address(0)) revert Error.ZeroAddress();
        if (_amount == 0) revert Error.ZeroAmount();

        emit BridgedTokensReceived(_account, _token, _amount);

        balances[_account][_token] += _amount;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /// @inheritdoc ITokenKeeper
    function pullToken(address _token, address _account) external returns (uint256) {
        if (msg.sender != zap) revert Error.Unauthorized();
        return _transferToken(_account, zap, _token);
    }

    /// @inheritdoc ITokenKeeper
    function withdraw(address _token) external returns (uint256) {
        return _transferToken(msg.sender, msg.sender, _token);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    ///////////////////////////////////////////////////////////////*/

    function _setZap(address _zap) internal {
        if (_zap == address(0)) revert Error.ZeroAddress();

        emit ZapSet(_zap);
        zap = _zap;
    }

    function _setStargateReceiver(address _receiver) internal {
        if (_receiver == address(0)) revert Error.ZeroAddress();

        emit StargateReceiverSet(_receiver);
        stargateReceiver = _receiver;
    }

    function _transferToken(address _from, address _to, address _token) internal returns (uint256) {
        if (_from == address(0)) revert Error.ZeroAddress();
        if (_to == address(0)) revert Error.ZeroAddress();
        if (_token == address(0)) revert Error.ZeroAddress();

        uint256 amount = balances[_from][_token];
        if (amount == 0) revert Error.ZeroAmount();

        emit TokenTransferred(_from, _to, _token, amount);
        balances[_from][_token] = 0;

        IERC20(_token).safeTransfer(_to, amount);

        return amount;
    }
}
