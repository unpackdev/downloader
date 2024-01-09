// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/*

    ██████╗  █████╗ ███╗   ██╗██╗███████╗██╗
    ██╔══██╗██╔══██╗████╗  ██║██║██╔════╝██║
    ██║  ██║███████║██╔██╗ ██║██║█████╗  ██║
    ██║  ██║██╔══██║██║╚██╗██║██║██╔══╝  ██║
    ██████╔╝██║  ██║██║ ╚████║██║███████╗███████╗
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚══════╝╚══════╝

  █████╗ ██████╗ ███████╗██╗  ██╗ █████╗ ███╗   ███╗
 ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗████╗ ████║
 ███████║██████╔╝███████╗███████║███████║██╔████╔██║
 ██╔══██║██╔══██╗╚════██║██╔══██║██╔══██║██║╚██╔╝██║
 ██║  ██║██║  ██║███████║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

                       ______
                      /     /\
                     /     /##\
                    /     /####\
                   /     /######\
                  /     /########\
                 /     /##########\
                /     /#####/\#####\
               /     /#####/++\#####\
              /     /#####/++++\#####\
             /     /#####/\+++++\#####\
            /     /#####/  \+++++\#####\
           /     /#####/    \+++++\#####\
          /     /#####/      \+++++\#####\
         /     /#####/        \+++++\#####\
        /     /#####/__________\+++++\#####\
       /                        \+++++\#####\
      /__________________________\+++++\####/
      \+++++++++++++++++++++++++++++++++\##/
       \+++++++++++++++++++++++++++++++++\/
        ``````````````````````````````````

              ██████╗██╗  ██╗██╗██████╗
             ██╔════╝╚██╗██╔╝██║██╔══██╗
             ██║      ╚███╔╝ ██║██████╔╝
             ██║      ██╔██╗ ██║██╔═══╝
             ╚██████╗██╔╝ ██╗██║██║
              ╚═════╝╚═╝  ╚═╝╚═╝╚═╝

*/

import "OpenSea.sol";
import "ICxipERC721.sol";
import "ICxipIdentity.sol";
import "ICxipProvenance.sol";
import "ICxipRegistry.sol";
import "IPA1D.sol";
import "Address.sol";
import "Bytes.sol";
import "RotatingToken.sol";
import "Strings.sol";
import "CollectionData.sol";
import "TokenData.sol";
import "Verification.sol";

