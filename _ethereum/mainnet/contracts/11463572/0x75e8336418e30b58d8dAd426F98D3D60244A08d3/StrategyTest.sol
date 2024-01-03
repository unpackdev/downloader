// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.6.11;

import "./StrategyBase.sol";
import "./TestToken.sol";

/* solium-disable */
contract StrategyTest is StrategyBase {
    // test helper
    uint public _depositAmount_;
    uint public _withdrawAmount_;
    bool public _harvestWasCalled_;
    bool public _exitWasCalled_;
    // simulate strategy withdrawing less than requested
    uint public _maxWithdrawAmount_ = uint(-1);
    // mock liquidity provider
    address public constant _POOL_ = address(1);

    constructor(
        address _controller,
        address _vault,
        address _underlying
    ) public StrategyBase(_controller, _vault, _underlying) {
        // allow this contract to freely withdraw from POOL
        TestToken(underlying)._approve_(_POOL_, address(this), uint(-1));
    }

    function _totalAssets() internal view override returns (uint) {
        return IERC20(underlying).balanceOf(_POOL_);
    }

    function _depositUnderlying() internal override {
        uint bal = IERC20(underlying).balanceOf(address(this));
        _depositAmount_ = bal;
        IERC20(underlying).transfer(_POOL_, bal);
    }

    function _getTotalShares() internal view override returns (uint) {
        return IERC20(underlying).balanceOf(_POOL_);
    }

    function _withdrawUnderlying(uint _shares) internal override {
        _withdrawAmount_ = _shares;

        if (_shares > _maxWithdrawAmount_) {
            _withdrawAmount_ = _maxWithdrawAmount_;
        }
        IERC20(underlying).transferFrom(_POOL_, address(this), _withdrawAmount_);
    }

    function harvest() external override onlyAuthorized {
        _harvestWasCalled_ = true;
    }

    function exit() external override onlyAuthorized {
        _exitWasCalled_ = true;
        _withdrawAll();
    }

    // test helpers
    function _setVault_(address _vault) external {
        vault = _vault;
    }

    function _setUnderlying_(address _token) external {
        underlying = _token;
    }

    function _setAsset_(address _token) external {
        assets[_token] = true;
    }

    function _mintToPool_(uint _amount) external {
        TestToken(underlying)._mint_(_POOL_, _amount);
    }

    function _setTotalDebt_(uint _debt) external {
        totalDebt = _debt;
    }

    function _setMaxWithdrawAmount_(uint _max) external {
        _maxWithdrawAmount_ = _max;
    }
}
