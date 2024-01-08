//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";

import "./PaymentRecipient.sol";
import "./Directory.sol";

contract Marketer is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    IERC721ReceiverUpgradeable,
    PaymentRecipient
{
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    Directory private _directory;

    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNOR_ROLE, _msgSender());
    }

    //
    // Modifiers
    //
    modifier isGovernor() {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Marketer: caller is not governor");
        _;
    }

    //
    // Generic and standard functions
    //
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    //
    // Admin functions
    //
    function setDirectoryAddress(address newAddress) public virtual isGovernor() {
        _directory = Directory(newAddress);
    }

    // TODO Implement exchange integrations (Wyvern Protocol, Rarible, etc.)
}
