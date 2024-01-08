// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IVesting.sol";

interface IVestingFactory {
    /**
     * @dev Emitted when new vesting add or create
     *
     * @param sender - is the account that add/create vesting
     * @param vesting - is the address of vesting which was add or created
     * @param isPrivate - is the type of vesting which was add or created
     */
    event AddVesting(address indexed sender, address vesting, bool isPrivate);

    /**
     * @dev Emitted when vesting remove from register
     *
     * @param sender - is the account that remove vesting
     * @param vesting - is the address of vesting which was removed
     */
    event RemoveVesting(address indexed sender, address vesting);

    /**
     *  @notice add new account to whitelist, can be invoked only by Owner
     *  @dev grant role CREATOR to the account
     *  @param _account - address to be granted role
     */
    function addCreator(address _account) external;

    /**
     *  @notice remove account from the whitelist, can be invoked only by Owner
     *  @dev revoke role CREATOR from the account, checked ownership in revokeRole
     *  @param _account - address to be revoked role
     */
    function removeCreator(address _account) external;

    /**
     *  @notice set new implementation, can be invoked only by Owner
     *  @dev set new implementation of Vesting for the factory
     *  @param _vestingImplementation - addresses of new implementation
     */
    function setVestingImplementation(address _vestingImplementation) external;

    /**
     *  @notice Create a new vesting.
     *  @dev create a new proxy of Vesting.
     *  @param _name - name of the vesting which will be created
     *  @param _rewardToken - the token address that will be used to issue rewards to users
     *  @param _depositToken - the token address that will be used for users to pay
     *  @param _signer - addresses which will sign transactions on deposit
     *  @param _initialUnlockPercentage - the percentage of tokens that will be unlocked after the sale
     *  @param _minAllocation - the minimum number for which the user can purchase tokens
     *  @param _maxAllocation - the maximum number for which the user can purchase tokens
     *  @param _vestingType - vesting unlock type
     *  @return proxy Address of recently created Vesting.
     */
    function createVesting(
        string memory _name,
        address _rewardToken,
        address _depositToken,
        address _signer,
        uint256 _initialUnlockPercentage,
        uint256 _minAllocation,
        uint256 _maxAllocation,
        IVesting.VestingType _vestingType
    ) external returns (address proxy);

    /**
     *  @notice add new vesting to register, can be invoked only by Owner
     *  @dev add new vesting address to register
     *  @param _vesting - is the address of vesting that will add
     *  @param _isPrivate - is the type of vesting that will add
     */
    function add(address _vesting, bool _isPrivate) external;

    /**
     *  @notice remove vesting from register, can be invoked only by Owner
     *  @dev remove vesting address from register
     *  @param _vesting - is the address of vesting that will removed
     */
    function remove(address _vesting) external;

    /**
     *  @notice get contract Owner
     *  @dev return address which has DEFAULT_ADMIN_ROLE
     *  @return address of the contract owner
     */
    function owner() external view returns (address);

    /**
     *  @notice get list of registered vesting
     *  @dev return list of addresses which is registered in register
     *  @param _offset - the shift from the beginning of the array
     *  @param _limit - the count of addresses which will returned or less
     *  @return array address
     */
    function list(uint256 _offset, uint256 _limit)
        external
        view
        returns (address[] memory);

    /**
     *  @notice returns whether the address is in the register
     *  @dev bool whether the address is registered
     *  @param _vesting - is the address of vesting that will be checked
     *  @return bool whether the address is registered
     */
    function isRegistered(address _vesting) external view returns (bool);
}
