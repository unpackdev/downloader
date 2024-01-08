// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.0;

import "./ERC20PausableUpgradeable.sol";
import "./Initializable.sol";
import "./TimeLockMechanism.sol";
import "./BumperAccessControl.sol";
import "./IBumpMarket.sol";

///@title  Bumper Liquidity Provision Program (LPP) - bUSDC ERC20 Token
///@notice This suite of contracts is intended to be replaced with the Bumper 1b launch in Q4 2021.
///@dev onlyOwner for BUSDC will be BumpMarket
contract BUSDCV2 is
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

    ///@dev This function is modified in version 2.
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        require(
            recipient == owner(),
            "bUSDC can only be transferred to Bump Market"
        );
        return IBumpMarket(owner()).withdrawLiquidity(msg.sender, amount);
    }

    ///@dev This function is modified in version 2.
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        timeLocked
        returns (bool)
    {
        require(
            spender == owner(),
            "bUSDC can only be approved to Bump Market"
        );
        return super.approve(spender, amount);
    }

    ///@dev This function is modified in version 2.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override timeLocked returns (bool) {
        require(
            recipient == owner(),
            "bUSDC can only be transferred to Bump Market"
        );
        return super.transferFrom(sender, recipient, amount);
    }

    ///@notice This method is used to burn bUSDC tokens form user address.
    ///@dev This method is called from BumpMarket contract.
    ///@dev This function is added in Version 2.
    ///@param account Address whose bUSDC tokens need to be burnt.
    ///@param amount Number of bUSDC tokens user wants to burn.
    function burn(address account, uint256 amount) public virtual onlyOwner {
        _burn(account, amount);
    }
}
