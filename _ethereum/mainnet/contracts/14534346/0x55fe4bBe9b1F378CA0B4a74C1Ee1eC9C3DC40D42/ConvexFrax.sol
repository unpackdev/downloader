/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.2;
pragma experimental ABIEncoderV2;


import "./IBooster.sol";
import "./ICurveFi.sol";
import "./IRewards.sol";
import "./IUni.sol";
import "./Math.sol";
import "./ConvexCrvLp.sol";
import "./IERC20Upgradeable.sol";
import "./Initializable.sol";
import "./SafeERC20Upgradeable.sol";


contract ConvexFraxStrategy is ConvexCrvLp, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public constant dai = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    address public constant usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant usdt = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public constant crv3 = address(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    address public constant frax3crv = address(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B);
    address public constant zapCurve = address(0xA79828DF1850E8a3A3064576f380D90aECDD3359);

    address[] public pathTarget;

    function initialize(
        address _vault
    ) external initializer {
        BaseStrategy._initialize(_vault);

        slippage_factor = 150;
        minReportDelay = 1 days;
        maxReportDelay = 30 days;
        profitFactor = 100000;
        debtThreshold = 1e24;
        want_wrapped = IERC20Upgradeable(frax3crv);
        want_wrapped.safeApprove(_vault, type(uint256).max); // Give Vault unlimited access (might save gas)

        if (address(want) == dai) {
            curve_lp_idx = 0;
        } else if (address(want) == usdc) {
            curve_lp_idx = 1;
        } else if (address(want) == usdt) {
            curve_lp_idx = 2;
        } else {
            revert("Strategy cant be applied to this vault");
        }

        curve = frax3crv;
        id = 32;
        isClaimRewards = true; // default is true, turn off in emergency
        // isClaimExtras = true; // add this if there are extra rewards

        (address _lp,,,address _reward,,) = Booster(booster).poolInfo(id);
        require(_lp == address(want_wrapped), "constructor: incorrect lp token");
        rewardContract = _reward;

        _approveBasic();
        pathTarget = new address[](2);
        _setPathTarget(0, 1); // crv path target
        _setPathTarget(1, 1); // cvx path target

        dex = new address[](2);
        dex[0] = sushiswap; // crv
        dex[1] = sushiswap; // cvx
        _approveDex();
    }

    function _approveBasic() internal override {
        want_wrapped.safeApprove(booster, 0);
        want_wrapped.safeApprove(booster, type(uint256).max);
        want_wrapped.safeApprove(zapCurve, 0);
        want_wrapped.safeApprove(zapCurve, type(uint256).max);
        IERC20Upgradeable(dai).safeApprove(zapCurve, 0);
        IERC20Upgradeable(dai).safeApprove(zapCurve, type(uint256).max);
        IERC20Upgradeable(usdc).safeApprove(zapCurve, 0);
        IERC20Upgradeable(usdc).safeApprove(zapCurve, type(uint256).max);
        IERC20Upgradeable(usdt).safeApprove(zapCurve, 0);
        IERC20Upgradeable(usdt).safeApprove(zapCurve, type(uint256).max);
    }

    function _approveDex() internal override {
        IERC20Upgradeable(crv).safeApprove(dex[0], 0);
        IERC20Upgradeable(crv).safeApprove(dex[0], type(uint256).max);
        IERC20Upgradeable(cvx).safeApprove(dex[1], 0);
        IERC20Upgradeable(cvx).safeApprove(dex[1], type(uint256).max);
    }

    function calc_want_from_wrapped(uint256 wrapped_amount) public view override returns (uint256 expected_return) {
        if (wrapped_amount > 0) {
            expected_return = ICurveFi(zapCurve).calc_withdraw_one_coin(curve, wrapped_amount, int128(curve_lp_idx) + 1);
        }
    }

    function calc_wrapped_from_want(uint256 want_amount) public view override returns (uint256) {
        uint256[4] memory amounts;
        amounts[curve_lp_idx + 1] = want_amount;
        return ICurveFi(zapCurve).calc_token_amount(curve, amounts, true);
    }

    function wrap(uint256 want_amount) internal override returns (uint256 expected_return) {
        if (want_amount > 0) {
            expected_return = calc_wrapped_from_want(want_amount);
            uint256[4] memory amounts;
            amounts[curve_lp_idx + 1] = want_amount;
            ICurveFi(zapCurve).add_liquidity(curve, amounts, 0);
        }
    }

    function unwrap(uint256 wrapped_amount) internal override returns (uint256 expected_return) {
        if (wrapped_amount > 0) {
            expected_return = calc_want_from_wrapped(wrapped_amount);
            ICurveFi(zapCurve).remove_liquidity_one_coin(curve, wrapped_amount, int128(curve_lp_idx) + 1, 0);
        }
    }


    // >>> approve other rewards on dex
    // function _approveDex() internal override { super._approveDex(); }

    // >>> include other rewards
    // function _migrateRewards(address _newStrategy) internal override { super._migrateRewards(_newStrategy); }

    // >>> include all other rewards in eth besides _claimableBasicInETH()
    // function _claimableInETH() internal override view returns (uint256 _claimable) { _claimable = super._claimableInETH(); }

    function _setPathTarget(uint _tokenId, uint _id) internal {
        if (_id == 0) {
            pathTarget[_tokenId] = dai;
        }
        else if (_id == 1) {
            pathTarget[_tokenId] = usdc;
        }
        else {
            pathTarget[_tokenId] = usdt;
        }
    }

    function setPathTarget(uint _tokenId, uint _id) external onlyAuthorized {
        _setPathTarget(_tokenId, _id);
    }

    function prepareReturn(uint256 _debtOutstanding)
    internal
    override
    returns (
        uint256 _profit,
        uint256 _loss,
        uint256 _debtPayment
    )
    {
        // here some 'want' token could be free
        // we dont want it to be taken into account as profit
        uint before = balanceOfWrapped() + calc_wrapped_from_want(balanceOfWant());

        Rewards(rewardContract).getReward(address(this), isClaimExtras);
        uint256 _crv = IERC20Upgradeable(crv).balanceOf(address(this));
        if (_crv > 0) {
            address[] memory path = new address[](3);
            path[0] = crv;
            path[1] = weth;
            path[2] = pathTarget[0];

            Uni(dex[0]).swapExactTokensForTokens(_crv, uint256(0), path, address(this), block.timestamp);
        }
        uint256 _cvx = IERC20Upgradeable(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            address[] memory path = new address[](3);
            path[0] = cvx;
            path[1] = weth;
            path[2] = pathTarget[1];

            Uni(dex[1]).swapExactTokensForTokens(_cvx, uint256(0), path, address(this), block.timestamp);
        }
        uint256 _dai = IERC20Upgradeable(dai).balanceOf(address(this));
        uint256 _usdc = IERC20Upgradeable(usdc).balanceOf(address(this));
        uint256 _usdt = IERC20Upgradeable(usdt).balanceOf(address(this));
        if (_dai > 0 || _usdc > 0 || _usdt > 0) {
            ICurveFi(zapCurve).add_liquidity(curve, [0, _dai, _usdc, _usdt], 0);
        }
        _profit = balanceOfWrapped() - before;

        uint _total = estimatedTotalWrappedAssets();
        uint _debt = calc_wrapped_from_want(vault.strategies(address(this)).totalDebt);
        if (_total < _debt) {
            _loss = _debt - _total;
            _profit = 0;
        }

        if (_debtOutstanding > 0) {
            _withdrawSome(_debtOutstanding);
            _debtPayment = Math.min(_debtOutstanding, balanceOfWrapped() - _profit);
        }
    }
}