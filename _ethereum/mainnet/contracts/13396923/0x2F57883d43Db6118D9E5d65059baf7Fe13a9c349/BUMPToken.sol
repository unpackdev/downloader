// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC20PausableUpgradeable.sol";
import "./Initializable.sol";
import "./TimeLockMechanism.sol";
import "./BumperAccessControl.sol";

///@title  Bumper Liquidity Provision Program (LPP) - BUMP ERC20 Token
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021.
///@dev onlyOwner for BUMPToken is BumpMarket
contract BUMPToken is
    Initializable,
    ERC20PausableUpgradeable,
    TimeLockMechanism,
    BumperAccessControl
{
    ///@notice Will initialize state variables of this contract
    ///@param name_- Name of ERC20 token.
    ///@param symbol_- Symbol to be used for ERC20 token.
    ///@param _unlockTimestamp- Amount of duration for which certain functions are locked
    ///@param _whitelistAddresses Array of white list addresses
    function initialize(
        string memory name_,
        string memory symbol_,
        uint256 _unlockTimestamp,
        uint256 bumpSupply,
        address[] memory _whitelistAddresses
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Pausable_init();
        _TimeLockMechanism_init(_unlockTimestamp);
        _BumperAccessControl_init(_whitelistAddresses);
        _mint(address(this), bumpSupply);
        _pause();
    }

    ///@notice This function is used by governance to pause BUMP token contract.
    function pause() external whenNotPaused onlyGovernance {
        _pause();
    }

    ///@notice This function is used by governance to un-pause BUMP token contract.
    function unpause() external whenPaused onlyGovernance {
        _unpause();
    }

    ///@notice This function is used by governance to increase supply of BUMP tokens.
    ///@param _increaseSupply Amount by which supply will increase.
    ///@dev So this basically mints new tokens in the name of protocol.
    function mint(uint256 _increaseSupply) external virtual onlyGovernance {
        _mint(address(this), _increaseSupply);
    }

    ///@notice This function updates unlockTimestamp variable
    ///@param _unlockTimestamp New deadline for lock in period
    function updateUnlockTimestamp(uint256 _unlockTimestamp)
        external
        virtual
        onlyGovernance
    {
        unlockTimestamp = _unlockTimestamp;
        emit UpdateUnlockTimestamp("", msg.sender, _unlockTimestamp);
    }

    ///@notice Called when distributing BUMP tokens from the protocol
    ///@param account- Account to which tokens are transferred
    ///@param amount- Amount of tokens transferred
    ///@dev Only governance or owner will be able to transfer these tokens
    function distributeToAddress(address account, uint256 amount)
        external
        virtual
        onlyGovernanceOrOwner
    {
        _transfer(address(this), account, amount);
    }

    ///@notice Transfers not available until after the LPP concludes
    ///@param recipient- Account to which tokens are transferred
    ///@param amount- Amount of tokens transferred
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    ///@notice Transfers not available until after the LPP concludes
    ///@param spender- Account to which tokens are approved
    ///@param amount- Amount of tokens approved
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    ///@notice Transfers not available until after the LPP concludes
    ///@param sender- Account which is transferring tokens
    ///@param recipient- Account which is receiving tokens
    ///@param amount- Amount of tokens being transferred
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override timeLocked returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}
