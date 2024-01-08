// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IUniswapV3Pool.sol";

import "./IUniversalVault.sol";

// @title Hypervisor
// @notice A Uniswap V2-like interface with fungible liquidity to Uniswap V3
// which allows for arbitrary liquidity provision: one-sided, lop-sided, and
// balanced
contract Hypervisor is ERC20 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public visr;
    address public owner;

    // @param _pool Uniswap V3 pool for which liquidity is managed
    // @param _owner Owner of the Hypervisor
    constructor(
        address _visr,
        address _owner
    ) ERC20("Reward Visor", "RVISR") {
        owner = _owner;
        visr = IERC20(_visr);
    }

    // @param visr Amount of VISR transfered from sender to Hypervisor
    // @param to Address to which liquidity tokens are minted
    // @param from Address from which tokens are transferred 
    // @return shares Quantity of liquidity tokens minted as a result of deposit
    function deposit(
        uint256 visrDeposit,
        address from,
        address to
    ) external returns (uint256 shares) {
        require(visrDeposit > 0, "deposits must be nonzero");
        require(to != address(0) && to != address(this), "to");
        require(from != address(0) && from != address(this), "from");

        visr.safeTransferFrom(from, address(this), visrDeposit);

        shares = totalSupply() == 0 ? visrDeposit : visrDeposit ;
        if (totalSupply() != 0) {
          uint256 visrBalance = visr.balanceOf(address(this));
          shares = shares.mul(totalSupply()).div(visrBalance);
        }
        _mint(to, shares);
    }

    // @param shares Number of rewards shares to redeem for VISR
    // @param to Address to which redeemed pool assets are sent
    // @param from Address from which liquidity tokens are sent
    // @return rewards Amount of visr redeemed by the submitted liquidity tokens
    function withdraw(
        uint256 shares,
        address to,
        address from
    ) external returns (uint256 rewards) {
        require(shares > 0, "shares");
        require(to != address(0), "to");

        rewards = visr.balanceOf(address(this)).mul(shares).div(totalSupply());
        visr.safeTransfer(to, rewards);

        require(from == msg.sender || IUniversalVault(from).owner() == msg.sender, "Sender must own the tokens");
        _burn(from, shares);
    }

    function emergencyWithdraw(IERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}
