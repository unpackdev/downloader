// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "./ECDSA.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ICheezburger.sol";
import "./CheezburgerRegistry.sol";

contract CheezburgerOwnership is Ownable, ReentrancyGuard, CheezburgerRegistry {
    using ECDSA for bytes32;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error EmptyAddressNotAllowed();
    error InvalidSignature(address actual, address expected);
    error UnauthorizedUser();
    error SignatureExpired();
    error TokenNotFound();
    error OwnershipAlreadyClaimed();
    error ClaimOwnershipDisabled();
    error CannotReceiveEtherDirectly();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    event SocialOwnershipClaimed(
        uint256 indexed userId,
        address indexed authorizedUser
    );
    event SocialFeesClaimed(
        uint256 indexed userId,
        address indexed authorizedUser,
        uint256 indexed amount
    );
    event SocialOwnershipTransferred(
        uint256 indexed userId,
        address indexed previousOwner,
        address indexed newOwner
    );

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    uint256 private constant SIGNATURE_VALIDITY = 20 minutes;

    mapping(uint256 => address) public owners;
    address public authorizerAddress;
    ICheezburger public chzb;

    constructor(address _chzb) {
        if (_chzb == address(0)) {
            revert EmptyAddressNotAllowed();
        }
        _initializeOwner(msg.sender);
        chzb = ICheezburger(_chzb);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function claimOwnership(
        bytes calldata _message,
        bytes calldata _signature
    ) external nonReentrant {
        address recovered = keccak256(_message)
            .toEthSignedMessageHash()
            .recoverCalldata(_signature);
        if (recovered != authorizerAddress) {
            revert InvalidSignature(recovered, authorizerAddress);
        }
        (uint256 userId, address authorizedUser, uint256 timestamp) = abi
            .decode(_message, (uint256, address, uint256));

        // Only the authorized user can claim
        if (authorizedUser != msg.sender) {
            revert UnauthorizedUser();
        }

        // Verify timestamp from message
        if (timestamp > block.timestamp) {
            revert SignatureExpired();
        }
        if (timestamp + SIGNATURE_VALIDITY < block.timestamp) {
            revert SignatureExpired();
        }

        // Ensure token exist
        if (getSocialToken(chzb, userId).leftSide == address(0)) {
            revert TokenNotFound();
        }

        // Ensure ownership has not been claimed already
        if (owners[userId] != address(0)) {
            revert OwnershipAlreadyClaimed();
        }

        owners[userId] = authorizedUser;

        emit SocialOwnershipClaimed(userId, authorizedUser);
    }

    /// @dev Allows an owner to claim fees from their social token
    /// @param userId ID of the owner's social token
    function claimFees(
        uint256 userId
    ) external onlySocialOwner(userId) nonReentrant {
        uint256 amount = chzb.withdrawFeesOf(userId, owners[userId]);
        emit SocialFeesClaimed(userId, owners[userId], amount);
    }

    /// @dev Transfers ownership of a social token to a new owner
    /// @param userId ID of the social token
    /// @param _newOwner New owner address
    function transferSocialOwnership(
        uint256 userId,
        address _newOwner
    ) external onlySocialOwner(userId) nonReentrant {
        address previousOwner = owners[userId];
        owners[userId] = _newOwner;
        emit SocialOwnershipTransferred(userId, previousOwner, _newOwner);
    }

    /// @dev Allows the owner to change the authorizer address
    /// @param _authorizerAddress The address allowed to make signatures for ownership claims
    function changeSettings(address _authorizerAddress) external onlyOwner {
        authorizerAddress = _authorizerAddress;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Requires caller to be authorized owner of the specified social token
    modifier onlySocialOwner(uint256 userId) {
        address user = owners[userId];
        if (user != msg.sender) {
            revert UnauthorizedUser();
        }
        _;
    }
}
