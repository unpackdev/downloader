// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./IERC2981.sol";

contract MonoprixCollection is ERC721, Pausable, Ownable, IERC2981 {
    using Strings for uint256;
    using Address for address payable;

    // The maximum possible id for this collection
    // noting that the ids start at 1
    uint256 private immutable maxId;

    // The royalties taken on each sale. Can range from 0 to 10000
    // 1000 => 10%
    uint16 private constant ROYALTIES = 1000;

    // Price for one mint - 0.09 ETH
    uint256 public mintPrice = 90000000000000000;

    // From 0 to 10000 (to take 2 decimals into account)
    uint16 public immutable artistCommission;

    // Address receiving the funds
    address private fundsRecipient = 0x14bD21Bd869beb87A5910421D5ce29c972905a37;

    // Address of the artist
    address public artist;

    // Total supply minted so far
    uint256 public totalSupply;

    string public baseURI;

    constructor(
        string memory name,
        string memory symbol,
        uint16 _artistCommission,
        address _artist,
        string memory _baseUri,
        uint256 _maxId
    ) ERC721(name, symbol) {
        require(_artist != address(0), "Invalid address");
        artistCommission = _artistCommission;
        artist = _artist;
        baseURI = _baseUri;
        maxId = _maxId;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Mint a given token for the sender
     */
    function mint(uint256 tokenId) external payable {
        mintFor(msg.sender, tokenId);
    }

    /**
     * @dev Mint for a given address and a given token id
     */
    function mintFor(address to, uint256 tokenId) public payable {
        // Check the value given is correct
        require(msg.value == mintPrice, "Invalid value");
        // Raise the error instead of waiting for safeMint
        require(!_exists(tokenId), "Token already minted");
        // Only the ids in the predefined range are allowed
        require(tokenId >= 1 && tokenId <= maxId, "Invalid token id");
        // Mint the token
        _safeMint(to, tokenId);
        // Increase the supply by 1
        totalSupply += 1;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Set the price for minting a token
     */
    function setMintPrice(uint256 price) external onlyOwner {
        mintPrice = price;
    }

    /**
     * @dev Set the recipient of most of the funds of this contract
     * and all of the royalties
     */
    function setFundsRecipient(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");
        fundsRecipient = addr;
    }

    /**
     * @dev Set the address of the artist
     */
    function setArtist(address addr) external onlyOwner {
        require(addr != address(0), "Invalid address");
        artist = addr;
    }

    /**
     * @dev Retrieve the funds of the sale
     */
    function retrieveFunds() external {
        require(
            msg.sender == fundsRecipient ||
                msg.sender == artist ||
                msg.sender == owner(),
            "Not allowed"
        );
        uint256 artistBalance = (address(this).balance * artistCommission) /
            10000;
        // Sends the part owed to the artist...
        payable(artist).sendValue(artistBalance);
        // ...and sends all the rest to the recipient address
        payable(fundsRecipient).sendValue(address(this).balance);
    }

    /**
     * @dev Get the URI for a given token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    /**
     * @dev Check if the token exists or not
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = fundsRecipient;
        // We divide it by 10000 as the royalties can change from
        // 0 to 10000 representing percents with 2 decimals
        royaltyAmount = (salePrice * ROYALTIES) / 10000;
    }
}
