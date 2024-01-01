// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

import "./VTVLVesting.sol";
import "./IVestingFee.sol";

/// @title Vesting Factory contract
/// @notice Create Vesting contract

contract VTVLVestingFactory is Ownable {
    using SafeERC20 for IERC20;

    event CreateVestingContract(
        address indexed vestingAddress,
        address deployer
    );

    mapping(address => bool) isVestingContracts;

    /**
    @notice This modifier requires the vesting contract.
    */
    modifier onlyVestingContract(address _vestingContract) {
        require(
            isVestingContracts[_vestingContract],
            "Not our vesting contract"
        );
        _;
    }

    /**
     * @notice Create Vesting contract without funding.
     * @dev This will only create the vesting contract.
     * @param _tokenAddress Vesting Fund token address.
     * @param _feePercent The percent of fee.
     */
    function createVestingContract(
        IERC20Extented _tokenAddress,
        uint256 _feePercent
    ) public {
        VTVLVesting vestingContract = new VTVLVesting(
            _tokenAddress,
            _feePercent
        );

        isVestingContracts[address(vestingContract)] = true;

        emit CreateVestingContract(address(vestingContract), msg.sender);
    }

    /**
     * @notice Set the fee percent of Vesting contract.
     * @dev 100% will be 10000.
     */
    function setFee(
        address _vestingContract,
        uint256 _feePercent
    ) external onlyOwner onlyVestingContract(_vestingContract) {
        if (_feePercent > 0 && _feePercent < 10000) {
            IVestingFee(_vestingContract).setFee(_feePercent);
        } else {
            revert("INVALID_FEE_PERCENT");
        }
    }

    /**
     * @notice Set the fee recipient of Vesting contract.
     */
    function updateFeeReceiver(
        address _vestingContract,
        address _newReceiver
    ) external onlyOwner onlyVestingContract(_vestingContract) {
        IVestingFee(_vestingContract).updateFeeReceiver(_newReceiver);
    }

    /**
     * @notice Set the minimum price that will take the fee.
     * @dev 0.3 will be 30.
     */
    function updateconversionThreshold(
        address _vestingContract,
        uint256 _threshold
    ) external onlyOwner onlyVestingContract(_vestingContract) {
        IVestingFee(_vestingContract).updateconversionThreshold(_threshold);
    }

    /**
     * @notice Withdraw the token to the receiver.
     */
    function withdraw(
        address _tokenAddress,
        address _receiver
    ) external onlyOwner {
        uint256 balance = IERC20(_tokenAddress).balanceOf(address(this));
        IERC20(_tokenAddress).transfer(_receiver, balance);
    }
}
