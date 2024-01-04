//SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

import "./Ownable.sol";
import "./CloneFactory.sol";
import "./TokenVesting.sol";

/**
 * @dev Deploys new vesting contracts
 */
contract VestingFactory is CloneFactory, Ownable {

    using SafeMath for uint256;

    event Created(address beneficiary, address vestingContract);

    /// @dev implementation address of Token Vesting
    address private implementation;

    /// @dev Address to Token Vesting map
    mapping(address => TokenVesting) vestings;

    /// @dev Deploys a new proxy instance and sets custom owner of proxy
    /// Throws if the owner already have a Token Vesting contract
    /// @return vesting - address of new Token Vesting Contract
    function deployVesting(
        uint256[] memory periods,
        uint256[] memory tokenAmounts,
        address beneficiary,
        address token
    ) public returns (TokenVesting vesting) {
        require(implementation != address(0));
        require(
            vestings[beneficiary] == TokenVesting(0),
            "beneficiary exists"
        );
        require(periods.length == tokenAmounts.length, "Length mismatch");

        address _vesting = address(uint160(createClone(implementation)));
        vesting = TokenVesting(_vesting);
        require(vesting.initialize(periods, tokenAmounts, beneficiary, token), "!Initialized");

        vestings[beneficiary] = vesting;

        emit Created(beneficiary, _vesting);
    }

    /// @dev Change the address implementation of the Token Vesting
    /// @param _impl new implementation address of Token Vesting
    function setImplementation(address _impl) external onlyOwner {
        implementation = _impl;
    }

    /// @dev get token vesting implementation address
    function getImplementation() external view returns(address) {
        return implementation;
    }

    /// @dev get vesting contract address for a given beneficiary
    function getVestingContract(address beneficiary) external view returns(address) {
        return address(vestings[beneficiary]);
    }

    /// @notice Fetch amount that can be currently released by a certain address
    function releaseableAmount(address beneficiary) public view returns(uint) {
        TokenVesting _vesting = vestings[beneficiary];

        (uint releasedPeriods, uint totalPeriods,,,) = _vesting.getGlobalData();

        uint256 amount = 0;
        for (uint256 i = releasedPeriods; i < totalPeriods; i++) {
            (uint vestingAmount, uint timestamp) = _vesting.getPeriodData(i);
            if (timestamp <= block.timestamp) {
                amount = amount.add(vestingAmount);
            }
            else {
                break;
            }
        }
        return amount;
    }
}