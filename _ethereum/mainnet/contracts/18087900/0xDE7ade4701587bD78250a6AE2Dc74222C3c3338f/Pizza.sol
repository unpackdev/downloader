// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";
import "./ERC20.sol";
import "./Pausable.sol";
import "./Blacklistable.sol";
import "./ReentrancyGuard.sol";
import "./Rescuable.sol";
import "./SafeERC20.sol";

/**
 * @title Pizza Token
 * @dev ERC20 token with pausable, blacklistable, and rescuable features.
 * @notice Major powers are separated amongst the roles in the Pizza token
 *
 * Owner: Can change ownership and update contract roles.
 *   Power: can transfer Ownership, update Pauser, Rescuer, Blacklister, and MasterMinter.
 *
 * Pauser: Can pause and unpause the contract.
 *   Power: Pause and Unpause. Pausing restricts all non-view functions in the Pizza contract.
 *
 * Rescuer: Can rescue ERC20 tokens accidentally sent to the contract.
 *   Power: Rescue Funds. 
            Rescue rights not affected by pauses.
 *
 * Blacklister: Can manage the blacklist and restrict certain functions.
 *   Power: Add to and Remove from Blacklist.
 *          Blacklisted addresses face restricted functionalities.
 *          Blacklisting rights are not affected by pauses.
 *
 * Master Minter: Controls minting-related operations and configuration.
 *   Power: Issue and Redeem tokens. Configure and manage minters.
 *   The Master minter has the exclusive authority to add, update, and remove minters.
 *   Constraint: Minting and burning can only be performed by the masterMinter. 
 *   Minters' operations are subject to the allowance set by the masterMinter.
 */

