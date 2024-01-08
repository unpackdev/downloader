// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./AccessControlEnumerable.sol";
import "./EnumerableSet.sol";
import "./TransparentUpgradeableProxy.sol";
import "./IVestingFactory.sol";

contract VestingFactory is IVestingFactory, AccessControlEnumerable {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    /// @dev set of registered vestings
    EnumerableSet.AddressSet private vestings;

    /// @dev implementation of Vesting
    address public vestingImplementation;

    /**
     *  @notice initialization
     *  @dev initialize contract, set implementation, grand roles for the deployer
     *  @param _vestingImplementation - addresses of implementation
     */
    constructor(address _vestingImplementation) {
        require(
            _vestingImplementation != address(0),
            "VestingFactory: wrong vesting implementation address"
        );
        vestingImplementation = _vestingImplementation;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     *  @notice returns whether the address is in the register
     *  @dev bool whether the address is registered
     *  @param _vesting - is the address of vesting that will be checked
     *  @return bool whether the address is registered
     */
    function isRegistered(address _vesting)
        external
        view
        override
        returns (bool)
    {
        return vestings.contains(_vesting);
    }

    /**
     *  @notice get list of registered vesting
     *  @dev return list of addresses which is registered in register
     *  @param _offset - the shift from the beginning of the array
     *  @param _limit - the count of addresses which will returned or less
     *  @return result - array address
     **/
    function list(uint256 _offset, uint256 _limit)
        external
        view
        override
        returns (address[] memory result)
    {
        uint256 to = _offset + _limit < vestings.length()
            ? _offset + _limit
            : vestings.length();
        to = to > _offset ? to : _offset;

        result = new address[](to - _offset);

        for (uint256 i = _offset; i < to; i++) {
            result[i - _offset] = vestings.at(i);
        }
    }

    /**
     *  @notice add new account to whitelist, can be invoked only by Owner
     *  @dev grant role CREATOR to the account
     *  @param _account - address to be granted role
     */
    function addCreator(address _account)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(CREATOR_ROLE, _account);
    }

    /**
     *  @notice remove account from the whitelist, can be invoked only by Owner
     *  @dev revoke role CREATOR from the account, checked ownership in revokeRole
     *  @param _account - address to be revoked role
     */
    function removeCreator(address _account) external override {
        revokeRole(CREATOR_ROLE, _account);
    }

    /**
     *  @notice add new vesting to register, can be invoked only by Owner
     *  @dev add new vesting address to register
     *  @param _vesting - is the address of vesting that will add
     *  @param _isPrivate - is the type of vesting that will add
     */
    function add(address _vesting, bool _isPrivate)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _add(_vesting, _isPrivate);
    }

    /**
     *  @notice remove vesting from register, can be invoked only by Owner
     *  @dev remove vesting address from register
     *  @param _vesting - is the address of vesting that will removed
     */
    function remove(address _vesting)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        bool success = vestings.remove(_vesting);
        require(success, "VestingFactory: Not found");

        emit RemoveVesting(_msgSender(), _vesting);
    }

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
    ) external override onlyRole(CREATOR_ROLE) returns (address proxy) {
        bytes memory bytesData = abi.encodeWithSignature(
            "initialize(string,address,address,address,uint256,uint256,uint256,uint8)",
            _name,
            _rewardToken,
            _depositToken,
            _signer,
            _initialUnlockPercentage,
            _minAllocation,
            _maxAllocation,
            _vestingType
        );

        proxy = address(
            new TransparentUpgradeableProxy(
                vestingImplementation,
                owner(),
                bytesData
            )
        );

        Ownable(proxy).transferOwnership(_msgSender());

        _add(proxy, false);
    }

    /**
     *  @notice set new implementation, can be invoked only by Owner
     *  @dev set new implementation of Vesting for the factory
     *  @param _vestingImplementation - addresses of new implementation
     */
    function setVestingImplementation(address _vestingImplementation)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _vestingImplementation != address(0),
            "VestingFactory: wrong vesting implementation address"
        );
        vestingImplementation = _vestingImplementation;
    }

    /**
     *  @notice get contract Owner
     *  @dev return address which has DEFAULT_ADMIN_ROLE
     *  @return address of the contract owner
     */
    function owner() public view override returns (address) {
        return getRoleMember(DEFAULT_ADMIN_ROLE, 0);
    }

    /**
     *  @notice add new vesting to register
     *  @dev add new vesting address to register
     *  @param _vesting - is the address of vesting that will add
     *  @param _isPrivate - is the type of vesting that will add
     */
    function _add(address _vesting, bool _isPrivate) internal {
        require(vestings.add(_vesting), "VestingFactory: Already exists");
        emit AddVesting(_msgSender(), _vesting, _isPrivate);
    }
}
