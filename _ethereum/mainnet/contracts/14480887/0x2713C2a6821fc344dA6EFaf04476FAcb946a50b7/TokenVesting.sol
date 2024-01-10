// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

/**
 * @title Token vesting contract
 * @author Onur Tekin
 */
contract TokenVesting is Ownable {
    using SafeERC20 for IERC20;

    /// Token contract that tokens will be released to
    IERC20 public immutable token;

    /// First token release time
    uint256 public immutable firstUnlockTime;
    /// Second token release time
    uint256 public immutable secondUnlockTime;
    /// Third token release time
    uint256 public immutable thirdUnlockTime;

    /**
     * @dev This struct holds information about the vesting
     * @param amountToClaimOnFirstUnlockTime Amount of token that is going to be released on first release time
     * @param amountToClaimOnSecondUnlockTime Amount of token that is going to be released on second release time
     * @param amountToClaimOnThirdUnlockTime Amount of token that is going to be released on third release time
     * @param totalClaimed Total claimed amount of tokens
     */
    struct Vesting {
        uint256 amountToClaimOnFirstUnlockTime;
        uint256 amountToClaimOnSecondUnlockTime;
        uint256 amountToClaimOnThirdUnlockTime;
        uint256 totalClaimed;
    }

    /// A mapping for storing vesting data for each address
    mapping(address => Vesting) private _addressVesting;

    /**
     * @dev Emitted when the tokens are claimed
     * @param beneficiary The address of the beneficiary
     * @param amount The claimed amount of tokens
     */
    event Claimed(address indexed beneficiary, uint256 amount);

    constructor(
        address addressToken,
        uint256 _firstUnlockTime,
        uint256 _secondUnlockTime,
        uint256 _thirdUnlockTime
    ) {
        require(addressToken != address(0), "TokenVesting: token address cannot be zero");
        require(_firstUnlockTime > block.timestamp, "TokenVesting: first unlock time is before current time");
        require(_secondUnlockTime > _firstUnlockTime, "TokenVesting: second unlock time is before first unlock time");
        require(_thirdUnlockTime > _secondUnlockTime, "TokenVesting: third unlock time is before second unlock time");

        token = IERC20(addressToken);
        firstUnlockTime = _firstUnlockTime;
        secondUnlockTime = _secondUnlockTime;
        thirdUnlockTime = _thirdUnlockTime;
    }

    modifier onlyBeneficiary(address beneficiary) {
        Vesting memory vesting = _addressVesting[beneficiary];
        require(_isContainsAnyLockedToken(vesting), "TokenVesting: address is not beneficiary");
        _;
    }

    /**
     * @dev Adds beneficiaries
     * @param addresses Beneficiary addresses
     * @param vestings Vesting data for beneficiary addresses
     */
    function addBeneficiaries(address[] memory addresses, Vesting[] memory vestings) external onlyOwner {
        require(addresses.length == vestings.length, "TokenVesting: arrays of incorrect length");

        for (uint256 i = 0; i < addresses.length; i++) {
            Vesting memory vesting = vestings[i];
            address beneficiaryAddress = addresses[i];

            _setBeneficiaryVestingData(beneficiaryAddress, vesting);
        }
    }

    /// @dev Claims tokens
    function claim() external onlyBeneficiary(msg.sender) {
        require(block.timestamp >= firstUnlockTime, "TokenVesting: current time is before first unlock time");

        uint256 availableAmountToClaim = getAvailableAmountToClaim(msg.sender);
        require(availableAmountToClaim > 0, "TokenVesting: no tokens to claim");

        uint256 contractBalance = token.balanceOf(address(this));
        require(
            contractBalance >= availableAmountToClaim,
            "TokenVesting: contract balance is not enough to perform claim"
        );

        _addressVesting[msg.sender].totalClaimed += availableAmountToClaim;
        token.safeTransfer(msg.sender, availableAmountToClaim);

        emit Claimed(msg.sender, availableAmountToClaim);
    }

    /**
     * @dev Returns vesting data for `beneficiary`
     * @param beneficiary Beneficiary address
     * @return vesting See {Vesting}
     */
    function getVesting(address beneficiary)
        external
        view
        onlyBeneficiary(beneficiary)
        returns (Vesting memory vesting)
    {
        vesting = _addressVesting[beneficiary];
    }

    /**
     * @dev Returns available amount to claim
     * @param beneficiary Beneficiary address
     * @return amount available amount to claim
     */
    function getAvailableAmountToClaim(address beneficiary) public view returns (uint256 amount) {
        Vesting memory vesting = _addressVesting[beneficiary];
        amount = _getAmountToClaim(beneficiary) - vesting.totalClaimed;
    }

    /**
     * @dev Sets `vesting` data for the `beneficiary`
     * @param beneficiary Beneficiary address
     * @param vesting See {Vesting}
     */
    function _setBeneficiaryVestingData(address beneficiary, Vesting memory vesting) private {
        Vesting storage beneficiaryVesting = _addressVesting[beneficiary];

        beneficiaryVesting.amountToClaimOnFirstUnlockTime = vesting.amountToClaimOnFirstUnlockTime;
        beneficiaryVesting.amountToClaimOnSecondUnlockTime = vesting.amountToClaimOnSecondUnlockTime;
        beneficiaryVesting.amountToClaimOnThirdUnlockTime = vesting.amountToClaimOnThirdUnlockTime;
    }

    /**
     * @dev Returns amount to claim as of the moment function called
     * @param beneficiary Beneficiary address
     * @return amount amount to claim
     */
    function _getAmountToClaim(address beneficiary) private view returns (uint256 amount) {
        Vesting memory vesting = _addressVesting[beneficiary];

        if (block.timestamp >= thirdUnlockTime) {
            amount +=
                vesting.amountToClaimOnFirstUnlockTime +
                vesting.amountToClaimOnSecondUnlockTime +
                vesting.amountToClaimOnThirdUnlockTime;
        } else if (block.timestamp >= secondUnlockTime) {
            amount += vesting.amountToClaimOnFirstUnlockTime + vesting.amountToClaimOnSecondUnlockTime;
        } else if (block.timestamp >= firstUnlockTime) {
            amount += vesting.amountToClaimOnFirstUnlockTime;
        }
    }

    /**
     * @dev Checks `vesting` to see if there is any locked token
     * @param vesting See {Vesting}
     * @return lockedToken the result of the check
     */
    function _isContainsAnyLockedToken(Vesting memory vesting) private pure returns (bool lockedToken) {
        lockedToken =
            vesting.amountToClaimOnFirstUnlockTime > 0 ||
            vesting.amountToClaimOnSecondUnlockTime > 0 ||
            vesting.amountToClaimOnThirdUnlockTime > 0;
    }
}
