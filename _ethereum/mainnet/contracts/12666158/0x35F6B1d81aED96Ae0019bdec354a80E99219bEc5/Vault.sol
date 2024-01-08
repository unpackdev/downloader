//SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./ReentrancyGuardUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";

import "./PaymentRecipient.sol";
import "./Directory.sol";
import "./Uniquettes.sol";

contract Vault is
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    IERC721ReceiverUpgradeable,
    PaymentRecipient
{
    bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    event UniquetteLiquidated(
        address indexed operator,
        address indexed owner,
        address beneficiary,
        uint256 indexed tokenId,
        uint256 collateralValue
    );

    Directory private _directory;

    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GOVERNOR_ROLE, _msgSender());
    }

    //
    // Modifiers
    //
    modifier isGovernor() {
        require(hasRole(GOVERNOR_ROLE, _msgSender()), "Vault: caller is not governor");
        _;
    }

    //
    // Admin functions
    //
    function setDirectoryAddress(address newDirectoryAddress) public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Vault: caller is not an admin");
        _directory = Directory(newDirectoryAddress);
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
    // Unique functions
    //
    function uniquetteLiquidate(uint256 tokenId, address payable beneficiary) public virtual nonReentrant {
        address operator = _msgSender();

        Uniquettes.Uniquette memory uniquette = _directory.uniquetteGetById(tokenId);

        require(
            uniquette.owner == operator || _directory.isApprovedForAll(uniquette.owner, operator),
            "Vault: not an owner or approved operator"
        );

        _directory.safeTransferFrom(uniquette.owner, address(this), tokenId);
        payable(address(beneficiary)).transfer(uniquette.collateralValue);

        //_directory.uniquetteForSale(tokenId, uniquette.collateralValue); TODO Allow to collect by paying just collateral value

        emit UniquetteLiquidated(operator, uniquette.owner, beneficiary, tokenId, uniquette.collateralValue);
    }
}
