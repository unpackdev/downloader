// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Pausable.sol";

// Box opening related errors
error SeedPotOpeningIsClosed();
error CannotOpenUnownedBox();
error ZeroAddress();
error TooManyBoxes();

abstract contract VanguardFactory {
    function openBox(
        address to,
        uint256 boxId
    ) public virtual returns (uint256);
}

interface IMagicEdenContract {
    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract BlackBoxVanguard is ReentrancyGuard, AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address private vanguardContract;

    IMagicEdenContract public magicEdenContract;
    VanguardFactory factory;
    address immutable BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    bool public canOpenSeedPot;

    event BoxOpened(address indexed owner, uint256 boxId);

    constructor(
        address _vanguardContract,
        address _magicEdenContract,
        address[] memory admins
    ) {
        if (_vanguardContract == address(0)) revert ZeroAddress();
        if (_magicEdenContract == address(0)) revert ZeroAddress();

        magicEdenContract = IMagicEdenContract(_magicEdenContract);
        factory = VanguardFactory(_vanguardContract);

        for (uint256 i = 0; i < admins.length; ++i) {
            _setupRole(ADMIN_ROLE, admins[i]);
        }
    }

    function openBoxes(
        uint256[] calldata boxIds
    ) public nonReentrant returns (uint256[] memory) {
        if (boxIds.length > 100) revert TooManyBoxes();
        if (!canOpenSeedPot) revert SeedPotOpeningIsClosed();

        uint256[] memory results = new uint256[](boxIds.length);

        for (uint256 i; i < boxIds.length; ) {
            uint256 boxId = boxIds[i];

            address boxOwner = magicEdenContract.ownerOf(boxId);
            if (boxOwner != msg.sender) revert CannotOpenUnownedBox();

            results[i] = factory.openBox(boxOwner, boxId);

            // Should get approval before to call transferFrom
            magicEdenContract.transferFrom(msg.sender, BURN_ADDRESS, boxId);

            unchecked {
                ++i;
            }

            emit BoxOpened(boxOwner, boxId);
        }

        return results;
    }

    function setOpenSeedPot(bool isEnable) external onlyRole(ADMIN_ROLE) {
        canOpenSeedPot = isEnable;
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}
