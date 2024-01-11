// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";

interface MigrateTokenContract {
    function mintTransfer(address to, uint256 oldTokenId)
        external
        returns (uint256);

    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

error InvalidPrice(address emitter);
error SoldOut(address emitter);
error SaleNotStarted(address emitter);
error PresaleFinished(address emitter);
error MigrationNotActive(address emitter);
error NoFunds(address emitter);
error InvalidMigrationContract(address emitter);
/**
 * @dev Error that occurs when transferring ether has failed.
 * @param emitter The contract that emits the error.
 */
error EtherTransferFail(address emitter);

/**
 * @title 432 VIRUS 
 * Inspired by the "flickering screen"; a crucial element depicted in the Snow Crash fiction novel by Neal Stephenson, it functions as a hallucinatory drug in the metaverses.
 *
 * @author SNOWCASH, www.snowcash.io
 */
contract Virus is ERC721A, Ownable {
    /**
     * @dev Max supply of nfts including the premint amount
     */
    uint256 public constant MAX_SUPPLY = 128;

    /**
     * @dev amount of NFTs which can and must be minted before the public sale starts
     */
    uint256 public constant PREMINT_AMOUNT = 28;

    /**
     * @dev amount of ETH which must be sent in the mint method to mint a nft
     */
    uint256 public immutable price;

    /**
     * @dev address which would perform a migration
     */
    address public migrationAddress;

    /**
     * @dev if the migration is active (true) or not (false)
     */
    bool public migrationActive;

    /**
     * @dev metadata token uri for all minted nfts unless overridden with {Virus.setTokenURI)
     */
    string public globalTokenUri;

    /**
     * @dev allows to set metadata for specific tokenIds to different uris
     */
    mapping(uint256 => string) public tokenUriMap;

    /**
     * @dev Event that is emitted when a nft is minted
     */
    event Sold(address indexed to, uint256 tokenId);

    /**
     * @dev Event that is emitted when a nft is migrated
     */
    event Migrated(address indexed to, uint256 oldTokenId, uint256 newTokenId);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _price,
        string memory _tokenUri
    ) payable ERC721A(_name, _symbol) {
        price = _price;
        globalTokenUri = _tokenUri;
    }

    /**
     * @dev Allows to mint a new nft if the correct price is transferred
     * Checks that all nfts from the presale are minted and that the max supply hasn't been reached
     */
    function mint() public payable {
        if (msg.value != price) revert InvalidPrice(address(this));
        if (_totalMinted() >= MAX_SUPPLY) revert SoldOut(address(this));
        if (_totalMinted() < PREMINT_AMOUNT)
            revert SaleNotStarted(address(this));

        emit Sold(msg.sender, _currentIndex);
        _safeMint(msg.sender, 1);
    }

    /**
     * @dev Allows to premint nfts directly to addresses.
     * Only the contract owner can call this method.
     * Check if premint is still allowed happens in {Virus-_premint}
     * Overflow of it can't happen, as the loop will terminate at 28 (PREMINT_AMOUNT)
     */
    function premint(address[] calldata addresses) public onlyOwner {
        uint256 length = addresses.length;
        for (uint256 i; i < length; i = _uncheckedInc(i)) {
            _premint(addresses[i]);
        }
    }

    /**
     * @dev Returns the metadata uri for a given tokenId.
     * If the tokenId hasn't a specific token uri, the global token uri is returned
     * Reverts for not existing tokenIds
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (bytes(tokenUriMap[tokenId]).length != 0) {
            return tokenUriMap[tokenId];
        }
        return globalTokenUri;
    }

    /**
     * @dev Allows the contract owner to transfer all ETH from the contract
     */
    function drain() public payable onlyOwner {
        uint256 balance = address(this).balance;
        if (balance != 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool drained, ) = payable(msg.sender).call{value: balance}("");
            if (!drained) revert EtherTransferFail(address(this));
        }
    }

    /**
     * @dev Allows nft holders to migrate their own or approved nft to a new one.
     * migrationActive must be set to true and the migrationAddress must be set to an address different than the zero address.
     * First the token is burned and afterwards the {MigrateTokenContract.mintTransfer} is called.
     * If the migration fails for any reason this method reverts as well
     */
    function migrateToken(uint256 tokenId) public {
        if (!migrationActive || migrationAddress == address(0))
            revert MigrationNotActive(address(this));

        //burn with approval check
        _burn(tokenId, true);
        MigrateTokenContract migrationContract = MigrateTokenContract(
            migrationAddress
        );
        uint256 newTokenId = migrationContract.mintTransfer(
            msg.sender,
            tokenId
        );
        emit Migrated(msg.sender, tokenId, newTokenId);
    }

    /**
     * @dev Returns the starting token id
     */
    function startTokenId() public pure returns (uint256) {
        return _startTokenId();
    }

    /**
     * @dev Sets the global token uri.
     */
    function setGlobalTokenURI(string calldata tokenUri) public onlyOwner {
        globalTokenUri = tokenUri;
    }

    /**
     * @dev Sets the token uri for a specific token id.
     * To fallback to the global uri again pass "" as tokenUri
     */
    function setTokenURI(uint256 tokenId, string calldata tokenUri)
        public
        onlyOwner
    {
        tokenUriMap[tokenId] = tokenUri;
    }

    /**
     * @dev Sets the migration state. Can only be changed by the contract owner
     */
    function setMigrationState(bool state) public onlyOwner {
        migrationActive = state;
    }

    /**
     * @dev Sets the migration address. Can only be changed by the contract owner
     */
    function setMigrateAddress(address newAddress) public onlyOwner {
        migrationAddress = newAddress;
        // allow to set zero address
        if (newAddress != address(0)) {
            MigrateTokenContract migrationContract = MigrateTokenContract(
                newAddress
            );
            if (!migrationContract.supportsInterface(type(IERC721).interfaceId))
                revert InvalidMigrationContract(address(this));
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /**
     * @dev Returns the total amount of tokens burned in the contract.
     */
    function totalBurned() public view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev Returns the number of tokens minted by `owner`.
     */
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * @dev Returns the number of tokens burned by or on behalf of `owner`.
     */
    function numberBurned(address owner) public view returns (uint256) {
        return _numberBurned(owner);
    }

    /**
     * @dev Check whether a given interface is supported by this contract.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Start token ids with 1
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev Mints a single nft to an address.
     * Checks if the premint amount hasn't been reached
     */
    function _premint(address recipient) internal {
        if (_totalMinted() >= PREMINT_AMOUNT)
            revert PresaleFinished(address(this));
        _safeMint(recipient, 1);
    }

    /**
     * @dev Save gas fees during loops using this method.
     * Overflow won't happen as this can maximal be called 28 times before the premint method reverts
     */
    function _uncheckedInc(uint256 i) private pure returns (uint256) {
        unchecked {
            return i + 1;
        }
    }
}
