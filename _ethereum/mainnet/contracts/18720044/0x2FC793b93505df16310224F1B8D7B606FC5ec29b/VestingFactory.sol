// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.21;

import "./Clones.sol";
import "./Ownable.sol";
import "./Multicall.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";

import "./Vesting.sol";

contract VestingFactory is Ownable, Multicall {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Clones for address;
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address public immutable template;

    mapping(address => EnumerableSet.AddressSet) internal _vestings;

    event NewVesting(address indexed instance, address indexed beneficiary, uint256 amount, string description);
    event VestingIncreased(address indexed instance, address indexed beneficiary, uint256 amount);

    constructor(address _token, address _lottery) Ownable(msg.sender) {
        token = IERC20(_token);
        template = address(new Vesting(_token, _lottery));
    }

    function vestingsOf(address account) external view returns (uint256) {
        return _vestings[account].length();
    }

    function vestingsOfByIndex(address account, uint256 index) external view returns (address) {
        return _vestings[account].at(index);
    }

    function listVestingsOf(address account) external view returns (address[] memory) {
        return _vestings[account].values();
    }

    function createVesting(
        uint256 amount,
        address beneficiary,
        uint64 startTimestamp,
        uint64 durationSeconds,
        bytes32 referralCode,
        string calldata description
    )
        external
        onlyOwner
        returns (address instance)
    {
        instance = template.clone();
        Vesting(payable(instance)).initialize(beneficiary, startTimestamp, durationSeconds, referralCode);
        token.safeTransfer(instance, amount);
        emit NewVesting(instance, beneficiary, amount, description);
    }

    function increaseVesting(address instance, uint256 amount) external onlyOwner {
        address beneficiary = Vesting(payable(instance)).owner();
        require(_vestings[beneficiary].contains(instance), "VestingFactory: Invalid vesting");

        token.safeTransfer(instance, amount);

        emit VestingIncreased(instance, beneficiary, amount);
    }

    function ownershipUpdate(address oldOwner, address newOwner) external {
        require(oldOwner == address(0), "VestingFactory: can't transfer ownership.");
        require(_vestings[newOwner].add(msg.sender), "VestingFactory: reverted");
    }

    function claimable(address account) external view returns (uint256 totalValue) {
        EnumerableSet.AddressSet storage instances = _vestings[account];
        uint256 length = instances.length();
        for (uint256 i = 0; i < length; ++i) {
            Vesting vesting = Vesting(payable(instances.at(i)));
            totalValue +=
                vesting.vestedAmount(address(token), uint64(block.timestamp)) - vesting.released(address(token));
        }
    }

    function claimAll(address account) external {
        EnumerableSet.AddressSet storage instances = _vestings[account];
        uint256 length = instances.length();
        for (uint256 i = 0; i < length; ++i) {
            Vesting(payable(instances.at(i))).release(address(token));
        }
    }

    function withdraw(IERC20 anytoken, address recipient) external onlyOwner {
        anytoken.transfer(recipient, anytoken.balanceOf(address(this)));
    }
}
