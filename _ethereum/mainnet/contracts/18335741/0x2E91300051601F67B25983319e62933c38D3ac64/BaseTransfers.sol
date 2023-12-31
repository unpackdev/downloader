// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "./CoreDeposit.sol";
import "./CoreWithdraw.sol";
import "./BaseAccessControl.sol";
import "./ReentrancyGuard.sol";

abstract contract BaseTransfers is CoreDeposit, CoreWithdraw, BaseAccessControl, ReentrancyGuard {
    function deposit(
        uint256[] calldata amounts,
        address[] calldata erc20Tokens
    ) external payable virtual override onlyClients nonReentrant stopGuarded {
        return _deposit(amounts, erc20Tokens);
    }

    function withdraw(
        uint256 amount,
        address erc20Token
    ) public virtual override onlyClients nonReentrant stopGuarded returns (bool) {
        return _withdraw(amount, erc20Token);
    }

    function withdrawTo(
        uint256 amount,
        address erc20Token,
        address to
    ) public virtual override onlyWhitelisted nonReentrant stopGuarded returns (bool) {
        // `to` account must be a client
        _checkRole(ROLE_CLIENT, to);

        return _withdrawTo(amount, erc20Token, to);
    }

    function withdrawAll(
        address[] calldata tokens
    ) public virtual override onlyClients nonReentrant stopGuarded returns (bool) {
        return _withdrawAll(tokens);
    }

    function withdrawAllTo(
        address[] calldata tokens,
        address to
    ) public virtual override onlyWhitelisted stopGuarded returns (bool) {
        _checkRole(ROLE_CLIENT, to);
        return _withdrawAllTo(tokens, to);
    }

    function supportsNativeAssets() public pure virtual override returns (bool) {
        return false;
    }
}
