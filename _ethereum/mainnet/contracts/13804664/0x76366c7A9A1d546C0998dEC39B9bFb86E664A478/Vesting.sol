// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./PausableUpgradeable.sol";
import "./MerkleProofUpgradeable.sol";
import "./BumperAccessControl.sol";

contract Vesting is PausableUpgradeable, BumperAccessControl {
    using SafeERC20 for IERC20;

    address public tokenBUMP;
    bytes32 public merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    // Pause list of investors
    mapping(address => bool) public investorPause;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address indexed account, uint256 amount, uint256 timestamp);

    ///@notice Will initialize state variables of this contract
    ///@param _whitelistAddresses Array of white list addresses
    function initialize(
        address _token,
        bytes32 _merkleRoot,
        address[] calldata _whitelistAddresses
    ) public initializer {
        __Pausable_init();
        _BumperAccessControl_init(_whitelistAddresses);
        // token should NOT be 0 address
        require(_token != address(0), "address(0)");
        tokenBUMP = _token;
        merkleRoot = _merkleRoot;
        // contract is paused by default
        _pause();
    }

    /// @notice Index used or not.
    /// @dev Information is stored in bits
    /// @param index Serial number of proof
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    /// @notice Set index used.
    /// @dev Information is stored in bits
    /// @param index Serial number of proof
    function _setClaimed(uint256 index) internal {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] =
            claimedBitMap[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    /// @notice Claim a specific amount of tokens.
    /// @dev Can only be invoked if the escrow is NOT paused.
    ///      Can only be invoked if the investor is NOT paused.
    /// @param index Serial number of proof
    /// @param account Investor address to which funds will be transferred
    /// @param amount The number of funds to be transferred
    /// @param timestamp Timestamp of periods
    /// @param merkleProof Proof of data accuracy
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        uint256 timestamp,
        bytes32[] calldata merkleProof
    ) external whenNotPaused {
        _claim(index, account, amount, timestamp, merkleProof);
    }

    /// @notice Bulk token claim.
    /// @dev Can only be invoked if the escrow is NOT paused.
    ///      Can only be invoked if the investor is NOT paused.
    /// @param claimArgs array encoded values (index, account, amount, timestamp, merkleProof)
    function claimBulk(bytes[] calldata claimArgs) external whenNotPaused {
        for (uint256 i = 0; i < claimArgs.length; i++) {
            (uint256 index, address account, uint256 amount, uint256 timestamp, bytes32[] memory merkleProof) = abi.decode(
                    claimArgs[i],
                (uint256, address, uint256, uint256, bytes32[])
            );
            _claim(index, account, amount, timestamp, merkleProof);
        }
    }

    /// @notice Claim a specific amount of tokens.
    /// @param index Serial number of proof
    /// @param account Investor address to which funds will be transferred
    /// @param amount The number of funds to be transferred
    /// @param timestamp Timestamp of periods
    /// @param merkleProof Proof of data accuracy
    function _claim(
        uint256 index,
        address account,
        uint256 amount,
        uint256 timestamp,
        bytes32[] memory merkleProof
    ) internal {
        require(!investorPause[account], "investor Paused");
        require(timestamp < block.timestamp, "Early");
        require(!isClaimed(index), "Drop already claimed");

        // Verify the merkle proof.
        bytes32 node = keccak256(
            abi.encodePacked(index, account, amount, timestamp)
        );
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        // Mark it claimed and send the token.
        _setClaimed(index);

        IERC20(tokenBUMP).safeTransfer(account, amount);

        emit Claimed(index, account, amount, block.timestamp);
    }

    /// @notice Transfer tokens from the contract to the address.
    /// @dev Only owner of the vesting escrow can invoke this function.
    function withdraw(
        address to,
        address token,
        uint256 amount
    ) external onlyGovernance {
        IERC20(token).safeTransfer(to, amount);
    }

    /// @notice Set Merkle root
    /// @dev Only owner of the vesting escrow can invoke this function.
    function setMerkleRoot(bytes32 root) external onlyGovernance {
        merkleRoot = root;
    }

    /// @notice Pause vesting contract
    /// @dev Only owner of the vesting escrow can invoke this function.
    function pause() external onlyGovernance whenNotPaused {
        _pause();
    }

    /// @notice Unpause vesting contract
    /// @dev Only owner of the vesting escrow can invoke this function.
    function unpause() external onlyGovernance whenPaused {
        _unpause();
    }

    /// @notice Pause investor
    /// @dev Only owner of the vesting escrow can invoke this function.
    /// @param activeInvestors The array recipient address for which vesting will be paused.
    function pauseRecipients(address[] calldata activeInvestors)
        external
        onlyGovernance
    {
        for (uint256 i = 0; i < activeInvestors.length; i++) {
            address investor = activeInvestors[i];

            investorPause[investor] = true;
        }
    }

    /// @notice Unpause investor
    /// @dev Only owner of the vesting escrow can invoke this function.
    /// @param pausedInvestors The array recipient address for which vesting will be paused.
    function unpauseRecipients(address[] calldata pausedInvestors)
        external
        onlyGovernance
    {
        for (uint256 i = 0; i < pausedInvestors.length; i++) {
            address investor = pausedInvestors[i];

            investorPause[investor] = false;
        }
    }
}
