// SPDX-License-Identifier: CC0 1.0 Universal

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.19;

import "./MultiOwner.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./IERC2981.sol";

import "./Wawa.sol";

/// @title WawaNFT
contract WawaNFT is MultiOwner, IERC2981, ReentrancyGuard, ERC721Enumerable {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    address payable public immutable treasuryAddress;

    uint256 public constant PRICE = 0.05 ether;

    /// @notice get for second market ratio.
    uint256 public secondaryRoyalty;
    uint256 private constant _MAX_SECONDARY_ROYALITY_FEE = 10_000;
    uint256 public paymentBalanceOwner;
    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    mapping(uint256 tokenId => bool) public created;
    mapping(uint256 tokenId => Wawa wawa) private allWawa;
    mapping(Faction faction => uint256) private factionCount;
    mapping(uint8 petId => uint256) private petCount;
    mapping(string tokenURI => bool) private createdTokenURI;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event LogGetWawa(
        address indexed sender,
        address indexed user,
        uint256 indexed tokenId,
        Faction faction,
        uint8 petId,
        Trait trait,
        string tokenURI,
        bytes32 gene,
        uint256 timestamp
    );
    event SetTokenURI(uint256 indexed tokenId, string uri);
    event SetFaction(uint256 indexed tokenId, Faction faction);
    event SetPetId(uint256 indexed tokenId, uint8 petId);
    event SetTrait(uint256 indexed tokenId, Trait trait);
    event SetGene(uint256 indexed tokenId, bytes32 gene);
    event SetSecondaryRoyalityFee(uint256 secondaryRoyalty);
    event PaymentWithdrawnOwner(uint256 amount);
    event PaymentReceivedOwner(uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error ZeroAddressNotAllowed();
    error InvalidTokenID();
    error FailedPaymentToTreasury();
    error SentAmountDoesNotMatch();
    error TokenURIAlreadyUsed();
    error PaymentBalanceZero();
    error InvalidSecondaryRoyalityFee(uint256 value);

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */

    constructor(address payable _treasuryAddress) ERC721("Wawa", "Phi-Wawa") {
        if (_treasuryAddress == address(0)) revert ZeroAddressNotAllowed();
        treasuryAddress = _treasuryAddress;
        secondaryRoyalty = 0;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  TOKEN URI                                 */
    /* -------------------------------------------------------------------------- */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!created[tokenId]) revert InvalidTokenID();
        return getTokenURI(tokenId);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   METHOD                                   */
    /* -------------------------------------------------------------------------- */

    /* --------------------------------- SETTER --------------------------------- */
    function setFaction(uint256 tokenId, Faction faction) public virtual onlyOwner {
        allWawa[tokenId].faction = faction;
        emit SetFaction(tokenId, faction);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public virtual onlyOwner {
        if (createdTokenURI[_tokenURI]) revert TokenURIAlreadyUsed();

        createdTokenURI[_tokenURI] = true;
        allWawa[tokenId].tokenURI = _tokenURI;

        emit SetTokenURI(tokenId, _tokenURI);
    }

    // should check pet owner can change petId
    function setPet(uint256 tokenId, uint8 petId) public virtual onlyOwner {
        uint8 oldPetId = allWawa[tokenId].petId;
        if (oldPetId != petId) {
            if (oldPetId > 0) {
                --petCount[oldPetId];
            }
            ++petCount[petId];
        }
        allWawa[tokenId].petId = petId;
        emit SetPetId(tokenId, petId);
    }

    function setGene(uint256 tokenId, bytes32 gene) public virtual onlyOwner {
        allWawa[tokenId].gene = gene;
        emit SetGene(tokenId, allWawa[tokenId].gene);
    }

    function setTrait(uint256 tokenId, Trait memory trait) public virtual onlyOwner {
        allWawa[tokenId].trait = trait;
        emit SetTrait(tokenId, trait);
    }

    // /* --------------------------------- GETTER --------------------------------- */
    function getFaction(uint256 tokenId) external view returns (Faction) {
        return allWawa[tokenId].faction;
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return allWawa[tokenId].tokenURI;
    }

    function getWawaInfo(uint256 tokenId) external view returns (Wawa memory) {
        return allWawa[tokenId];
    }

    function getFactionCount(Faction faction) external view returns (uint256) {
        return factionCount[faction];
    }

    function getPetCount(uint8 petId) external view returns (uint256) {
        return petCount[petId];
    }

    /* -------------------------------------------------------------------------- */
    /*                                Mint METHOD                                 */
    /* -------------------------------------------------------------------------- */
    /*
    * @title getWawa
    * @notice mint Wawa to verify user
    * @param to : receiver address
    * @param tokenId : object nft token_id
    * @dev onlyOwner method. Generally, this method is invoked by GetWawa contract
    */
    function getWawa(
        address to,
        uint256 tokenId,
        string calldata _tokenURI,
        Faction faction,
        Trait calldata trait,
        uint8 petId,
        bytes32 gene
    )
        external
        payable
        nonReentrant
        onlyOwner
    {
        // check if the function caller is not a zero account address
        if (to == address(0)) revert ZeroAddressNotAllowed();

        // Amount sent in to buy should be equal to the token's price
        if (msg.value != PRICE) revert SentAmountDoesNotMatch();

        // Setting the Wawa
        setTokenURI(tokenId, _tokenURI);
        setTrait(tokenId, trait);
        setPet(tokenId, petId);
        setGene(tokenId, gene);
        setFaction(tokenId, faction);
        ++factionCount[faction];

        (bool success,) = payable(treasuryAddress).call{ value: PRICE }("");
        if (!success) revert FailedPaymentToTreasury();

        // Mint the token
        created[tokenId] = true;
        super._safeMint(to, tokenId);

        emit LogGetWawa(msg.sender, to, tokenId, faction, petId, trait, _tokenURI, gene, block.timestamp);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Royalty METHOD                               */
    /* -------------------------------------------------------------------------- */
    /* --------------------------------- PUBLIC --------------------------------- */
    /// @notice EIP2981 royalty standard
    function royaltyInfo(
        uint256,
        uint256 salePrice
    )
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = address(this);
        royaltyAmount = (salePrice * secondaryRoyalty) / 10_000;
        return (receiver, royaltyAmount);
    }

    /// @notice Receive royalties
    receive() external payable {
        _addToOwnerBalance(msg.value);
    }

    /// @notice Adds funds to the payment balance for the owner.
    /// @param amount The amount to add to the balance.
    function _addToOwnerBalance(uint256 amount) internal {
        paymentBalanceOwner += amount;
        emit PaymentReceivedOwner(amount);
    }

    function setSecondaryRoyalityFee(uint256 newSecondaryRoyalty) external onlyOwner {
        if (newSecondaryRoyalty > _MAX_SECONDARY_ROYALITY_FEE) {
            revert InvalidSecondaryRoyalityFee(newSecondaryRoyalty);
        }
        secondaryRoyalty = newSecondaryRoyalty;
        emit SetSecondaryRoyalityFee(newSecondaryRoyalty);
    }

    /// @notice Sends you your full available balance.
    /// @param withdrawTo The address to send the balance to.
    function withdrawOwnerBalance(address withdrawTo) external onlyOwner nonReentrant {
        if (withdrawTo == address(0)) revert ZeroAddressNotAllowed();
        if (paymentBalanceOwner == 0) revert PaymentBalanceZero();
        uint256 balance = paymentBalanceOwner;
        paymentBalanceOwner = 0;

        (bool success,) = withdrawTo.call{ value: balance }("");
        if (!success) revert PaymentBalanceZero();

        emit PaymentWithdrawnOwner(balance);
    }
}
