// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./ERC1155Upgradeable.sol";
import "./ISeenHausNFT.sol";
import "./IERC2981.sol";
import "./MarketClientBase.sol";
import "./SeenHausNFTStorage.sol";

/**
 * @title SeenHausNFT
 * @notice This is the Seen.Haus ERC-1155 NFT contract.
 *
 * Key features:
 * - Supports the ERC-2981 NFT Royalty Standard
 * - Tracks the original creator of each token.
 * - Tracks which tokens have a physical part
 * - Logically capped token supplies; a token's supply cannot be increased after minting.
 * - Only ESCROW_AGENT-roled addresses can mint physical NFTs.
 * - Only MINTER-roled addresses can mint digital NFTs, e.g., Seen.Haus staff, approved artists.
 * - Newly minted NFTs are automatically transferred to the MarketController and consigned
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract SeenHausNFT is SeenHausNFTStorage, ISeenHausNFT, MarketClientBase, ERC1155Upgradeable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Initializer
     */
    function initialize(address _initOwner)
    public {
        __ERC1155_init("");
        _transferOwnership(_initOwner);
    }

    /**
     * @notice The nextToken getter
     * @dev does not increment counter
     */
    function getNextToken()
    external view override
    returns (uint256)
    {
        return nextToken;
    }

    /**
     * @notice Get the info about a given token.
     *
     * @param _tokenId - the id of the token to check
     * @return tokenInfo - the info about the token. See: {SeenTypes.Token}
     */
    function getTokenInfo(uint256 _tokenId)
    external view override
    returns (Token memory tokenInfo)
    {
        return tokens[_tokenId];
    }

    /**
     * @notice Check if a given token id corresponds to a physical lot.
     *
     * @param _tokenId - the id of the token to check
     */
    function isPhysical(uint256 _tokenId)
    public view override
    returns (bool) {
        Token memory token = tokens[_tokenId];
        return token.isPhysical;
    }

    /**
     * @notice Mint a given supply of a token, optionally flagging as physical.
     *
     * Token supply is sent to the MarketController.
     *
     * @param _supply - the supply of the token
     * @param _creator - the creator of the NFT (where the royalties will go)
     * @param _tokenURI - the URI of the token metadata
     * @param _royaltyPercentage - the percentage of royalty expected on secondary market sales
     * @param _isPhysical - whether the NFT should be flagged as physical or not
     */
    function mint(uint256 _supply, address payable _creator, string memory _tokenURI, uint16 _royaltyPercentage, bool _isPhysical)
    internal
    returns(Consignment memory consignment)
    {
        // Get the MarketController
        IMarketController marketController = getMarketController();

        // Make sure royalty percentage is acceptable
        require(_royaltyPercentage <= marketController.getMaxRoyaltyPercentage(), "Royalty percentage exceeds marketplace maximum");

        // Get the next token id
        uint256 tokenId = nextToken++;

        // Store the token info
        Token storage token = tokens[tokenId];
        token.id = tokenId;
        token.uri = _tokenURI;
        token.supply = _supply;
        token.creator = _creator;
        token.isPhysical = _isPhysical;
        token.royaltyPercentage = _royaltyPercentage;

        // Mint the token, sending it to the MarketController
        _mint(address(marketController), tokenId, _supply, new bytes(0x0));

        // Consign the token for the primary market
        consignment = marketController.registerConsignment(Market.Primary, msg.sender, _creator, address(this), tokenId, _supply);
    }

    /**
     * @notice Mint a given supply of a token, marking it as physical.
     *
     * Entire supply must be minted at once.
     * More cannot be minted later for the same token id.
     * Can only be called by an address with the ESCROW_AGENT role.
     * Token supply is sent to the MarketController.
     *
     * @param _supply - the supply of the token
     * @param _creator - the creator of the NFT (where the royalties will go)
     * @param _tokenURI - the URI of the token metadata
     * @param _royaltyPercentage - the percentage of royalty expected on secondary market sales
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     *
     * @return consignment - the registered primary market consignment of the newly minted token
     */
    function mintPhysical(uint256 _supply, address payable _creator, string memory _tokenURI, uint16 _royaltyPercentage)
    external override
    onlyRole(ESCROW_AGENT)
    returns(Consignment memory consignment)
    {
        // Mint the token, flagging it as physical, consigning to the MarketController
        return mint(_supply, _creator, _tokenURI, _royaltyPercentage, true);
    }

    /**
     * @notice Mint a given supply of a token.
     *
     * Entire supply must be minted at once.
     * More cannot be minted later for the same token id.
     * Can only be called by an address with the MINTER role.
     * Token supply is sent to the caller's address.
     *
     * @param _supply - the supply of the token
     * @param _creator - the creator of the NFT (where the royalties will go)
     * @param _tokenURI - the URI of the token metadata
     * @param _royaltyPercentage - the percentage of royalty expected on secondary market sales
     *
     * N.B. Represent percentage value as an unsigned int by multiplying the percentage by 100:
     * e.g, 1.75% = 175, 100% = 10000
     *
     * @return consignment - the registered primary market consignment of the newly minted token
     */
    function mintDigital(uint256 _supply, address payable _creator, string memory _tokenURI, uint16 _royaltyPercentage)
    external override
    onlyRole(MINTER)
    returns(Consignment memory consignment)
    {
        // Mint the token, consigning to the MarketController
        return mint(_supply, _creator, _tokenURI, _royaltyPercentage, false);
    }

    /**
     * @notice Get royalty info for a token
     *
     * For a given token id and sale price, how much should be sent to whom as royalty
     *
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     *
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _value sale price
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external view override
    returns (address receiver, uint256 royaltyAmount)
    {
        Token storage token = tokens[_tokenId];
        receiver = token.creator;
        royaltyAmount = getPercentageOf(_salePrice, token.royaltyPercentage);
    }

    /**
     * @notice Implementation of the {IERC165} interface.
     *
     * N.B. This method is inherited from several parents and
     * the compiler cannot decide which to use. Thus, they must
     * be overridden here.
     *
     * if you just call super.supportsInterface, it chooses
     * 'the most derived contract'. But that's not good for this
     * particular function because you may inherit from several
     * IERC165 contracts, and all concrete ones need to be allowed
     * to respond.
     */
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Upgradeable, IERC165Upgradeable)
    returns (bool)
    {
        return (
            interfaceId == type(ISeenHausNFT).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }

    /**
     * @notice Get the token URI
     *
     * This method is overrides the Open Zeppelin version, returning
     * a unique stored metadata URI for each token rather than a
     * replaceable baseURI template, since the latter is not compatible
     * with IPFS hashes.
     *
     * @param _tokenId - id of the token to get the URI for
     */
    function uri(uint256 _tokenId)
    public view override
    returns (string memory)
    {
        Token storage token = tokens[_tokenId];
        return token.uri;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}