// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IERC20.sol";
import "./Initializable.sol";
import "./ERC20VotesUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Ownable.sol";

contract XVader is
    Initializable,
    ERC20VotesUpgradeable,
    ReentrancyGuardUpgradeable,
    Ownable
{
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable vader;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IERC20 _vader) {
        require(_vader != IERC20(address(0)), "vader = zero address");
        vader = _vader;
    }

    function initialize() external initializer {
        owner = msg.sender;

        __ReentrancyGuard_init();
        __ERC20_init("xVADER", "xVADER");
        __ERC20Permit_init("xVADER");
    }

    // Locks vader and mints xVader
    function enter(uint _amount) external nonReentrant {
        // Gets the amount of vader locked in the contract
        uint totalVader = vader.balanceOf(address(this));
        // Gets the amount of xVader in existence
        uint totalShares = totalSupply();

        // If no xVader exists, mint it 1:1 to the amount put in.
        // Calculate and mint the amount of xVader the vader is worth.
        // The ratio will change overtime, as xVader is burned/minted and
        // vader deposited + gained from fees / withdrawn.
        uint xVADERToMint = totalShares == 0 || totalVader == 0
            ? _amount
            : (_amount * totalShares) / totalVader;

        _mint(msg.sender, xVADERToMint);

        // Lock the vader in the contract
        vader.transferFrom(msg.sender, address(this), _amount);
    }

    // Claim back your VADER
    // Unlocks the staked + gained vader and burns xVader
    function leave(uint _shares) external nonReentrant {
        // Calculates the amount of vader the xVader is worth
        uint vaderAmount = (_shares * vader.balanceOf(address(this))) / totalSupply();

        _burn(msg.sender, _shares);
        vader.transfer(msg.sender, vaderAmount);
    }
}
