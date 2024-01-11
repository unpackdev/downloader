// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IStayDAONFTRoyaltyVault.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./UUPSUpgradeable.sol";

contract StayDAONFTRoyaltyVault is
    IStayDAONFTRoyaltyVault,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    uint16 public constant ROYALTY_DECIMALS = 10000;
    uint256 public mintRoyalty;
    uint256 public secondaryRoyalty;
    uint16[] public mintRoyaltyShares;
    uint16[] public secondaryRoyaltyShares;
    address[] public mintRoyaltyRecipients;
    address[] public secondaryRoyaltyRecipients;

    mapping(address => uint256) public mintRoyaltyClaimables;
    mapping(address => uint256) public secondaryRoyaltyClaimables;

    receive() external payable {
        secondaryRoyalty += msg.value;
    }

    function initialize() external initializer {
        __Ownable_init();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function setMintRoyalty(
        address[] calldata recipients,
        uint16[] calldata shares
    ) external onlyOwner {
        mintRoyaltyRecipients = recipients;
        mintRoyaltyShares = shares;
    }

    function setSecondaryRoyalty(
        address[] calldata recipients,
        uint16[] calldata shares
    ) external onlyOwner {
        secondaryRoyaltyRecipients = recipients;
        secondaryRoyaltyShares = shares;
    }

    function receiveMintFunds() external payable override {
        mintRoyalty += msg.value;
    }

    function snapshotMintRoyaltyClaimables() external whenNotPaused {
        uint256 mintSnapshot = mintRoyalty;
        mintRoyalty = 0;
        for (uint256 i = 0; i < mintRoyaltyRecipients.length; ++i) {
            mintRoyaltyClaimables[mintRoyaltyRecipients[i]] +=
                (mintSnapshot * mintRoyaltyShares[i]) /
                ROYALTY_DECIMALS;
        }
    }

    function snapshotSecondaryRoyaltyClaimables() external whenNotPaused {
        uint256 secondarySnapshot = secondaryRoyalty;
        secondaryRoyalty = 0;
        for (uint256 i = 0; i < secondaryRoyaltyRecipients.length; ++i) {
            secondaryRoyaltyClaimables[secondaryRoyaltyRecipients[i]] +=
                (secondarySnapshot * secondaryRoyaltyShares[i]) /
                ROYALTY_DECIMALS;
        }
    }

    function withdrawMintRoyalty() external whenNotPaused nonReentrant {
        uint256 amount = mintRoyaltyClaimables[_msgSender()];
        mintRoyaltyClaimables[_msgSender()] = 0;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = payable(_msgSender()).call{
            value: amount
        }("");
        require(success, string(data));
    }

    function withdrawSecondaryRoyalty() external whenNotPaused nonReentrant {
        uint256 amount = secondaryRoyaltyClaimables[_msgSender()];
        secondaryRoyaltyClaimables[_msgSender()] = 0;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = payable(_msgSender()).call{
            value: amount
        }("");
        require(success, string(data));
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