/**
 * @title CXIP ERC721
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing ERC721 NFTs.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract DanielArshamErosions {
    /**
     * @dev Stores default collection data: name, symbol, and royalties.
     */
    CollectionData private _collectionData;

    /**
     * @dev Internal last minted token id, to allow for auto-increment.
     */
    uint256 private _currentTokenId;

    /**
     * @dev Array of all token ids in collection.
     */
    uint256[] private _allTokens;

    /**
     * @dev Map of token id to array index of _ownedTokens.
     */
    mapping(uint256 => uint256) private _ownedTokensIndex;

    /**
     * @dev Token id to wallet (owner) address map.
     */
    mapping(uint256 => address) private _tokenOwner;

    /**
     * @dev 1-to-1 map of token id that was assigned an approved operator address.
     */
    mapping(uint256 => address) private _tokenApprovals;

    /**
     * @dev Map of total tokens owner by a specific address.
     */
    mapping(address => uint256) private _ownedTokensCount;

    /**
     * @dev Map of array of token ids owned by a specific address.
     */
    mapping(address => uint256[]) private _ownedTokens;

    /**
     * @notice Map of full operator approval for a particular address.
     * @dev Usually utilised for supporting marketplace proxy wallets.
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Token data mapped by token id.
     */
    mapping(uint256 => TokenData) private _tokenData;

    /**
     * @dev Address of admin user. Primarily used as an additional recover address.
     */
    address private _admin;

    /**
     * @dev Address of contract owner. This address can run all onlyOwner functions.
     */
    address private _owner;

    /**
     * @dev Simple tracker of all minted (not-burned) tokens.
     */
    uint256 private _totalTokens;

    /**
     * @dev Mapping from token id to position in the allTokens array.
     */
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @notice Event emitted when an token is minted, transfered, or burned.
     * @dev If from is empty, it's a mint. If to is empty, it's a burn. Otherwise, it's a transfer.
     * @param from Address from where token is being transfered.
     * @param to Address to where token is being transfered.
     * @param tokenId Token id that is being minted, Transfered, or burned.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @notice Event emitted when an address delegates power, for a token, to another address.
     * @dev Emits event that informs of address approving a third-party operator for a particular token.
     * @param wallet Address of the wallet configuring a token operator.
     * @param operator Address of the third-party operator approved for interaction.
     * @param tokenId A specific token id that is being authorised to operator.
     */
    event Approval(address indexed wallet, address indexed operator, uint256 indexed tokenId);

    /**
     * @notice Event emitted when an address authorises an operator (third-party).
     * @dev Emits event that informs of address approving/denying a third-party operator.
     * @param wallet Address of the wallet configuring it's operator.
     * @param operator Address of the third-party operator that interacts on behalf of the wallet.
     * @param approved A boolean indicating whether approval was granted or revoked.
     */
    event ApprovalForAll(address indexed wallet, address indexed operator, bool approved);

    /**
     * @notice Event emitted to signal to OpenSea that a permanent URI was created.
     * @dev Even though OpenSea advertises support for this, they do not listen to this event, and do not respond to it.
     * @param uri The permanent/static URL of the NFT. Cannot ever be changed again.
     * @param id Token id of the NFT.
     */
    event PermanentURI(string uri, uint256 indexed id);

    /**
     * @notice Constructor is empty and not utilised.
     * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
     */
    constructor() {}

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "CXIP: caller not an owner");
        _;
    }

    /**
     * @notice Enables royaltiy functionality at the ERC721 level when ether is sent with no calldata.
     * @dev See implementation of _royaltiesFallback.
     */
    receive() external payable {
        _royaltiesFallback();
    }

    /**
     * @notice Enables royaltiy functionality at the ERC721 level no other function matches the call.
     * @dev See implementation of _royaltiesFallback.
     */
    fallback() external {
        _royaltiesFallback();
    }

    /**
     * @notice Gets the URI of the NFT on Arweave.
     * @dev Concatenates 2 sections of the arweave URI.
     * @return string The URI.
     */
    function arweaveURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "CXIP: token does not exist");
        uint256 index = RotatingToken.calculateRotation(tokenId, getTokenSeparator());
        return string(abi.encodePacked("https://arweave.net/", _tokenData[index].arweave, _tokenData[index].arweave2));
    }

    /**
     * @notice Gets the URI of the NFT backup from CXIP.
     * @dev Concatenates to https://nft.cxip.io/.
     * @return string The URI.
     */
    function contractURI() external view returns (string memory) {
        return string(abi.encodePacked("https://nft.cxip.io/", Strings.toHexString(address(this)), "/"));
    }

    /**
     * @notice Gets the creator's address.
     * @dev If the token Id doesn't exist it will return zero address.
     * @return address Creator's address.
     */
    function creator(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "CXIP: token does not exist");
        uint256 index = RotatingToken.calculateRotation(tokenId, getTokenSeparator());
        return _tokenData[index].creator;
    }

    /**
     * @notice Gets the HTTP URI of the token.
     * @dev Concatenates to the baseURI.
     * @return string The URI.
     */
    function httpURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "CXIP: token does not exist");
        return string(abi.encodePacked(baseURI(), "/", Strings.toHexString(tokenId)));
    }

    /**
     * @notice Gets the IPFS URI
     * @dev Concatenates to the IPFS domain.
     * @return string The URI.
     */
    function ipfsURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "CXIP: token does not exist");
        uint256 index = RotatingToken.calculateRotation(tokenId, getTokenSeparator());
        return string(abi.encodePacked("https://ipfs.io/ipfs/", _tokenData[index].ipfs, _tokenData[index].ipfs2));
    }

    /**
     * @notice Gets the name of the collection.
     * @dev Uses two names to extend the max length of the collection name in bytes
     * @return string The collection name.
     */
    function name() external view returns (string memory) {
        return string(abi.encodePacked(Bytes.trim(_collectionData.name), Bytes.trim(_collectionData.name2)));
    }

    /**
     * @notice Gets the hash of the NFT data used to create it.
     * @dev Payload is used for verification.
     * @param tokenId The Id of the token.
     * @return bytes32 The hash.
     */
    function payloadHash(uint256 tokenId) external view returns (bytes32) {
        require(_exists(tokenId), "CXIP: token does not exist");
        uint256 index = RotatingToken.calculateRotation(tokenId, getTokenSeparator());
        return _tokenData[index].payloadHash;
    }

    /**
     * @notice Gets the signature of the signed NFT data used to create it.
     * @dev Used for signature verification.
     * @param tokenId The Id of the token.
     * @return Verification a struct containing v, r, s values of the signature.
     */
    function payloadSignature(uint256 tokenId) external view returns (Verification memory) {
        require(_exists(tokenId), "CXIP: token does not exist");
        uint256 index = RotatingToken.calculateRotation(tokenId, getTokenSeparator());
        return _tokenData[index].payloadSignature;
    }

    /**
     * @notice Gets the address of the creator.
     * @dev The creator signs a payload while creating the NFT.
     * @param tokenId The Id of the token.
     * @return address The creator.
     */
    function payloadSigner(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "CXIP: token does not exist");
        uint256 index = RotatingToken.calculateRotation(tokenId, getTokenSeparator());
        return _tokenData[index].creator;
    }

    /**
     * @notice Shows the interfaces the contracts support
     * @dev Must add new 4 byte interface Ids here to acknowledge support
     * @param interfaceId ERC165 style 4 byte interfaceId.
     * @return bool True if supported.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        if (
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x780e9d63 || // ERC721Enumerable
            interfaceId == 0x5b5e139f || // ERC721Metadata
            interfaceId == 0x150b7a02 || // ERC721TokenReceiver
            interfaceId == 0xe8a3d485 || // contractURI()
            IPA1D(getRegistry().getPA1D()).supportsInterface(interfaceId)
        ) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Gets the collection's symbol.
     * @dev Trims the symbol.
     * @return string The symbol.
     */
    function symbol() external view returns (string memory) {
        return string(Bytes.trim(_collectionData.symbol));
    }

    /**
     * @notice Get's the URI of the token.
     * @dev Defaults the the Arweave URI
     * @return string The URI.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "CXIP: token does not exist");
        uint256 index = RotatingToken.calculateRotation(tokenId, getTokenSeparator());
        return string(abi.encodePacked("https://arweave.net/", _tokenData[index].arweave, _tokenData[index].arweave2));
    }

    /**
     * @notice Get list of tokens owned by wallet.
     * @param wallet The wallet address to get tokens for.
     * @return uint256[] Returns an array of token ids owned by wallet.
     */
    function tokensOfOwner(address wallet) external view returns (uint256[] memory) {
        return _ownedTokens[wallet];
    }

    /**
     * @notice Checks if a given hash matches a payload hash.
     * @dev Uses sha256 instead of keccak.
     * @param hash The hash to check.
     * @param payload The payload prehashed.
     * @return bool True if the hashes match.
     */
    function verifySHA256(bytes32 hash, bytes calldata payload) external pure returns (bool) {
        bytes32 thePayloadHash = sha256(payload);
        return hash == thePayloadHash;
    }

    /**
     * @notice Adds a new address to the token's approval list.
     * @dev Requires the sender to be in the approved addresses.
     * @param to The address to approve.
     * @param tokenId The affected token.
     */
    function approve(address to, uint256 tokenId) public {
        address tokenOwner = _tokenOwner[tokenId];
        require(to != tokenOwner, "CXIP: can't approve self");
        require(_isApproved(msg.sender, tokenId), "CXIP: not approved sender");
        _tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }

    /**
     * @notice Burns the token.
     * @dev The sender must be the owner or approved.
     * @param tokenId The token to burn.
     */
    function burn(uint256 tokenId) public {
        require(_isApproved(msg.sender, tokenId), "CXIP: not approved sender");
        address wallet = _tokenOwner[tokenId];
        _clearApproval(tokenId);
        _tokenOwner[tokenId] = address(0);
        emit Transfer(wallet, address(0), tokenId);
        _removeTokenFromOwnerEnumeration(wallet, tokenId);
    }

    /**
     * @notice Initializes the collection.
     * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
     * @param newOwner The owner of the collection.
     * @param collectionData The collection data.
     */
    function init(address newOwner, CollectionData calldata collectionData) public {
        require(Address.isZero(_admin), "CXIP: already initialized");
        _admin = msg.sender;
        // temporary set to self, to pass rarible royalties logic trap
        _owner = address(this);
        _collectionData = collectionData;
        IPA1D(address(this)).init (0, payable(collectionData.royalties), collectionData.bps);
        // set to actual owner
        _owner = newOwner;
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     * @param from cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must exist and be owned by `from`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     * @param from cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must exist and be owned by `from`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable {
        require(_isApproved(msg.sender, tokenId), "CXIP: not approved sender");
        _transferFrom(from, to, tokenId);
        if (Address.isContract(to)) {
            require(
                ICxipERC721(to).onERC721Received(address(this), from, tokenId, data) == 0x150b7a02,
                "CXIP: onERC721Received fail"
            );
        }
    }

    /**
     * @notice Adds a new approved operator.
     * @dev Allows platforms to sell/transfer all your NFTs. Used with proxy contracts like OpenSea/Rarible.
     * @param to The address to approve.
     * @param approved Turn on or off approval status.
     */
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "CXIP: can't approve self");
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     * @dev WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * @param from  cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must be owned by `from`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable {
        transferFrom(from, to, tokenId, "");
    }

    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     * @dev WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
     * @param from  cannot be the zero address.
     * @param to cannot be the zero address.
     * @param tokenId token must be owned by `from`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory /*_data*/
    ) public payable {
        require(_isApproved(msg.sender, tokenId), "CXIP: not approved sender");
        _transferFrom(from, to, tokenId);
    }

    /**
     * @notice Mints batches of NFTs.
     * @dev Limited to maximum number of NFTs that can be minted for this drop. Needs to be called in tokenId sequence.
     * @param creatorWallet The wallet address of the NFT creator.
     * @param startId The tokenId from which to start batch mint.
     * @param length The total number of NFTs to mint starting from the startId.
     * @param recipient Optional parameter, to send the token to a recipient right after minting.
     */
    function batchMint(address creatorWallet, uint256 startId, uint256 length, address recipient) public onlyOwner {
        require(!getMintingClosed(), "CXIP: minting is now closed");
        require(_allTokens.length + length <= getTokenLimit(), "CXIP: over token limit");
        require(isIdentityWallet(creatorWallet), "CXIP: creator not in identity");
        bool hasRecipient = !Address.isZero(recipient);
        uint256 tokenId;
        for (uint256 i = 0; i < length; i++) {
            tokenId = (startId + i);
            if (hasRecipient) {
                require(!_exists(tokenId), "CXIP: token already exists");
                emit Transfer(address(0), creatorWallet, tokenId);
                emit Transfer(creatorWallet, recipient, tokenId);
                _tokenOwner[tokenId] = recipient;
                _addTokenToOwnerEnumeration(recipient, tokenId);
            } else {
                _mint(creatorWallet, tokenId);
            }
        }
        if (_allTokens.length == getTokenLimit()) {
            setMintingClosed();
        }
    }

    function getStartTimestamp() public view returns (uint256) {
        return RotatingToken.getStartTimestamp();
    }

    /**
     * @dev Gets the minting status from storage slot.
     * @return mintingClosed Whether minting is open or closed permanently.
     */
    function getMintingClosed() public view returns (bool mintingClosed) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.DanielArshamErosions.mintingClosed')) - 1);
        uint256 data;
        assembly {
            data := sload(
                /* slot */
                0xab90edbe8f424080ec4ee1e9062e8b7540cbbfd5f4287285e52611030e58b8d4
            )
        }
        mintingClosed = (data == 1);
    }

    /**
     * @dev Sets the minting status to closed in storage slot.
     */
    function setMintingClosed() public onlyOwner {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.DanielArshamErosions.mintingClosed')) - 1);
        uint256 data = 1;
        assembly {
            sstore(
                /* slot */
                0xab90edbe8f424080ec4ee1e9062e8b7540cbbfd5f4287285e52611030e58b8d4,
                data
            )
        }
    }

    /**
     * @dev Gets the token limit from storage slot.
     * @return tokenLimit Maximum number of tokens that can be minted.
     */
    function getTokenLimit() public view returns (uint256 tokenLimit) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.DanielArshamErosions.tokenLimit')) - 1);
        assembly {
            tokenLimit := sload(
                /* slot */
                0xb63653e470fa8e7fcc528e0068173a1969fdee5ae0ee29dd58e7b6111b829c56
            )
        }
    }

    /**
     * @dev Sets the token limit to storage slot.
     * @param tokenLimit Maximum number of tokens that can be minted.
     */
    function setTokenLimit(uint256 tokenLimit) public onlyOwner {
        require(getTokenLimit() == 0, "CXIP: token limit already set");
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.DanielArshamErosions.tokenLimit')) - 1);
        assembly {
            sstore(
                /* slot */
                0xb63653e470fa8e7fcc528e0068173a1969fdee5ae0ee29dd58e7b6111b829c56,
                tokenLimit
            )
        }
    }

    /**
     * @dev Gets the token separator from storage slot.
     * @return tokenSeparator The number of tokens before separation.
     */
    function getTokenSeparator() public view returns (uint256 tokenSeparator) {
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.DanielArshamErosions.tokenSeparator')) - 1);
        assembly {
            tokenSeparator := sload(
                /* slot */
                0x988145eec05de02f4c5d4ecd419a9617237db574d35b27207657cbd8c5b1f045
            )
        }
    }

    /**
     * @dev Sets the token separator to storage slot.
     * @param tokenSeparator The number of tokens before separation.
     */
    function setTokenSeparator(uint256 tokenSeparator) public onlyOwner {
        require(getTokenSeparator() == 0, "CXIP: separator already set");
        // The slot hash has been precomputed for gas optimizaion
        // bytes32 slot = bytes32(uint256(keccak256('eip1967.CXIP.DanielArshamErosions.tokenSeparator')) - 1);
        assembly {
            sstore(
                /* slot */
                0x988145eec05de02f4c5d4ecd419a9617237db574d35b27207657cbd8c5b1f045,
                tokenSeparator
            )
        }
    }

    /**
     * @notice Set an NFT state.
     * @dev Time-based states will be retrieved by index.
     * @param id The index of time slot to set for.
     * @param tokenData The token data for the particular time slot.
     */
    function prepareMintData(uint256 id, TokenData calldata tokenData) public onlyOwner {
        require(Address.isZero(_tokenData[id].creator), "CXIP: token data already set");
        _tokenData[id] = tokenData;
    }

    function prepareMintDataBatch(uint256[] calldata ids, TokenData[] calldata tokenData) public onlyOwner {
        require(ids.length == tokenData.length, "CXIP: array lengths missmatch");
        for (uint256 i = 0; i < ids.length; i++) {
            require(Address.isZero(_tokenData[ids[i]].creator), "CXIP: token data already set");
            _tokenData[ids[i]] = tokenData[i];
        }
    }

    /**
     * @dev Sets the configuration for rotation calculations.
     * @param interval The number of seconds each rotation is shown for.
     * @param steps Total number of steps for complete rotation. Reverse rotation including.
     * @param halfwayPoint Step at which to reverse the rotation backwards. Must be exactly in the middle.
     */
    function setRotationConfig(uint256 index, uint256 interval, uint256 steps, uint256 halfwayPoint) public onlyOwner {
        RotatingToken.setRotationConfig(index, interval, steps, halfwayPoint);
    }

    function getRotationConfig(uint256 index) public view returns (uint256, uint256, uint256) {
        return RotatingToken.getRotationConfig(index);
    }

    /**
     * @notice Sets a name for the collection.
     * @dev The name is split in two for gas optimization.
     * @param newName First part of name.
     * @param newName2 Second part of name.
     */
    function setName(bytes32 newName, bytes32 newName2) public onlyOwner {
        _collectionData.name = newName;
        _collectionData.name2 = newName2;
    }

    /**
     * @notice Sets the start timestamp for token rotations.
     * @dev All rotation calculations will use this timestamp as the origin point from which to calculate.
     * @param _timestamp UNIX timestamp in seconds.
     */
    function setStartTimestamp(uint256 _timestamp) public onlyOwner {
        RotatingToken.setStartTimestamp(_timestamp);
    }

    /**
     * @notice Set a symbol for the collection.
     * @dev This is the ticker symbol for smart contract that shows up on EtherScan.
     * @param newSymbol The ticker symbol to set for smart contract.
     */
    function setSymbol(bytes32 newSymbol) public onlyOwner {
        _collectionData.symbol = newSymbol;
    }

    /**
     * @notice Transfers ownership of the collection.
     * @dev Can't be the zero address.
     * @param newOwner Address of new owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(!Address.isZero(newOwner), "CXIP: zero address");
        _owner = newOwner;
    }

    /**
     * @notice Get total number of tokens owned by wallet.
     * @dev Used to see total amount of tokens owned by a specific wallet.
     * @param wallet Address for which to get token balance.
     * @return uint256 Returns an integer, representing total amount of tokens held by address.
     */
    function balanceOf(address wallet) public view returns (uint256) {
        require(!Address.isZero(wallet), "CXIP: zero address");
        return _ownedTokensCount[wallet];
    }

    /**
     * @notice Get a base URI for the token.
     * @dev Concatenates with the CXIP domain name.
     * @return string the token URI.
     */
    function baseURI() public view returns (string memory) {
        return string(abi.encodePacked("https://nft.cxip.io/", Strings.toHexString(address(this))));
    }

    /**
     * @notice Gets the approved address for the token.
     * @dev Single operator set for a specific token. Usually used for one-time very specific authorisations.
     * @param tokenId Token id to get approved operator for.
     * @return address Approved address for token.
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @notice Get the associated identity for the collection.
     * @dev Goes up the chain to read from the registry.
     * @return address Identity contract address.
     */
    function getIdentity() public view returns (address) {
        return ICxipProvenance(getRegistry().getProvenance()).getWalletIdentity(_owner);
    }

    /**
     * @notice Checks if the address is approved.
     * @dev Includes references to OpenSea and Rarible marketplace proxies.
     * @param wallet Address of the wallet.
     * @param operator Address of the marketplace operator.
     * @return bool True if approved.
     */
    function isApprovedForAll(address wallet, address operator) public view returns (bool) {
        // pre-approved OpenSea and Rarible proxies removed, per Nifty Gateway's request
        return (_operatorApprovals[wallet][operator]/* ||
            // Rarible Transfer Proxy
            0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be == operator ||
            // OpenSea Transfer Proxy
            address(OpenSeaProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(wallet)) == operator*/);
    }

    /**
     * @notice Check if the sender is the owner.
     * @dev The owner could also be the admin or identity contract of the owner.
     * @return bool True if owner.
     */
    function isOwner() public view returns (bool) {
        return (msg.sender == _owner || msg.sender == _admin || isIdentityWallet(msg.sender));
    }

    /**
     * @notice Gets the owner's address.
     * @dev _owner is first set in init.
     * @return address Of ower.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Checks who the owner of a token is.
     * @dev The token must exist.
     * @param tokenId The token to look up.
     * @return address Owner of the token.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = _tokenOwner[tokenId];
        require(!Address.isZero(tokenOwner), "ERC721: token does not exist");
        return tokenOwner;
    }

    /**
     * @notice Get token by index.
     * @dev Used in conjunction with totalSupply function to iterate over all tokens in collection.
     * @param index Index of token in array.
     * @return uint256 Returns the token id of token located at that index.
     */
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "CXIP: index out of bounds");
        return _allTokens[index];
    }

    /**
     * @notice Get token from wallet by index instead of token id.
     * @dev Helpful for wallet token enumeration where token id info is not yet available. Use in conjunction with balanceOf function.
     * @param wallet Specific address for which to get token for.
     * @param index Index of token in array.
     * @return uint256 Returns the token id of token located at that index in specified wallet.
     */
    function tokenOfOwnerByIndex(
        address wallet,
        uint256 index
    ) public view returns (uint256) {
        require(index < balanceOf(wallet));
        return _ownedTokens[wallet][index];
    }

    /**
     * @notice Total amount of tokens in the collection.
     * @dev Ignores burned tokens.
     * @return uint256 Returns the total number of active (not burned) tokens.
     */
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @notice Empty function that is triggered by external contract on NFT transfer.
     * @dev We have this blank function in place to make sure that external contract sending in NFTs don't error out.
     * @dev Since it's not being used, the _operator variable is commented out to avoid compiler warnings.
     * @dev Since it's not being used, the _from variable is commented out to avoid compiler warnings.
     * @dev Since it's not being used, the _tokenId variable is commented out to avoid compiler warnings.
     * @dev Since it's not being used, the _data variable is commented out to avoid compiler warnings.
     * @return bytes4 Returns the interfaceId of onERC721Received.
     */
    function onERC721Received(
        address, /*_operator*/
        address, /*_from*/
        uint256, /*_tokenId*/
        bytes calldata /*_data*/
    ) public pure returns (bytes4) {
        return 0x150b7a02;
    }

    /**
     * @notice Allows retrieval of royalties from the contract.
     * @dev This is a default fallback to ensure the royalties are available.
     */
    function _royaltiesFallback() internal {
        address _target = getRegistry().getPA1D();
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice Checks if an address is an identity contract.
     * @dev It must also be registred.
     * @param sender Address to check if registered to identity.
     * @return bool True if registred identity.
     */
    function isIdentityWallet(address sender) internal view returns (bool) {
        address identity = getIdentity();
        if (Address.isZero(identity)) {
            return false;
        }
        return ICxipIdentity(identity).isWalletRegistered(sender);
    }

    /**
     * @dev Get the top-level CXIP Registry smart contract. Function must always be internal to prevent miss-use/abuse through bad programming practices.
     * @return ICxipRegistry The address of the top-level CXIP Registry smart contract.
     */
    function getRegistry() internal pure returns (ICxipRegistry) {
        return ICxipRegistry(0xC267d41f81308D7773ecB3BDd863a902ACC01Ade);
    }

    /**
     * @dev Add a newly minted token into managed list of tokens.
     * @param to Address of token owner for which to add the token.
     * @param tokenId Id of token to add.
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokensCount[to];
        _ownedTokensCount[to]++;
        _ownedTokens[to].push(tokenId);
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @notice Deletes a token from the approval list.
     * @dev Removes from count.
     * @param tokenId T.
     */
    function _clearApproval(uint256 tokenId) private {
        delete _tokenApprovals[tokenId];
    }

    /**
     * @notice Mints an NFT.
     * @dev Can to mint the token to the zero address and the token cannot already exist.
     * @param to Address to mint to.
     * @param tokenId The new token.
     */
    function _mint(address to, uint256 tokenId) private {
        require(!Address.isZero(to), "CXIP: can't mint a burn");
        require(!_exists(tokenId), "CXIP: token already exists");
        _tokenOwner[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId;
        _allTokensIndex[lastTokenId] = tokenIndex;
        delete _allTokensIndex[tokenId];
        delete _allTokens[lastTokenIndex];
        _allTokens.pop();
    }

    /**
     * @dev Remove a token from managed list of tokens.
     * @param from Address of token owner for which to remove the token.
     * @param tokenId Id of token to remove.
     */
    function _removeTokenFromOwnerEnumeration(
        address from,
        uint256 tokenId
    ) private {
        _removeTokenFromAllTokensEnumeration(tokenId);
        _ownedTokensCount[from]--;
        uint256 lastTokenIndex = _ownedTokensCount[from];
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if(tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }
        if(lastTokenIndex == 0) {
            delete _ownedTokens[from];
        } else {
            delete _ownedTokens[from][lastTokenIndex];
            _ownedTokens[from].pop();
        }
    }

    /**
     * @dev Primary internal function that handles the transfer/mint/burn functionality.
     * @param from Address from where token is being transferred. Zero address means it is being minted.
     * @param to Address to whom the token is being transferred. Zero address means it is being burned.
     * @param tokenId Id of token that is being transferred/minted/burned.
     */
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) private {
        require(_tokenOwner[tokenId] == from, "CXIP: not from's token");
        require(!Address.isZero(to), "CXIP: use burn instead");
        _clearApproval(tokenId);
        _tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @notice Checks if the token owner exists.
     * @dev If the address is the zero address no owner exists.
     * @param tokenId The affected token.
     * @return bool True if it exists.
     */
    function _exists(uint256 tokenId) private view returns (bool) {
        address tokenOwner = _tokenOwner[tokenId];
        return !Address.isZero(tokenOwner);
    }

    /**
     * @notice Checks if the address is an approved one.
     * @dev Uses inlined checks for different usecases of approval.
     * @param spender Address of the spender.
     * @param tokenId The affected token.
     * @return bool True if approved.
     */
    function _isApproved(address spender, uint256 tokenId) private view returns (bool) {
        require(_exists(tokenId));
        address tokenOwner = _tokenOwner[tokenId];
        return (
            spender == tokenOwner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(tokenOwner, spender)
        );
    }
}
