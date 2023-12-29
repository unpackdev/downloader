// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

pragma solidity ^0.8.10;

import "./IStrategy.sol";
import "./IAuraRouter.sol";
import "./IAuraVirtualVault.sol";
import "./OperableKeepable.sol";
import "./Errors.sol";
import "./FixedPointMathLib.sol";
import "./IERC20.sol";

contract AuraVirtualVault is IAuraVirtualVault, OperableKeepable {
    using FixedPointMathLib for uint256;

    IAuraRouter public router;
    IStrategy public strategy;
    IERC20 public constant AURA = IERC20(0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF);
    address public incentiveReceiver;

    mapping(address => uint256) public virtualShares;

    uint256 public totalSupply;

    event Deposit(address indexed receiver, uint256 assets);
    event Withdraw(address indexed receiver, uint256 assets);

    constructor() Governable(msg.sender) {}

    // Operator functions
    function deposit(address receiver, uint256 assets) external onlyOperator returns (uint256 shares) {
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }

        shares = previewDeposit(assets);

        _mintVirtual(receiver, shares);

        emit Deposit(receiver, assets);
    }

    function withdraw(address receiver, uint256 assets) external onlyOperator {
        uint256 shares = previewWithdraw(assets);
        uint256 userShares = virtualShares[receiver];

        if (shares > userShares) {
            revert Errors.InsufficientAssets();
        }

        _burnVirtual(receiver, shares);

        emit Withdraw(receiver, assets);
    }

    function mint(uint256 _shares, address _to) public onlyOperator {
        _mintVirtual(_to, _shares);
    }

    function burn(address _user, uint256 _shares) public onlyOperator {
        uint256 userShares = virtualShares[_user];

        if (_shares > userShares) {
            revert Errors.InsufficientAssets();
        }

        _burnVirtual(_user, _shares);
    }

    // Private functions
    function _mintVirtual(address _to, uint256 _shares) private {
        if (_to == address(0)) {
            revert Errors.ZeroAddress();
        }

        unchecked {
            totalSupply += _shares;
            virtualShares[_to] += _shares;
        }
    }

    function _burnVirtual(address _user, uint256 _shares) private {
        if (_user == address(0)) {
            revert Errors.ZeroAddress();
        }

        if (_shares > virtualShares[_user]) {
            revert Errors.InsufficientShares();
        }

        unchecked {
            virtualShares[_user] -= _shares;
            totalSupply -= _shares;
        }
    }

    // Public view functions
    function convertToShares(uint256 _assets) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? _assets : _assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 _shares) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? _shares : _shares.mulDivDown(totalAssets(), supply);
    }

    function previewRedeem(uint256 _shares) public view returns (uint256) {
        return convertToAssets(_shares);
    }

    function previewDeposit(uint256 _assets) public view returns (uint256) {
        return convertToShares(_assets);
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function totalAssets() public view returns (uint256) {
        (uint256 assets,) = strategy.vaultsPosition();
        return assets - router.totalWithdrawRequestsNoTokenized();
    }

    // Gov functions
    function setRouter(address _router) external onlyGovernor {
        if (_router == address(0)) {
            revert Errors.ZeroAddress();
        }
        router = IAuraRouter(_router);
    }

    function setStrategy(address _strategy) external onlyGovernor {
        if (_strategy == address(0)) {
            revert Errors.ZeroAddress();
        }
        strategy = IStrategy(_strategy);
    }

    function setReceiver(address _receiver) external onlyGovernor {
        if (_receiver == address(0)) {
            revert Errors.ZeroAddress();
        }
        incentiveReceiver = _receiver;
    }
}
