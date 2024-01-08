//SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./IStrat.sol";
import "./IArchiBankToken.sol";
import "./IVault.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

contract ArchiBankStrat is IStrat {
    
    using SafeERC20 for IERC20;
    IVault public vault;
    IArchiBankToken public abToken;
    IERC20 public underlying;

    constructor(IVault vault_, IArchiBankToken abToken_) {
        vault = vault_;
        abToken = abToken_;
        underlying = IERC20(abToken_.underlying());
        underlying.safeApprove(address(abToken), uint(-1));
    }

    function invest() external override onlyVault {
        uint balance = underlying.balanceOf(address(this));
        require(balance > 0, "ArchiBankStrat: BALANCE_LESSTHANEQUAL_ZERO");
        require(abToken.mint(balance) == 0, "ArchiBankStrat: FAIL_MINT");
    }

    function divest(uint amount) external override onlyVault {
        require(abToken.redeemUnderlying(amount) == 0, "ArchiBankStrat: FAIL_REDEEM");
        underlying.safeTransfer(address(vault), amount);
    }

    function calcTotalValue() external override returns (uint) {
        return abToken.balanceOfUnderlying(address(this));
    }

    function sweep(address _token) external {
        address owner = vault.owner();
        require(msg.sender == owner, "ArchiBankStrat: ONLY_OWNER");
        require(_token != address(abToken));
        IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this)));
    }

    modifier onlyVault {
        require(msg.sender == address(vault));
        _;
    }
}