// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @author thirdweb

import "./ERC20Permit.sol";
import "./ContractMetadata.sol";
import "./Multicall.sol";
import "./Ownable.sol";
import "./IBurnableERC20.sol";

contract ERC20LockableToken is ContractMetadata, Multicall, Ownable, ERC20Permit, IBurnableERC20 {
    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _defaultAdmin,
        uint256 _amount,
        string memory _name,
        string memory _symbol
    ) ERC20Permit(_name, _symbol) {
        _setupOwner(_defaultAdmin);
        _mint(msg.sender, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                        Lock Token
    //////////////////////////////////////////////////////////////*/

    mapping (address => uint256) private _lockTimes;
    mapping (address => uint256) private _lockAmounts;

    event LockChanged(address indexed account, uint256 releaseTime, uint256 amount);

    function setLock(address account, uint256 releaseTime, uint256 amount) public {
        require(_canLock(), "Not authorized to lock.");
        _lockTimes[account] = releaseTime;
        _lockAmounts[account] = amount;
        emit LockChanged(account, releaseTime, amount);
    }

    function getLock(address account) public view returns (uint256 lockTime, uint256 lockAmount) {
        return (_lockTimes[account], _lockAmounts[account]);
    }

    function _isLocked(address account, uint256 amount) internal view returns (bool) {
        return _lockTimes[account] != 0 &&
            _lockAmounts[account] != 0 &&
            _lockTimes[account] > block.timestamp &&
            (
                balanceOf(account) <= _lockAmounts[account] ||
                balanceOf(account) - _lockAmounts[account] < amount
            );
    }

    function _beforeTokenTransfer(
        address from,
        address,
        uint256 amount
    ) override internal virtual {
        require(!_isLocked(from, amount), "Locked balance");
    }

    /**
     *  @notice          Lets an owner a given amount of their tokens.
     *  @dev             Caller should own the `_amount` of tokens.
     *
     *  @param _amount   The number of tokens to burn.
     */
    function burn(uint256 _amount) external virtual {
        require(balanceOf(msg.sender) >= _amount, "not enough balance");
        _burn(msg.sender, _amount);
    }

    /**
     *  @notice          Lets an owner burn a given amount of an account's tokens.
     *  @dev             `_account` should own the `_amount` of tokens.
     *
     *  @param _account  The account to burn tokens from.
     *  @param _amount   The number of tokens to burn.
     */
    function burnFrom(address _account, uint256 _amount) external virtual override {
        require(_canBurn(), "Not authorized to burn.");
        require(balanceOf(_account) >= _amount, "not enough balance");
        uint256 decreasedAllowance = allowance(_account, msg.sender) - _amount;
        _approve(_account, msg.sender, 0);
        _approve(_account, msg.sender, decreasedAllowance);
        _burn(_account, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether tokens can be locked in the given execution context.
    function _canLock() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether tokens can be burned in the given execution context.
    function _canBurn() internal view virtual returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }
}
