// SPDX-License-Identifier: MIT
// Clopr Contracts

pragma solidity 0.8.21;

import "./Ownable.sol";
import "./AccessControl.sol";
import "./ERC721.sol";
import "./ERC165.sol";
import "./Strings.sol";
import "./IAccessControl.sol";
import "./IERC721Metadata.sol";
import "./IERC721.sol";
import "./IERC165.sol";
import "./IStoryPotionTank.sol";
import "./ICloprBottles.sol";
import "./IDelegateRegistry.sol";

/**
 * @title StoryPotionTank
 * @author Pybast.eth - Nefture
 * @custom:lead Antoine Bertin - Clopr
 * @dev Handles the distribution and management of StoryPotion, vital ingredients required for creating and enhancing CloprStories.
 */
contract StoryPotionTank is Ownable, AccessControl, ERC721, IStoryPotionTank {
    using Strings for uint256;

    /// @dev base URI used to retrieve the StoryPotion's tank token metadata
    string private baseUri;

    /// @dev role to modify StoryPotion's fill price
    bytes32 private constant MODIFY_FILL_PRICE_ROLE =
        keccak256("MODIFY_FILL_PRICE_ROLE");

    /// @dev delegate cash V2 contract
    IDelegateRegistry private constant DC =
        IDelegateRegistry(0x00000000000000447e69651d841bD8D104Bed493);

    /// @dev maximum number of fills available
    uint16 public constant POTION_TANK_MAX_SUPPLY = 40_000;

    uint16 public constant STORY_POTION_ID = 42;

    /// @dev CloprBottles' smart contract address
    ICloprBottles private constant BOTTLES_CONTRACT =
        ICloprBottles(0xB0711E51eef597FA03bfF2CbFea3Dc4d3C4f6906);

    /// @dev supply of the StoryPotion tank
    uint16 private potionTankSupply;
    /// @dev price of each fill
    uint64 private fillPrice;

    constructor(string memory baseUri_) ERC721("StoryPotionTank", "SPT") {
        if (bytes(baseUri_).length == 0) revert BaseUriCantBeNull();

        fillPrice = 0.0042 ether;
        potionTankSupply = POTION_TANK_MAX_SUPPLY;
        baseUri = baseUri_;

        _mint(0xCa540A0d3B37d605c1Af7Eb9D022C6D48B23198c, 42);

        _grantRole(
            DEFAULT_ADMIN_ROLE,
            0x799B7627f972dcf97b00bBBC702b2AD1b7546519
        );
        _transferOwnership(0x799B7627f972dcf97b00bBBC702b2AD1b7546519);
    }

    /**
     * ----------- EXTERNAL -----------
     */

    /// @inheritdoc IStoryPotionTank
    function adminChangeFillPrice(
        uint64 newPrice
    ) external onlyRole(MODIFY_FILL_PRICE_ROLE) {
        fillPrice = newPrice;

        emit NewFillPrice(newPrice);
    }

    /// @inheritdoc IStoryPotionTank
    function fillBottle(uint256 bottleTokenId, address vault) external payable {
        address requester = msg.sender;

        if (vault != address(0)) {
            bool isDelegateValid = DC.checkDelegateForERC721(
                msg.sender,
                vault,
                address(BOTTLES_CONTRACT),
                bottleTokenId,
                ""
            );

            if (!isDelegateValid) revert InvalidDelegateVaultPairing();

            requester = vault;
        }

        if (msg.value != fillPrice) revert BadFillPrice();
        if (potionTankSupply == 0) revert EmptyStoryPotionTank();

        unchecked {
            potionTankSupply -= 1;
        }

        BOTTLES_CONTRACT.fillBottle(
            bottleTokenId,
            STORY_POTION_ID,
            false,
            requester
        );
    }

    /**
     * ----------- ADMIN -----------
     */

    /// @inheritdoc IStoryPotionTank
    function withdraw(address receiver) external onlyOwner {
        // slither-disable-next-line incorrect-equality
        if (address(this).balance == 0) revert NothingToWithdraw();
        if (receiver == address(0)) revert CantWithdrawToZeroAddress();

        // slither-disable-next-line low-level-calls
        (bool sent, ) = receiver.call{value: address(this).balance}("");
        if (!sent) revert FailedToWithdraw();
    }

    /// @inheritdoc IStoryPotionTank
    function changeDefaultBaseUri(string memory newBaseUri) external onlyOwner {
        if (bytes(newBaseUri).length == 0) revert BaseUriCantBeNull();

        baseUri = newBaseUri;
        emit NewBaseUri(newBaseUri);
    }

    /**
     * ----------- ENUMERATIONS -----------
     */

    /// @inheritdoc IStoryPotionTank
    function getPotionTankSupply()
        external
        view
        returns (uint16 potionTankSupply_)
    {
        potionTankSupply_ = potionTankSupply;
    }

    /// @inheritdoc IStoryPotionTank
    function getFillPrice() external view returns (uint64 fillPrice_) {
        fillPrice_ = fillPrice;
    }

    /// @notice Get a Story Potion's metadata URI
    /// @dev See {IERC721Metadata-tokenURI}
    /// @param tokenId token ID of the StoryPotion tank
    /// @return tokenURI_ the URI of the token
    /// @inheritdoc IERC721Metadata
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);

        uint256 potionLeftPercentage = (uint256(potionTankSupply) * 100) /
            POTION_TANK_MAX_SUPPLY;

        return
            string(abi.encodePacked(baseUri, potionLeftPercentage.toString()));
    }

    /**
     * ----------- ERC165 -----------
     */

    /// @notice Know if a given interface ID is supported by this contract
    /// @dev This function overrides ERC721
    /// @param interfaceId ID of the interface
    /// @return supports_ is the interface supported
    /// @inheritdoc	ERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(ERC721, AccessControl) returns (bool supports_) {
        supports_ =
            interfaceId == type(IERC721).interfaceId || // ERC165 interface ID for ERC721.
            interfaceId == type(IERC721Metadata).interfaceId || // ERC165 interface ID for ERC721Metadata.
            interfaceId == type(IAccessControl).interfaceId || // ERC165 interface id for AccessControl
            interfaceId == type(IERC165).interfaceId; // ERC165 interface id for ERC165
    }
}
