// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./PullPayment.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./AddressUpgradeable.sol";

import "./MegacyNFTFactory.sol";
import "./ERC721Tradable.sol";

// import "./ICollectionContractInitializer.sol";
import "./ICollectionFactory.sol";
// import "./IGetRoyalties.sol";
// import "./ITokenCreator.sol";
// import "./IGetFees.sol";
// import "./IRoyaltyInfo.sol";

import "./AccountMigrationLibrary.sol";
import "./ProxyCall.sol";
import "./BytesLibrary.sol";

contract MegacyNFTCollection is
    ERC721Tradable,
    PullPayment
{
    using AccountMigrationLibrary for address;
    using AddressUpgradeable for address;
    using BytesLibrary for bytes;
    using ProxyCall for IProxyCall;
    using Counters for Counters.Counter;

    uint256 private constant ROYALTY_IN_BASIS_POINTS = 1000;

    /**
     * We rely on the OZ Counter util to keep track of the next available ID.
     * We track the nextTokenId instead of the currentTokenId to save users on gas costs. 
     * Read more about it here: https://shiny.mirror.xyz/OUampBbIz9ebEicfGnQf5At_ReMHlZy0tB4glb9xQ0E
     */ 

    Counters.Counter private _nextTokenId;
    mapping(uint256 => string) _tokenURIs; /// @dev TokenURI for NFT metadata_updatable = false

    /**
     * @notice The factory which was used to create this collection.
     * @dev This is used to read common config.
     */
    ICollectionFactory public immutable collectionFactory;
    /**
     * @dev Stores an optional alternate address to receive creator revenue and royalty payments.
     * The target address may be a contract which could split or escrow payments.
     */
    mapping(uint256 => address payable) private tokenIdToCreatorPaymentAddress;

    address payable factoryAddress;

    event CollectionMinted(address _to, string _uri, uint256 _tokenId);
    event CollectionInitiated(address _contractOwner, string namecollection);
    event LogDepositReceived(address _from, uint _amount);

    // /**
    //  * @notice Called by the factory on creation.
    //  * @param _creator The creator of this collection contract.
    //  * @param _name The name of this collection.
    //  * @param _symbol The symbol for this collection.
    //  */
    // function initialize(
    //     address payable _creator,
    //     string calldata _name,
    //     string calldata _symbol
    // ) external initializer {
    //     require(msg.sender == address(collectionFactory), "CollectionContract: Collection must be created via the factory");
    //     // __ERC721_init_unchained(_name, _symbol);
    //     _transferOwnership(_creator);
    // }

    constructor(
        address _collectionFactory,
        string memory _name,
        string memory _symbol,
        string memory _contractURI,
        address _creator
    )
        ERC721Tradable(
            _name,
            _symbol,
            "https://vietrro.megacy.io/nft/metadata/"
        )
    {
        require(
            _collectionFactory.isContract(),
            "CollectionContract: collectionFactory is not a contract"
        );
        collectionFactory = ICollectionFactory(_collectionFactory);
        setBaseContractURI(_contractURI);
        factoryAddress = payable(_collectionFactory);
        _transferOwnership(_creator);
        // nextTokenId is initialized to 1, since starting at 0 leads to higher gas cost for the first minter
        _nextTokenId.increment();
        emit CollectionInitiated(owner(), _name);
    }

    /**
    @notice Function used to receive ether
    @dev  Emits "LogDepositReceived" event | Ether send to this contract for
    no reason will be credited to the contract owner, and the deposit logged,
    */
    receive() external payable {
        payable(owner()).transfer(msg.value);
        emit LogDepositReceived(msg.sender, msg.value);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId));

        string memory _tokenURI = _tokenURIs[_tokenId];
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }
        return string(abi.encodePacked(_baseURI(), Strings.toHexString(address(this)), "/", Strings.toString(_tokenId)));
    }

    function mintTo(address _to) public virtual onlyOwner returns (uint256) {
        uint256 currentTokenId = _nextTokenId.current();
        string memory _uri = string(abi.encodePacked(_baseURI(), Strings.toHexString(address(this)), "/", Strings.toString(currentTokenId)));
        return mintToWithURI(_to, _uri);
    }

    function mintToWithURI(
        address _to,
        string memory _uri
    ) public virtual onlyOwner returns (uint256) {
        uint256 currentTokenId = _nextTokenId.current();
        _safeMint(_to, currentTokenId);
        _setTokenURI(currentTokenId, _uri);
        _nextTokenId.increment();
        MegacyNFTFactory(factoryAddress).recordMint(
            address(this),
            _to,
            currentTokenId
        );
        emit CollectionMinted(_to, _uri, currentTokenId);
        return currentTokenId;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) {
        MegacyNFTFactory(factoryAddress).recordTransfer(
            address(this),
            ownerOf(tokenId),
            to,
            tokenId
        );
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721) {
        MegacyNFTFactory(factoryAddress).recordTransfer(
            address(this),
            ownerOf(tokenId),
            to,
            tokenId
        );
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
    @notice Function used to withdraw contract funds
    */
    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public view override(ERC721Tradable) returns (bool isOperator) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        // for Polygon's Mumbai testnet, use 0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }
        // if OpenSea's ERC1155 Proxy Address is detected, auto-return true
        // for Polygon's Mumbai testnet, use 0x53d791f18155C211FF8b58671d0f7E9b50E596ad 0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101
        if (_operator == address(0x207Fa8Df3a17D96Ca7EA4f2893fcdCb78a304101)) {
            return true;
        }
        // otherwise, use the default ERC721.isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator); //ERC721Tradable
    }

    /**
     * @notice Returns an array of recipient addresses to which royalties for secondary sales should be sent.
     * The expected royalty amount is communicated with `getFeeBps`.
     * param tokenId The tokenId of the NFT to get the royalty recipients for.
     * @return recipients An array of addresses to which royalties should be sent.
     */
    function getFeeRecipients(
        uint256
    ) external view returns (address payable[] memory recipients) {
        recipients = new address payable[](1);
        recipients[0] = payable(owner());
    }

    /**
     * @notice Returns an array of royalties to be sent for secondary sales in basis points.
     * The expected recipients is communicated with `getFeeRecipients`.
     * @dev The tokenId param is ignored since all NFTs return the same value.
     * @return feesInBasisPoints The array of fees to be sent to each recipient, in basis points.
     */
    function getFeeBps(
        uint256 /* tokenId */
    ) external pure returns (uint256[] memory feesInBasisPoints) {
        feesInBasisPoints = new uint256[](1);
        feesInBasisPoints[0] = ROYALTY_IN_BASIS_POINTS;
    }

    /**
        @dev Returns the total tokens minted so far.
        1 is always subtracted from the Counter since it tracks the next available tokenId.
     */
    function totalSupply() public view returns (uint256) {
        return _nextTokenId.current() - 1;
    }
}