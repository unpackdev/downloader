// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20Upgradeable.sol";
import "./ERC20PermitUpgradeable.sol";
import "./ERC20VotesUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

/**
 * @title Wrapped HIGH
 * @author HIGHTENSOR Team
 * @notice The HIGH token will release 2.8B premined HIGH
 * - The blockchain will have a total of 28B HIGH that will be mined
 * - wHIGH can be redeemed onchain at a 1:1 rate, vice versa
 * @dev This ERC20 contract acts as the interim wrapped contract and the initially premind 2.8 billion HIGH
 * - On blockchain release, this token will redeem 1:1 on the new wHIGH bridge enabled contract
 * - as well as the blockchain
 * @notice The contract will become a bridge between the Hypertensor blockchain and Ethereum
 * - thus, it is upgradeable based on token holders votes, owned by holders
 * @dev Contract owner will be the governance contract
 */
contract WrappedHIGH is Initializable, ERC20Upgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) initializer public {
        __ERC20_init("Wrapped HIGH", "wHIGH");
        __ERC20Permit_init("Wrapped HIGH");
        __ERC20Votes_init();
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        _mint(msg.sender, 2800000000 * 10 ** decimals());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable, ERC20VotesUpgradeable)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}