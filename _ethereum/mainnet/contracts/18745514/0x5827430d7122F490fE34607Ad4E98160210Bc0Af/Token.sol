// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

contract Token is AccessControl, ERC20, ERC20Burnable, ERC20Permit {
    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 public constant BLACKLISTED_ROLE = keccak256("BLACKLISTED_ROLE");

    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public constant FEE_BURN = 100;
    uint256 public constant FEE_TOTAL = 300;

    IUniswapV2Router02 public immutable uniswapV2Router;

    bool public swapAndLiquifyEnabled;

    bool private _inSwapAndLiquify;
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    constructor(address uniswapV2Router_, string memory name_, string memory symbol_) ERC20(name_, symbol_) ERC20Permit(name_) {
        uniswapV2Router = IUniswapV2Router02(uniswapV2Router_);
        address uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(WHITELISTED_ROLE, _msgSender());
        _grantRole(WHITELISTED_ROLE, address(this));
        _grantRole(WHITELISTED_ROLE, uniswapV2Pair);

        _mint(_msgSender(), 100 * 10 ** decimals());
        // _mint(_msgSender(), 210_000_000_000 * 10 ** decimals());
    }

    receive() external payable {
    }

    function setSwapAndLiquifyEnabled(bool enabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function _update(address from, address to, uint256 value) internal override {
        if (_inSwapAndLiquify) {
            return super._update(from, to, value);
        }

        require(!hasRole(BLACKLISTED_ROLE, from) && !hasRole(BLACKLISTED_ROLE, to), "Token: Blacklisted");

        if (hasRole(WHITELISTED_ROLE, from) || hasRole(WHITELISTED_ROLE, to)) {
            return super._update(from, to, value);
        }

        uint256 feeAmount = value * FEE_TOTAL / FEE_DENOMINATOR;
        super._update(from, address(this), feeAmount);

        uint256 burnAmount = value * FEE_BURN / FEE_DENOMINATOR;
        super._update(address(this), address(0), burnAmount);

        if (swapAndLiquifyEnabled && !_inSwapAndLiquify && !hasRole(WHITELISTED_ROLE, from)) {
            _swapAndLiquify();
        }

        super._update(from, to, value - feeAmount);
    }

    function _swapAndLiquify() private lockTheSwap {
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance == 0) {
            return;
        }

        _approve(address(this), address(uniswapV2Router), tokenBalance);

        uint256 halfTokenBalance = tokenBalance / 2;

        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(halfTokenBalance, 0, path, address(this), block.timestamp);

        uint256 currentBalance = address(this).balance - initialBalance;
        uniswapV2Router.addLiquidityETH{value: currentBalance}(address(this), halfTokenBalance, 0, 0, address(0), block.timestamp);
    }

    function _revokeRole(bytes32 role, address account) internal override returns (bool) {
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            require(role != WHITELISTED_ROLE && role != BLACKLISTED_ROLE, "Token: Can't revoke role");
        }
        return super._revokeRole(role, account);
    }
}