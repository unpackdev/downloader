//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.18;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./IWatchersRing.sol";

// This is the main building block for smart contracts.
contract WatchersRing is ERC721, Ownable, ReentrancyGuard, IWatchersRing {
    using Strings for uint256;

    /// @notice Maximum supply of total rings.
    uint256 private constant MAX_SUPPLY = 700;

    /// @notice Counter to track the number minted so far.
    uint256 public numMinted;

    /// @notice Address of only-valid minter.
    address public minterAddress;

    /// @notice The base URI for the metadata of the tokens.
    string public baseTokenURI;

    error NoRingsAvailable();
    error Address0Error();

    /// @notice Whitelist for markets.
    mapping(address => bool) private _deniedMarketplaces;

    string private constant R = "I should like to save the Shire, if I could";

    /**
     * @dev Constructor of the contract.
     * @param baseURI string The initial base URI for the token metadata URL.
     * @notice We pass the name and symbol to the ERC721 constructor.
     */
    constructor(string memory baseURI) ERC721("WatchersRing", "WR") {
        baseTokenURI = baseURI;
    }

    /**
     * @dev Mint a new token with a specific id.
     * @param recipient address representing the owner of the new tokenId.
     * @param tokenId uint256 ID of the token to be minted.
     * @param rtype RingType to be minted.
     */
    function mintTokenId(
        address recipient,
        uint256 tokenId,
        WatchersRingType rtype
    ) public override nonReentrant {
        if (numMinted >= MAX_SUPPLY) {
            revert NoRingsAvailable();
        }

        require(_msgSender() == minterAddress, "Not a minter");

        ++numMinted;
        emit WatchersRingMinted(recipient, tokenId, rtype);

        _safeMint(recipient, tokenId);
    }

    /**
     * @dev Returns the URL of a given tokenId.
     * @param tokenId uint256 with ID of the token to be minted.
     * @return string the URL of a given tokenId.
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(baseTokenURI, tokenId.toString()));
    }

    /**
     *
     * @dev Returns the base URL of the token metadata.
     * @return string the base URL of the token metadata.
     */
    function getTokenURI() public view returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Returns if the token exists.
     * @param tokenId uint256 with the ID of the token.
     * @return exists bool if it exists.
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Returns the total number of minted lands.
     * @return totalSupply uint256 the number of minted lands.
     */
    function totalSupply() external view returns (uint256) {
        return numMinted;
    }

    /**
     * Only the owner can do these things.
     */

    /**
     * @dev Sets a new base URI.
     * @param newBaseURI string the new token base URI.
     */
    function setBaseURI(string calldata newBaseURI) public onlyOwner {
        baseTokenURI = newBaseURI;
    }

    /**
     * @dev Sets a new minter address.
     * @param newMinter Address of the new minter.
     */
    function setMinter(address newMinter) external onlyOwner {
        require(newMinter != address(0), "Invalid minter address");
        minterAddress = newMinter;
    }

    /**
     * @notice Override of the approve method to blacklist markets.
     * @param to Address to approve transfer.
     * @param tokenId Token be transferred allowed by to.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        require(!_deniedMarketplaces[to], "Invalid Marketplace");
        super.approve(to, tokenId);
    }

    /**
     * @notice Override of the setApprovalForAll method to blacklist markets.
     * @param operator Address to approve transfer.
     * @param approved Enable or disable transfer.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override {
        require(!_deniedMarketplaces[operator], "Invalid Marketplace");
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Override of the isApprovedForAll method to blacklist markets.
     * Reverts if is not allowed.
     * @param owner Address Owner of the tokens.
     * @param operator Address Marketplace address.
     * @return true if all the tokens are approved to be trasnferred by operator.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        require(!_deniedMarketplaces[operator], "Invalid Marketplace");
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Override of the getApproved method to blacklist markets.
     * Reverts if is not allowed.
     * @param tokenId ID of the token to check if is approved.
     * @return address that is allowed to transfer the tokenId.
     */
    function getApproved(
        uint256 tokenId
    ) public view virtual override returns (address) {
        address addr = super.getApproved(tokenId);
        require(!_deniedMarketplaces[addr], "Invalid Marketplace");
        return addr;
    }

    /**
     * @notice Add or remove an address for the market blacklist.
     * @param market Address Market place address.
     * @param denied Deny (true) or allow (false) a marketplace.
     */
    function setDeniedMarketplace(
        address market,
        bool denied
    ) public onlyOwner {
        _deniedMarketplaces[market] = denied;
    }

    /**
     * @dev ETH should not be sent to this contract, but in the case that it is
     * sent by accident, this function allows the owner to withdraw it.
     */
    function withdrawAll() external payable onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "withdraw was not succesfull");
    }

    /**
     * @dev Again, ERC20s should not be sent to this contract, but if someone
     * does, it's nice to be able to recover them.
     * @param token IERC20 The token address.
     * @param amount uint256 The amount to send.
     */
    function forwardERC20s(IERC20 token, uint256 amount) external onlyOwner {
        if (address(msg.sender) == address(0)) {
            revert Address0Error();
        }
        token.transfer(msg.sender, amount);
    }
}
