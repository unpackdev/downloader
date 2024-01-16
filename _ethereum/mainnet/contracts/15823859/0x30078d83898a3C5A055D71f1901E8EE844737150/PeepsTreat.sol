// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title PeepsTreat
/// @author MilkyTaste @ Ao Collaboration Ltd.

import "./ERC721AQueryable.sol";
import "./IERC721.sol";
import "./Payable.sol";

contract PeepsTreat is ERC721AQueryable, Payable {
    string public baseURI;

    struct MintDetails {
        uint16 maxSupply;
        uint8 minMint;
        uint8 maxMint;
        uint64 mintClose;
        uint256 price;
    }

    MintDetails public mintDetails;
    IERC721 public peepsClub;

    constructor(
        uint16 _maxSupply,
        uint8 _minMint,
        uint8 _maxMint,
        uint64 _mintClose,
        uint256 _price
    ) ERC721A("PeepsTreat", "TREAT") Payable(1000) {
        mintDetails = MintDetails(_maxSupply, _minMint, _maxMint, _mintClose, _price);
    }

    modifier senderCanMint() {
        require(block.timestamp < mintDetails.mintClose, "PeepsTreat: Mint closed");
        require(totalSupply() < mintDetails.maxSupply, "PeepsTreat: Max supply reached");
        _;
    }

    //
    // Mint
    //

    /**
     * Public mint.
     */
    function mintPublic() external payable senderCanMint {
        require(msg.value >= mintDetails.price, "PeepsTreat: Wrong price");
        _mint(msg.sender);
    }

    /**
     * Peeps mint.
     * @param peepId The Id of a Peep you own.
     */
    function mintPeeps(uint256 peepId) external senderCanMint {
        require(peepsClub.ownerOf(peepId) == msg.sender, "PeepsTreat: Not peep owner");
        _mint(msg.sender);
    }

    /**
     * Airdrop.
     * @param to The address to recieve the airdrop.
     */
    function mintAirdrop(address to) external onlyOwner {
        _mint(to);
    }

    function _mint(address to) internal {
        // Pseudo-random amount
        uint256 amount = (uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) %
            (mintDetails.maxMint - mintDetails.minMint)) + mintDetails.minMint;
        if (totalSupply() + amount > mintDetails.maxSupply) {
            amount = mintDetails.maxSupply - totalSupply();
        }
        super._mint(to, amount);
    }

    //
    // Admin
    //

    /**
     * Update URI.
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * Update the Peeps Club address.
     * @param _peepsClub The Peeps Club address.
     */
    function setPeepsClub(address _peepsClub) external onlyOwner {
        peepsClub = IERC721(_peepsClub);
    }

    /**
     * Update mint details.
     * @param when The new close date.
     * @param price The new price for non-peeps holders.
     * @dev Not all mint details are updatable.
     */
    function updateMintDetails(uint64 when, uint256 price) external onlyOwner {
        mintDetails = MintDetails(mintDetails.maxSupply, mintDetails.minMint, mintDetails.maxMint, when, price);
    }

    //
    // Views
    //

    /**
     * Returns when the mint closes.
     * @return when When the mint closes.
     */
    function mintCloseAt() public view returns (uint64 when) {
        return mintDetails.mintClose;
    }

    /**
     * Checks if an address can mint.
     * @return can If the caller can mint.
     */
    function canMint() external view returns (bool can) {
        return totalSupply() < mintDetails.maxSupply && block.timestamp < mintCloseAt();
    }

    /**
     * Returns the price.
     * @return price The price.
     */
    function getPrice() external view returns (uint256 price) {
        return mintDetails.price;
    }

    /**
     * Returns the starting token ID.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId The token id.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
