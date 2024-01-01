// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./MerkleProof.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./emitter.sol";
import "./helper.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

interface IFactory {
    function claimFee() external view returns (uint);
}

contract Claim is AccessControl, Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private emitterContract;

    address private factory;

    ///@dev Airdrop balance
    uint public claimBalance;

    ///@dev claim settings
    ClaimSettings public claimSettings;

    ///@dev mapping to keep track of amount to claim for a address
    mapping(address => uint256) public claimAmount;
    ///@dev mapping to keep track of amount to claim for a address
    mapping(address => CoolDownClaimDetails[]) public PendingClaimDetails;

    function initialize(
        address _admin,
        ClaimSettings memory _claimSettings,
        address _factory,
        address _emitter
    ) external initializer {
        claimSettings = _claimSettings;
        claimBalance = _claimSettings.claimAmountDetails.totalClaimAmount;

        if (!claimSettings.hasAllowanceMechanism) {
            claimSettings.walletAddress = address(this);
        }

        factory = _factory;
        emitterContract = _emitter;

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MODERATOR, _admin);
    }

    /// @notice This function is used to allocate particular amount of tokens
    /// @dev This function maps claim amount to a address based on settings
    /// @param _amount amount in decimals to claim
    /// @param _merkleProof merkle proof to check validity
    function claim(
        uint256 _amount,
        address _receiver,
        bytes32[] calldata _merkleProof,
        bytes memory _encodedData
    ) external payable nonReentrant {
        // Load in memory for gas savings
        ClaimSettings memory claimSettingsMemory = claimSettings;

        // Check if claim is enabled
        if (!claimSettings.isEnabled) revert ClaimNotStarted();
        // Check if claim still open
        if (claimSettingsMemory.startTime > block.timestamp)
            revert ClaimNotStarted();
        if (claimSettingsMemory.endTime < block.timestamp) revert ClaimClosed();

        if (claimAmount[msg.sender] == 0) {
            if (msg.value != IFactory(factory).claimFee())
                revert InvalidAmount();
            payable(factory).call{value: msg.value}("");
        }

        //Checking permissions
        if (claimSettingsMemory.permission == CLAIM_PERMISSION.TokenGated) {
            // Check if user has the minimum required token amount
            if (
                IERC20(claimSettingsMemory.daoToken).balanceOf(msg.sender) <
                claimSettingsMemory.tokenGatingValue
            ) revert InsufficientBalance();
        } else if (
            claimSettingsMemory.permission == CLAIM_PERMISSION.Whitelisted ||
            claimSettingsMemory.permission == CLAIM_PERMISSION.Prorata
        ) {
            bytes32 leaf = keccak256(_encodedData);
            (address _adr, uint256 _maximumClaimAmount) = abi.decode(
                _encodedData,
                (address, uint256)
            );

            if (
                !MerkleProof.verify(
                    _merkleProof,
                    claimSettingsMemory.merkleRoot,
                    leaf
                )
            ) revert IncorrectProof();

            // Check that the proof submitted by the right wallet.
            if (_adr != msg.sender) revert IncorrectUserAddress();
            // Check that the requested amount is not higher than what the wallet is allowed to claim
            require(
                claimAmount[msg.sender] + _amount <= _maximumClaimAmount,
                "Not Allowed"
            );
        }

        //Setting claim amount
        claimAmount[msg.sender] += _amount;

        require(
            claimSettingsMemory.claimAmountDetails.maxClaimable >=
                claimAmount[msg.sender],
            "Max claim reached"
        );

        //If there is a cooldown, start it until user can claim the tokens
        if (claimSettingsMemory.cooldownTime != 0) {
            if (PendingClaimDetails[_receiver].length > 20) revert MaxReached();
            CoolDownClaimDetails
                memory newCoolDownClaimDetails = CoolDownClaimDetails(
                    block.timestamp + claimSettingsMemory.cooldownTime,
                    _amount
                );
            PendingClaimDetails[_receiver].push(newCoolDownClaimDetails);
        } else {
            airdropTokens(_amount, _receiver);
        }

        ClaimEmitter(emitterContract).airdropClaimed(
            address(this),
            msg.sender,
            claimSettingsMemory.airdropToken,
            claimAmount[msg.sender],
            _amount
        );
    }

    function claimAllPending(address _receiver) external {
        CoolDownClaimDetails[] storage pendingClaims = PendingClaimDetails[
            _receiver
        ];

        uint256 totalClaimAmount;

        for (uint256 i; i < pendingClaims.length; ) {
            CoolDownClaimDetails memory _claim = pendingClaims[i];
            if (_claim.unlockTime <= block.timestamp) {
                uint256 amountToClaim = _claim.unlockAmount;
                totalClaimAmount += amountToClaim;

                // Shift elements to the left starting from the current index
                for (uint j = i; j < pendingClaims.length - 1; j++) {
                    pendingClaims[j] = pendingClaims[j + 1];
                }

                // Resize the array by reducing its length by 1
                pendingClaims.pop();
            } else {
                // Increment the index only when the claim is not removed
                ++i;
            }
        }
        PendingClaimDetails[_receiver] = pendingClaims;
        airdropTokens(totalClaimAmount, _receiver);
    }

    /// @notice This function is used to disburse allocated tokens
    /// @dev This function gets mapped amount for a particular user and transfers it
    /// @dev User can make multiple calls to this function to withdraw tokens
    function airdropTokens(uint256 _amount, address _receiver) private {
        if (claimSettings.hasAllowanceMechanism) {
            if (claimBalance < _amount) revert InsufficientBalance();
            IERC20(claimSettings.airdropToken).safeTransferFrom(
                claimSettings.walletAddress,
                _receiver,
                _amount
            );
        } else {
            IERC20(claimSettings.airdropToken).safeTransfer(_receiver, _amount);
        }
        claimBalance = claimBalance - _amount;
    }

    /// @dev This function is used to deposit tokens to the claim pool
    /// @dev Only admin can call this function
    /// @param _amount Amount of tokens to deposit
    function depositTokens(
        uint256 _amount,
        bytes32 _newRoot
    ) external onlyRole(MODERATOR) {
        ClaimSettings memory claimSettingsMemory = claimSettings;

        if (claimSettingsMemory.hasAllowanceMechanism)
            revert HasAllowanceMechanism();

        if (
            claimSettingsMemory.permission == CLAIM_PERMISSION.Whitelisted ||
            claimSettingsMemory.permission == CLAIM_PERMISSION.Prorata
        ) {
            claimSettings.merkleRoot = _newRoot;
            ClaimEmitter(emitterContract).changeRoot(address(this), _newRoot);
        }

        IERC20(claimSettingsMemory.airdropToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        claimSettings.claimAmountDetails.totalClaimAmount += _amount;
        claimBalance += _amount;

        ClaimEmitter(emitterContract).depositTokens(
            msg.sender,
            address(this),
            _amount
        );
    }

    /// @dev This function is used to withdraw tokens deposited by the admin
    /// @dev Only admin can call this function
    /// @param _amount Amount of tokens to withdraw
    function rollbackTokens(
        uint256 _amount,
        address rollbackAddress
    ) external onlyRole(MODERATOR) {
        IERC20(claimSettings.airdropToken).safeTransfer(
            rollbackAddress,
            _amount
        );

        claimSettings.claimAmountDetails.totalClaimAmount =
            claimSettings.claimAmountDetails.totalClaimAmount -
            _amount;
        claimBalance = claimBalance - _amount;

        ClaimEmitter(emitterContract).rollbackTokens(
            address(this),
            msg.sender,
            _amount
        );
    }

    /// @dev This function is used to change merkle root
    /// @dev Only admin can call this function
    /// @param _newRoot New merkle root
    function changeRoot(bytes32 _newRoot) external onlyRole(MODERATOR) {
        claimSettings.merkleRoot = _newRoot;
        ClaimEmitter(emitterContract).changeRoot(address(this), _newRoot);
    }

    /// @dev This function is used to change claim amount details
    /// @dev Only admin can call this function
    /// @param _newMaxClaimAmount New max claim amount
    function changeMaxClaimAmount(
        uint256 _newMaxClaimAmount
    ) external onlyRole(MODERATOR) {
        if (_newMaxClaimAmount == 0) revert InvalidAmount();
        claimSettings.claimAmountDetails.maxClaimable = _newMaxClaimAmount;
        ClaimEmitter(emitterContract).changeMaxClaimAmount(
            address(this),
            _newMaxClaimAmount
        );
    }

    /// @dev This function is used to toggle claim on/off
    /// @dev Only admin can call this function
    function toggleClaim() external onlyRole(MODERATOR) {
        claimSettings.isEnabled = !claimSettings.isEnabled;
        ClaimEmitter(emitterContract).toggleClaim(
            address(this),
            claimSettings.isEnabled
        );
    }

    /// @dev This function is used to change cool down time
    /// @dev Only admin can call this function
    /// @param _coolDownTime New cooldown time
    function changeCooldownTime(
        uint _coolDownTime
    ) external onlyRole(MODERATOR) {
        claimSettings.cooldownTime = _coolDownTime;
        ClaimEmitter(emitterContract).changeCooldownTime(
            address(this),
            _coolDownTime
        );
    }

    /// @dev This function is used to change claim start and end time
    /// @dev Only admin can call this function
    /// @param _startTime New start time
    /// @param _endTime New end time
    function changeStartAndEndTime(
        uint _startTime,
        uint _endTime
    ) external onlyRole(MODERATOR) {
        if (_startTime > _endTime || _endTime < _startTime)
            revert InvalidTime();

        claimSettings.startTime = _startTime;
        claimSettings.endTime = _endTime;

        ClaimEmitter(emitterContract).changeStartAndEndTime(
            address(this),
            _startTime,
            _endTime
        );
    }

    function addAdmin(address _admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(MODERATOR, _admin);
    }

    function encode(
        address _userAddress,
        uint256 _amount
    ) public pure returns (bytes memory) {
        return abi.encode(_userAddress, _amount);
    }
}
