// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";
import "./ERC4907A.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC2981.sol";

/**
 * @author Created with HeyMint Launchpad https://launchpad.heymint.xyz
 * @notice This contract handles minting GCP tokens.
 */
contract LaunchpadGCP is
    ERC721A,
    ERC721AQueryable,
    ERC4907A,
    Ownable,
    Pausable,
    ERC2981
{
    address public royaltyAddress = 0x68606fE88e8159AD8daa2DdC8043042c8ef17eCb;
    address[] public payoutAddresses = [
        0x68606fE88e8159AD8daa2DdC8043042c8ef17eCb
    ];
    bool public isPublicSaleActive = false;
    // Permanently freezes metadata so it can never be changed
    bool public metadataFrozen = false;
    string public baseTokenURI =
        "ipfs://bafybeifpjwfz3snh4c6eydflsvkb76yoyngwgy74fd3qmv3anmnmgpvojy/";
    // Maximum supply of tokens that can be minted
    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public publicMintsAllowedPerAddress = 10;
    uint256 public publicMintsAllowedPerTransaction = 10;
    uint256 public publicPrice = 0.0002 ether;
    uint256[] public payoutPercentages = [100];
    uint96 public royaltyFee = 500;

    constructor() ERC721A("GCP", "GCP") {
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    modifier originalUser() {
        require(tx.origin == msg.sender, "Cannot call from contract address");
        _;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Overrides the default ERC721A _startTokenId() so tokens begin at 1 instead of 0
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice Change the royalty fee for the collection
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Wraps and exposes publicly _numberMinted() from ERC721A
     */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @notice Update the base token URI
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_BEEN_FROZEN");
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Freeze metadata so it can never be changed again
     */
    function freezeMetadata() external onlyOwner {
        require(!metadataFrozen, "METADATA_HAS_ALREADY_BEEN_FROZEN");
        metadataFrozen = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // https://chiru-labs.github.io/ERC721A/#/migration?id=supportsinterface
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC721A, ERC2981, ERC4907A)
        returns (bool)
    {
        // Supports the following interfaceIds:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        // - IERC4907: 0xad092b5c
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC4907A.supportsInterface(interfaceId);
    }

    /**
     * @notice Allow owner to send 'mintNumber' tokens without cost to multiple addresses
     */
    function gift(address[] calldata receivers, uint256 mintNumber)
        external
        onlyOwner
    {
        require(
            (totalSupply() + (receivers.length * mintNumber)) <= MAX_SUPPLY,
            "MINT_TOO_LARGE"
        );

        for (uint256 i = 0; i < receivers.length; i++) {
            _safeMint(receivers[i], mintNumber);
        }
    }

    /**
     * @notice To be updated by contract owner to allow public sale minting
     */
    function setPublicSaleState(bool _saleActiveState) public onlyOwner {
        require(
            isPublicSaleActive != _saleActiveState,
            "NEW_STATE_IDENTICAL_TO_OLD_STATE"
        );
        isPublicSaleActive = _saleActiveState;
    }

    /**
     * @notice Update the public mint price
     */
    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    /**
     * @notice Set the maximum mints allowed per a given address in the public sale
     */
    function setPublicMintsAllowedPerAddress(uint256 _mintsAllowed)
        public
        onlyOwner
    {
        publicMintsAllowedPerAddress = _mintsAllowed;
    }

    /**
     * @notice Set the maximum public mints allowed per a given transaction
     */
    function setPublicMintsAllowedPerTransaction(uint256 _mintsAllowed)
        public
        onlyOwner
    {
        publicMintsAllowedPerTransaction = _mintsAllowed;
    }

    /**
     * @notice Allow for public minting of tokens
     */
    function mint(uint256 numTokens) external payable originalUser {
        require(isPublicSaleActive, "PUBLIC_SALE_IS_NOT_ACTIVE");

        require(
            numTokens <= publicMintsAllowedPerTransaction,
            "MAX_MINTS_PER_TX_EXCEEDED"
        );
        require(
            _numberMinted(msg.sender) + numTokens <=
                publicMintsAllowedPerAddress,
            "MAX_MINTS_EXCEEDED"
        );
        require(totalSupply() + numTokens <= MAX_SUPPLY, "MAX_SUPPLY_EXCEEDED");
        require(msg.value == publicPrice * numTokens, "PAYMENT_INCORRECT");

        _safeMint(msg.sender, numTokens);

        if (totalSupply() >= MAX_SUPPLY) {
            isPublicSaleActive = false;
        }
    }

    /**
     * @notice Withdraws all funds held within contract
     */
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "CONTRACT_HAS_NO_BALANCE");
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < 1; i++) {
            require(
                payable(payoutAddresses[i]).send(
                    (balance * payoutPercentages[i]) / 100
                )
            );
        }
    }
}
