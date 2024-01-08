// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

contract AncientGold is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    address public battleGround;

    function initialize() public initializer {
        __ERC20_init("Ancient Gold", "$AGOLD");
        __ERC20Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(address(this), 5000000000 * 10**decimals());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function setBattleGround(address contract_) external onlyOwner {
        battleGround = contract_;
    }

    function bgTransfer(address to_, uint256 amount_) external {
        require(msg.sender == battleGround, "GAD-20-E1");

        _transfer(address(this), to_, amount_);
    }
}
