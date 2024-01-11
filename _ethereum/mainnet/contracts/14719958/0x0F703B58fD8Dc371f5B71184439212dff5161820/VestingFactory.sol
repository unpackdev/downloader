// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Clones.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./Multicall.sol";
import "./Vesting.sol";

contract VestingFactory is AccessControl, Multicall {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Clones        for address;
    using SafeERC20     for IERC20;

    IERC20  public immutable token;
    address public immutable template = address(new Vesting());

    mapping(address => EnumerableSet.AddressSet) internal _vestings;

    event NewVesting(address indexed instance, address indexed beneficiary, uint256 amount, string description);
    event VestingIncreased(address indexed instance, address indexed beneficiary, uint256 amount);

    constructor(IERC20 _token, address admin)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        token = _token;
    }

    function vestingsOf(address account)
        external view returns (uint256)
    {
        return _vestings[account].length();
    }

    function vestingsOfByIndex(address account, uint256 index)
        external view returns (address)
    {
        return _vestings[account].at(index);
    }

    function listVestingsOf(address account)
        external view returns (address[] memory)
    {
        return _vestings[account].values();
    }

    function createVesting(
        uint256         amount,
        address         beneficiary,
        uint64          start,
        uint64          duration,
        string calldata description
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        returns (address instance)
    {
        // create vesting instance
        instance = template.clone();

        // register
        _vestings[beneficiary].add(instance);

        // initialize
        Vesting(payable(instance)).initialize(beneficiary, start, duration);

        // allocate tokens
        token.safeTransfer(instance, amount);

        // emit event
        emit NewVesting(instance, beneficiary, amount, description);
    }

    function increaseVesting(
        address instance,
        uint256 amount
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // check vesting instance
        address beneficiary = Vesting(payable(instance)).owner();
        require(_vestings[beneficiary].contains(instance));

        // allocate tokens
        token.safeTransfer(instance, amount);

        // emit event
        emit VestingIncreased(instance, beneficiary, amount);
    }

    function ownershipUpdate(address oldOwner, address newOwner)
        external
    {
        require(!_vestings[newOwner].add(msg.sender) || _vestings[oldOwner].remove(msg.sender));
    }

    function claimable(address account)
        external view returns (uint256 totalValue)
    {
        EnumerableSet.AddressSet storage instances = _vestings[account];
        uint256 length = instances.length();
        for (uint256 i = 0; i < length; ++i) {
            Vesting vesting = Vesting(payable(instances.at(i)));
            totalValue += vesting.vestedAmount(address(token), uint64(block.timestamp))
                        - vesting.released(address(token));
        }
    }

    function claimAll(address account)
        external
    {
        EnumerableSet.AddressSet storage instances = _vestings[account];
        uint256 length = instances.length();
        for (uint256 i = 0; i < length; ++i) {
            Vesting(payable(instances.at(i))).release(address(token));
        }
    }

    function withdraw(IERC20 anytoken, address recipient)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        anytoken.transfer(recipient, anytoken.balanceOf(address(this)));
    }
}