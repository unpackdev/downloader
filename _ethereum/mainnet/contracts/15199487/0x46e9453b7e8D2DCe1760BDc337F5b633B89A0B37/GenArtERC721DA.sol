// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./IERC165.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./GenArtAccess.sol";
import "./IGenArtMembership.sol";
import "./IGenArtPaymentSplitterV2.sol";
import "./IGenArtInterface.sol";
import "./GenArtDutchAuctionHouse.sol";

/**
 * @dev GEN.ART ERC721 V2
 * Implements the extentions {IERC721Enumerable} and {IERC2981}.
 * Inherits access control from {GenArtAccess}.
 * Sends all ETH to a {PaymentSplitter} contract.
 * Restricts minting to GEN.ART Membership holders.
 * IMPORTANT: This implementation requires the royalties to be send to the contracts address
 * in order to split the funds between payees automatically.
 */
contract GenArtERC721DA is ERC721Enumerable, GenArtAccess, IERC2981 {
    using Strings for uint256;
    using MintStateDA for MintStateDA.State;

    uint256 public _mintSupply;
    address public _royaltyReceiver = address(this);
    uint256 public _royaltyPoints;
    uint256 public _collectionId;
    bool private _reservedMinted;
    address public _genartInterface;
    address public _wethAddress;
    GenArtDutchAuctionHouse public _genartDA;
    string private _uri;
    string private _script;
    bool public _paused = true;

    /**
     *@dev Emitted on mint
     */
    event Mint(
        uint256 tokenId,
        uint256 collectionId,
        uint256 membershipId,
        address to
    );

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri_,
        string memory script_,
        uint256 collectionId_,
        uint256 mintSupply_,
        address genartInterface_,
        address wethAddress_,
        address genartDA_
    ) ERC721(name_, symbol_) GenArtAccess() {
        _uri = uri_;
        _script = script_;
        _collectionId = collectionId_;
        _mintSupply = mintSupply_;
        _genartInterface = genartInterface_;
        _wethAddress = wethAddress_;
        _genartDA = GenArtDutchAuctionHouse(payable(genartDA_));
        _mintOne(genartAdmin, 0);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     *@dev Get amount of mints for a membershipId
     */
    function getMembershipMints(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return _genartDA.getMintsByMembership(address(this), membershipId);
    }

    /**
     *@dev Get available mints for a membershipId
     */
    function getAvailableMintsForMembership(uint256 membershipId)
        public
        view
        returns (uint256)
    {
        return
            _genartDA.getAvailableMintsByMembership(
                address(this),
                membershipId
            );
    }

    /**
     *@dev Check if minter has available mint slots and has sent the required amount of ETH
     * Revert in case minting is paused or checks fail.
     */
    function checkMint(
        uint256 amount,
        uint256 availableMints,
        uint256 auctionStatus
    ) internal view {
        require(!_paused, "GenArtERC721DA: minting is paused");
        require(
            availableMints > 0 && totalSupply() + amount <= _mintSupply,
            "GenArtERC721DA: no mints available"
        );
        require(
            _genartDA.getAuctionStatus(address(this)) == auctionStatus,
            "GenArtERC721DA: not allowed to mint"
        );
        require(
            availableMints >= amount,
            "GenArtERC721DA: amount exceeds availableMints"
        );
        uint256 ethAmount;
        unchecked {
            ethAmount = _genartDA.getAuctionPrice(address(this)) * amount;
        }
        require(ethAmount == msg.value, "GenArtERC721DA: wrong amount sent");
    }

    /**
     *@dev Public function to mint the desired amount of tokens
     * Requirments:
     * - sender must be GEN.ART Membership owner
     */
    function mint(address to, uint256 amount) public payable {
        // get all available mints for sender
        uint256 availableMints = IGenArtInterface(_genartInterface)
            .getAvailableMintsForAccount(address(this), _msgSender());
        checkMint(amount, availableMints, 1);
        // get all memberships for sender
        uint256[] memory memberships = IGenArtInterface(_genartInterface)
            .getMembershipsOf(_msgSender());
        uint256 minted;
        uint256 i;
        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // get available mints for membership
            uint256 mints = getAvailableMintsForMembership(memberships[i]);
            // mint tokens with membership and stop if desired amount reached
            uint256 j;
            for (j = 0; j < mints && minted < amount; j++) {
                mintForMembership(to, memberships[i]);
                // update mint state once membership minted a token
                minted++;
            }
            _genartDA.saveMint(memberships[i], msg.sender, j);
            i++;
        }
        _genartDA.sendFunds{value: msg.value}();
    }

    /**
     *@dev Public function to mint one token for a GEN.ART Membership
     * Requirments:
     * - sender must own the membership
     */
    function mintOne(address to, uint256 membershipId) public payable {
        // check if sender is owner of membership
        require(
            IGenArtInterface(_genartInterface).ownerOfMembership(
                membershipId
            ) == _msgSender(),
            "GenArtERC721DA: sender is not membership owner"
        );
        // get available mints for membership
        uint256 availableMints = getAvailableMintsForMembership(membershipId);

        checkMint(1, availableMints, 1);
        // mint token
        mintForMembership(to, membershipId);
        // update mint state once membership minted a token
        _genartDA.saveMint(membershipId, msg.sender, 1);
        _genartDA.sendFunds{value: msg.value}();
    }

    function mintPublic(address to, uint8 amount) public payable {
        // get available mints for membership
        uint256 availableMints = _genartDA.getAuction(address(this)).supply -
            totalSupply();
        checkMint(amount, availableMints, 2);
        // mint token
        for (uint8 i; i < amount; i++) {
            _mintOne(to, 0);
        }
        // update mint state once membership minted a token
        _genartDA.sendFunds{value: msg.value}();
    }

    /**
     *@dev Mint token for membership
     */
    function mintForMembership(address to, uint256 membershipId) internal {
        _mintOne(to, membershipId);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     * Emits a {Mint} event.
     */
    function _mintOne(address to, uint256 membershipId) internal virtual {
        uint256 tokenId = _collectionId * 100_000 + totalSupply() + 1;
        _safeMint(to, tokenId);
        emit Mint(tokenId, _collectionId, membershipId, to);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);
        // check if sender is owner of token
        require(
            _msgSender() == owner,
            "GenArtERC721DA: burn caller is not owner"
        );
        _burn(tokenId);
    }

    /**
     * @dev Get royalty info see {IERC2981}
     */
    function royaltyInfo(uint256, uint256 salePrice_)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (_royaltyReceiver, (_royaltyPoints * salePrice_) / 10_000);
    }

    /**
     *@dev Get all tokens owned by an address
     */
    function getTokensByOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokenIds;
    }

    /**
     *@dev Pause and unpause minting
     */
    function setPaused(bool paused) public onlyAdmin {
        _paused = paused;
    }

    /**
     *@dev Set receiver of royalties
     */
    function setRoyaltyInfo(address receiver, uint256 royaltyPoints)
        public
        onlyGenArtAdmin
    {
        _royaltyReceiver = receiver;
        _royaltyPoints = royaltyPoints;
    }

    /**
     * @dev Set base uri
     */
    function setBaseURI(string memory uri) public onlyGenArtAdmin {
        _uri = uri;
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }
}