contract Pizza is Pausable, Blacklistable, Rescuable, ReentrancyGuard, ERC20 {
    constructor() ERC20("Pizza", "PIZZA") {
        masterMinter = address(msg.sender);
    }

    address public masterMinter;
    /** @notice array of all minter address */
    address[] public minterAddresses;
    /** @notice mapping to check if a given address is a minter */
    mapping(address => bool) public minters;
    /** @notice mapping of minter to its allowance */
    mapping(address => uint256) public minterAllowance;
    /** @notice mapping of minter to allowance already used */
    mapping(address => uint256) public minterUsedAllowance;

    event Issued(uint256 amount);
    event Redeemed(uint256 amount);
    event MintedByMinter(uint256 amount, address minter);
    event BurnedByMinter(uint256 amount, address minter);
    event MasterMinterChanged(address indexed newMasterMinter);
    event MinterConfigured(
        address indexed minter,
        uint256 minterAllowanceAmount
    );
    event MinterRemoved(address minter);
    event DestroyedBlackFunds(
        address indexed blackListedUser,
        uint256 dirtyFunds
    );

    /**
     * @dev Throws if called by any account other than a minter
     */
    modifier onlyMinters() {
        require(minters[msg.sender], "Pizza: caller is not a minter");
        _;
    }

    /**
     * @dev Throws if called by any account other than the masterMinter
     */
    modifier onlyMasterMinter() {
        require(
            msg.sender == masterMinter,
            "Pizza: caller is not the masterMinter"
        );
        _;
    }

    /// @dev checks if it is on the minterAddresses array

    function isMinter(address minter) public view returns (bool) {
        for (uint i = 0; i < minterAddresses.length; i++) {
            if (minterAddresses[i] == minter) {
                return true;
            }
        }
        return false;
    }

    function allMinters() public view returns (address[] memory) {
        return minterAddresses;
    }

    function transfer(
        address _to,
        uint256 _value
    )
        public
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(_to)
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        override
        whenNotPaused
        notBlacklisted(_from)
        notBlacklisted(_to)
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }

    /** @dev Issues a new amount of tokens.
     * These tokens are deposted into the owner address.
     * Only the masterMinter call this function.
     * Issue amount is unlimited.
     */

    function issue(
        uint256 amount
    ) public onlyMasterMinter whenNotPaused notBlacklisted(msg.sender) {
        require(
            totalSupply() + amount > totalSupply(),
            "issuing negative amount to total supply"
        );

        require(
            balanceOf(masterMinter) + amount > balanceOf(masterMinter),
            "issuing negative amount to owner"
        );

        _mint(masterMinter, amount);
        emit Issued(amount);
    }

    /** @dev Redeems an amount of tokens.
     * These tokens are withdrawn from the owner address,
     * which means the tokens must be deposited from the owner address before hand.
     * Only the masterMinter call this function.
     * The redemption amount must be covered by the balance in the owern address
     * or the call will fail.
     */

    function redeem(
        uint256 amount
    ) public onlyMasterMinter whenNotPaused notBlacklisted(msg.sender) {
        require(totalSupply() >= amount);
        require(balanceOf(masterMinter) >= amount);
        _burn(masterMinter, amount);
        emit Redeemed(amount);
    }

    /**
     * @notice Mint new tokens by an authorized minter.
     * MasterMinter may not call this function as masterMinter cannot be added to the list of minters
     * @param to Recipient address for minted tokens.
     * @param amount Amount of tokens to mint.
     * Requirements: Authorized minter, contract not paused, recipient not blacklisting.
     * Emits a MintedByMinter event.
     */
    function mintByMinter(
        address to,
        uint256 amount
    )
        public
        nonReentrant
        onlyMinters
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(to)
    {
        uint256 allowance = minterAllowance[msg.sender];
        uint256 usedAllowance = minterUsedAllowance[msg.sender];
        require(usedAllowance + amount < allowance, "Insufficient allowance");
        require(
            totalSupply() + amount > totalSupply(),
            "issuing negative amount to total supply"
        );
        require(
            balanceOf(to) + amount > balanceOf(to),
            "issuing negative amount to owner"
        );
        _mint(to, amount);
        minterUsedAllowance[msg.sender] += amount;
        emit MintedByMinter(amount, to);
    }

    /**
     * @notice Redeems tokens by an authorized minter.
     * MasterMinter may not call this function as masterMinter cannot be added to the list of minters
     * @param from source address for tokens to be redeemed.
     * @param amount Amount of tokens to be redeemed.
     * Requirements: Authorized minter, contract not paused, recipient not blacklisting.
     * Emits a BurnedByMinter event.

     */

    function burnByMinter(
        address from,
        uint256 amount
    )
        public
        nonReentrant
        onlyMinters
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(from)
    {
        require(totalSupply() >= amount);
        require(balanceOf(from) >= amount);
        _burn(from, amount);
        uint256 usedAllowance = minterUsedAllowance[msg.sender];
        if (usedAllowance < amount) {
            delete minterUsedAllowance[msg.sender];
        } else {
            minterUsedAllowance[msg.sender] -= amount;
        }
        emit BurnedByMinter(amount, from);
    }

    /**
     * @dev Updates the address of the masterMinter role.
     * Only the contract owner can update the masterMinter address.
     * @param _newMasterMinter The new address to be set as the masterMinter.
     * The new address cannot be the zero address and must not be blacklisted.
     * Emits a MasterMinterChanged event.
     */
    function updateMasterMinter(
        address _newMasterMinter
    ) external whenNotPaused onlyOwner notBlacklisted(_newMasterMinter) {
        require(
            _newMasterMinter != address(0),
            "Pizza: new masterMinter is the zero address"
        );
        masterMinter = _newMasterMinter;
        emit MasterMinterChanged(masterMinter);
    }

    /**
     * @dev Function to add a new minter or to update the allowance of a minter
     * @param minter The address of the minter
     * @param minterAllowanceAmount The minting amount allowed for the minter
     * @return True if the operation was successful.
     */
    function configureMinter(
        address minter,
        uint256 minterAllowanceAmount
    ) external whenNotPaused onlyMasterMinter returns (bool) {
        require(minter != masterMinter, "trying to add masterMinter");
        minters[minter] = true;
        minterAllowance[minter] = minterAllowanceAmount;
        minterAddresses.push(minter);
        emit MinterConfigured(minter, minterAllowanceAmount);
        return true;
    }

    /**
     * @dev Removes a minter from the list of authorized minters.
     * Only the masterMinter can call this function to remove a minter.
     * @param minter The address of the minter to be removed.
     * @return A boolean indicating the success of the operation.
     * Requirements: Caller must be the masterMinter, contract not paused,
     * the minter address cannot be the zero address, and the minter cannot be the contract owner.
     * Emits a MinterRemoved event.
     */
    function removeMinter(
        address minter
    ) external whenNotPaused onlyMasterMinter returns (bool) {
        require(minter != address(0), "Zero address!");
        require(minter != owner(), "You cannot remove the owner!");
        require(isMinter(minter), "Address not on list of minter addresses!");
        // deleting value from mapping
        delete minters[minter];
        delete minterAllowance[minter];
        delete minterUsedAllowance[minter];

        // Find and remove the minter from the list of minter addresses
        for (uint256 i = 0; i < minterAddresses.length; i++) {
            // if the programme finds a slot in the array whose entry is the minter
            // it replaces it with the last element in the array
            if (minterAddresses[i] == minter) {
                minterAddresses[i] = minterAddresses[
                    minterAddresses.length - 1
                ];
                minterAddresses.pop();
                break;
            }
        }
        emit MinterRemoved(minter);
        return true;
    }

    /**
     * @dev this function destroys the balance of a blacklisted address.
     * The function is callable only by the masterMinter and not the blacklister
     * This is to concentrate the rights concerning supply change in the hands of the masterMinter
     * And to deprive the blacklister of independent and unchecked fund destruction powers
     */
    function destroyBlackFunds(
        address _blackListedUser
    ) public onlyMasterMinter {
        require(isBlacklisted[_blackListedUser], "user is not blacklisted!");
        uint256 dirtyFunds = balanceOf(_blackListedUser);
        _burn(_blackListedUser, dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
}
