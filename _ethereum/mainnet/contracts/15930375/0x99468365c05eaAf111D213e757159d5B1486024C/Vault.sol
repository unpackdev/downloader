// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import "./ITokenDecimals.sol";
import "./ITokenBurn.sol";
import "./VaultBase.sol";
import "./AssetSpenderRole.sol";
import "./MultichainRouterRole.sol";
import "./BalanceManagement.sol";


contract Vault is VaultBase, AssetSpenderRole, MultichainRouterRole, BalanceManagement {

    error TokenDecimalsError();
    error TokenNotSetError();
    error TokenNotEnabledError();

    address public immutable underlying; // Anyswap ERC20 standard

    address public variableToken;
    bool public variableTokenEnabled;

    event SetVariableToken(address indexed variableToken);
    event SetVariableTokenEnabled(bool indexed isEnabled);
    event RedeemVariableToken(address indexed caller, uint256 amount);

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol,
        address[] memory _assetSpenders,
        bool _depositAllowed,
        address _ownerAddress,
        bool _grantManagerRoleToOwner
    )
        VaultBase(
            _asset,
            _name,
            _symbol,
            _depositAllowed
        )
    {
        underlying = address(0);

        for (uint256 index; index < _assetSpenders.length; index++) {
            _setAssetSpender(_assetSpenders[index], true);
        }

        _initRoles(_ownerAddress, _grantManagerRoleToOwner);
    }

    function setAssetSpender(address _assetSpender, bool _value) external onlyManager {
        _setAssetSpender(_assetSpender, _value);
    }

    function setMultichainRouter(address _account, bool _value) external onlyManager {
        _setMultichainRouter(_account, _value);
    }

    function setVariableToken(address _variableToken, bool _isEnabled) external onlyManager {
        // Zero address is allowed
        if (
            _variableToken != address(0) &&
            ITokenDecimals(_variableToken).decimals() != decimals
        ) {
            revert TokenDecimalsError();
        }

        variableToken = _variableToken;

        emit SetVariableToken(_variableToken);

        _setVariableTokenEnabled(_isEnabled);
    }

    function setVariableTokenEnabled(bool _isEnabled) external onlyManager {
        _setVariableTokenEnabled(_isEnabled);
    }

    function mint(address _to, uint256 _amount) external onlyMultichainRouter returns (bool) {
        _mint(_to, _amount);

        return true;
    }

    function burn(address _from, uint256 _amount) external onlyMultichainRouter returns (bool) {
        _burn(_from, _amount);

        return true;
    }

    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableToken
    )
        external
        onlyAssetSpender
        whenNotPaused
        returns (address assetAddress)
    {
        if (_forVariableToken && !variableTokenEnabled) {
            revert TokenNotEnabledError();
        }

        safeTransfer(asset, _to, _amount);

        return asset;
    }

    function redeemVariableToken(uint256 _amount) external whenNotPaused {
        if (variableToken == address(0)) {
            revert TokenNotSetError();
        }

        if (!variableTokenEnabled) {
            revert TokenNotEnabledError();
        }

        ITokenBurn(variableToken).burn(msg.sender, _amount);

        emit RedeemVariableToken(msg.sender, _amount);

        safeTransfer(asset, msg.sender, _amount);
    }

    function isReservedToken(address _tokenAddress) public view override returns (bool) {
        return _tokenAddress == asset;
    }

    function _setVariableTokenEnabled(bool _isEnabled) private {
        variableTokenEnabled = _isEnabled;

        emit SetVariableTokenEnabled(_isEnabled);
    }

    function _initRoles(address _ownerAddress, bool _grantManagerRoleToOwner) private {
        address ownerAddress =
            _ownerAddress == address(0) ?
                msg.sender :
                _ownerAddress;

        if (_grantManagerRoleToOwner) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}