// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./TreasuryVester.sol";

import "./IERC20.sol";
import "./AccessControl.sol";
import "./Address.sol";

// proxy
import "./Clones.sol";

contract TreasuryVesterFactory is AccessControl {
    using Address for address;
    using Clones for address;

    /// @notice The role assigned to users who can call admin/restricted functions
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice The Euler token
    IERC20 public EUL;

    /// @notice The Euler treasury contract
    address public treasury;

    TreasuryVester public immutable vestingLogic;

    /// @notice mapping vested token recipients to their vesting contracts
    mapping(address => address[]) public vestingContracts;
    /// @notice mapping hash of vesting data to created vesting contracts
    mapping(bytes32 => address) public vestingData;

    /// MODIFIERS
    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender),
            "Caller does not have the ADMIN_ROLE"
        );
        _;
    }

    /// EVENTS
    event TreasuryUpdated(address newTreasury);
    event VestingContract(
        address indexed recipient,
        address vestingContract,
        uint256 index
    );

    constructor(address eul_, address treasury_, address treasuryVesterImplementation_) {
        require(eul_ != address(0), "cannot set zero address as euler token");
        require(eul_.isContract(), "euler token must be a smart contract");
        EUL = IERC20(eul_);

        require(treasury_ != address(0), "cannot set zero address as treasury");
        treasury = treasury_;

        require(treasuryVesterImplementation_ != address(0), "cannot set zero address as treasury vester");
        require(treasuryVesterImplementation_.isContract(), "treasury vester must be a smart contract");
        vestingLogic = TreasuryVester(treasuryVesterImplementation_);

        _setupRole(DEFAULT_ADMIN_ROLE, treasury);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, treasury);
    }

    /**
     * @notice Creates a hash of the vesting contract parameters.
     * @param recipient The address for which the vesting contract is created
     * @param vestingAmount The vested amount
     * @param vestingBegin The start timestamp of vesting
     * @param vestingCliff Timestamp of vesting cliff when withdrawal of vested tokens can begin
     * @param vestingEnd The timestamp when the vesting ends
     */
    function hashVestingData(
        address recipient,
        uint256 vestingAmount,
        uint256 vestingBegin,
        uint256 vestingCliff,
        uint256 vestingEnd
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    recipient,
                    vestingAmount,
                    vestingBegin,
                    vestingCliff,
                    vestingEnd
                )
            );
    }

    /**
     * @notice Creates a new vesting contract for the specified recipient.
     * Only callable by admins.
     * @param recipient The address for which the vesting contract is created
     * @param vestingAmount The vested amount
     * @param vestingBegin The start timestamp of vesting
     * @param vestingCliff Timestamp of vesting cliff when withdrawal of vested tokens can begin
     * @param vestingEnd The timestamp when the vesting ends
     */
    function createVestingContract(
        address recipient,
        uint256 vestingAmount,
        uint256 vestingBegin,
        uint256 vestingCliff,
        uint256 vestingEnd
    )
        external
        onlyAdmin
        returns (
            address recipient_,
            address vestingContract_,
            uint256 index_
        )
    {
        bytes32 vestingDataHash = hashVestingData(
            recipient,
            vestingAmount,
            vestingBegin,
            vestingCliff,
            vestingEnd
        );
        require(
            vestingData[vestingDataHash] == address(0),
            "vesting contract already exists"
        );
        require(
            EUL.balanceOf(address(this)) >= vestingAmount,
            "insufficient balance for vestingAmount"
        );
        bytes memory data = abi.encodeWithSelector(
            vestingLogic.initialize.selector,
            address(EUL),
            recipient,
            vestingAmount,
            vestingBegin,
            vestingCliff,
            vestingEnd
        );

        recipient_ = recipient;
        index_ = vestingContracts[recipient].length;
        vestingContract_ = _initAndEmit(address(vestingLogic).clone(), data);
        vestingData[vestingDataHash] = vestingContract_;
        vestingContracts[recipient_].push(vestingContract_);
        EUL.transfer(vestingContract_, vestingAmount);
        emit VestingContract(recipient_, vestingContract_, index_);
    }

    function _initAndEmit(address instance, bytes memory initdata)
        internal
        returns (address)
    {
        instance.functionCallWithValue(initdata, msg.value);
        return instance;
    }

    /**
     * @notice Removes excess Euler tokens from this contract.
     * Only callable by admins.
     * @param amount The amount to withdraw to treasury
     */
    function withdraw(uint256 amount) external onlyAdmin {
        EUL.transfer(treasury, amount);
    }

    /**
     * @notice Update the treasury address to receive minted tokens.
     * Only callable by admins.
     * @param newTreasury The address to set as the new Treasury
     */
    function updateTreasury(address newTreasury) external onlyAdmin {
        require(newTreasury != address(0), "cannot set zero treasury address");
        treasury = newTreasury;
        emit TreasuryUpdated(treasury);
    }

    function getVestingContract(address recipient, uint256 index)
        external
        view
        returns (address)
    {
        return vestingContracts[recipient][index];
    }

    function getVestingContracts(address recipient)
        external
        view
        returns (address[] memory)
    {
        return vestingContracts[recipient];
    }
}
