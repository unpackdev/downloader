// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;

import "./ERC20PausableUpgradeable.sol";
import "./Initializable.sol";
import "./TimeLockMechanism.sol";
import "./BumperAccessControl.sol";

///@title  Bumper Liquidity Provision Program (LPP) - BUSDC ERC20 Token
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021.
///@dev onlyOwner for BUSDC will be BumpMarket
contract BUSDC is
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
        address[] memory _whitelistAddresses
    ) public initializer {
        __ERC20_init(name_, symbol_);
        __ERC20Pausable_init();
        _TimeLockMechanism_init(_unlockTimestamp);
        _BumperAccessControl_init(_whitelistAddresses);
        _pause();
    }

    function pause() external whenNotPaused onlyGovernanceOrOwner {
        _pause();
    }

    function unpause() external whenPaused onlyGovernanceOrOwner {
        _unpause();
    }

    function mint(address account, uint256 amount) external virtual onlyOwner {
        _mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    ///@notice This method will be update timelock of BUSDC contract.
    ///@param _unlockTimestamp New unlock timestamp
    ///@dev The reason it is onlyGovernanceOrOwner because owner in this case will be BumpMarket.
    function updateUnlockTimestamp(uint256 _unlockTimestamp)
        external
        virtual
        onlyGovernanceOrOwner
    {
        unlockTimestamp = _unlockTimestamp;
        emit UpdateUnlockTimestamp("", msg.sender, _unlockTimestamp);
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        return super.approve(spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override timeLocked returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}
