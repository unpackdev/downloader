// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

import "./IVault.sol";
import "./IUniversalVault.sol";

interface IVisor {
    function delegatedTransferERC20(address token, address to, uint256 amount) external;
}

contract Extract {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IVault public hypervisor;
    address payable public owner;
    uint256 public bonus;
    IERC20 public bonusToken;

    constructor(
        address _hypervisor,
        address _bonusToken,
        address payable _owner
    ) {
        hypervisor = IVault(_hypervisor);
        bonusToken = IERC20(_bonusToken);
        owner = _owner;
    }

    function extractTokens(
        uint256 shares,
        address to,
        address from
    ) external {
        require(IUniversalVault(from).owner() == msg.sender, "Sender must own the tokens");
        IVisor(from).delegatedTransferERC20(address(hypervisor), address(this), shares);
        uint256 withdrawShares = shares.div(2);
        IVault(hypervisor).withdraw(withdrawShares, to, address(this));
        bonusToken.safeTransfer(to, bonus.mul(shares).div(IERC20(address(hypervisor)).totalSupply()));
    }

    function setBonus(uint256 _bonus) external onlyOwner {
        bonus = _bonus;
    }

    function sweepTokens(address token) external onlyOwner {
      IERC20(token).transfer(owner, IERC20(token).balanceOf(address(this)));
    }

    function sweepEth() external onlyOwner {
      owner.transfer(address(this).balance);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }
}
