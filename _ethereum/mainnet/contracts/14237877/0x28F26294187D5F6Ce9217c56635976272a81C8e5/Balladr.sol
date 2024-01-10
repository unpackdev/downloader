// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

/**
 * @title Ballad(r)'s NFT Contract
 * @notice All Collections and NFTs from this contract are minted by artists.
 */

contract Balladr is ERC1155, Ownable {

    // List of authorized contracts allowed to interact with protected functions
    mapping(address => bool) public authorizedContracts;

    // Base Royalties in Basis Points
    uint256 public baseRoyaltiesInBasisPoints;

    // Store the Uri of the Token
    mapping(uint256 => string) private _tokenUris;

    //Store whether the Uri has been set as Frozen (not modifiable)
    mapping(uint256 => bool) private isTokenUriFrozen;

    // Store the maximum supply for a given token
    mapping(uint256 => uint256) private tokenMaxSupply;

    // Store the current minted supply for a given token
    mapping(uint256 => uint256) private tokenMinteds;

    // Store the address owning a given collection
    mapping(uint256 => address) private collectionOwner;

    // Store the collectionId that a given tokenId belongs to
    mapping(uint256 => uint256) private tokenIdToCollectionId;

    // Store whether a given collection is closed
    mapping(uint256 => bool) private isCollectionClosed;

    // Store an alternative payment address for a collection
    // The alternative payment address could be a contract
    mapping(uint256 => address) private collectionPaymentAddress;

    // Store a custom royalty percentage for a given collection
    // The percentage is store in Basis Points
    mapping(uint256 => uint256) private collectionRoyaltyPercentage;

    // Store the metadata of the contract
    string public contractUri;

    // Event fired when a token URI is frozen
    event PermanentURI(string uri, uint256 indexed tokenId);

    // Event fired when a collection is closed
    event CollectionClosed(uint256 indexed collectionId);

    // Event fired when a new token is minted
    event Minted(address indexed creator, uint256 indexed tokenId, uint256 amount);

    // Event fired when a payment address has been set for a specific CollectionId
    event CollectionPaymentAddressUpdated(uint256 indexed collectionId, address paymentAddress);

    // Event fired when royalties are updated for a collection
    event CollectionRoyaltiesUpdated(uint256 indexed collectionId, uint256 _royalties);

    // Event fired when collection owner is updated
    event CollectionOwnerUpdated(uint256 indexed collectionId, address newOwner);

    /**
    * @notice Only an Authorized Minter or Manager contract can use modified function
    */
    modifier onlyAuthorized() {
        require(authorizedContracts[msg.sender] == true, "Not authorized");
        _;
    }

    /**
    * @notice Overide default ERC-1155 URI
    */
    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return _tokenUris[tokenId];
    }

    /**
    * @notice Set base royalties for Artists.
    * Maximum that could ever be set by Balladr is 10% (in Basis Points)
    */
    function setbaseRoyaltiesInBasisPoints(uint256 _baseRoyaltiesInBasisPoints) public onlyOwner {
        require(_baseRoyaltiesInBasisPoints <= 1000, "Royalties are too high");
        baseRoyaltiesInBasisPoints = _baseRoyaltiesInBasisPoints;
    }

    /**
    * @notice Add an Authorized Contract
    */
    function addAuthorizedContrat(address target) public onlyOwner {
        authorizedContracts[target] = true;
    }

    /**
    * @notice Revoke an Authorized contract
    */
    function removeAuthorizedContrat(address target) public onlyOwner {
        authorizedContracts[target] = false;
    }

    /**
    * @notice Change contract Uri
    */
    function setContractUri(string memory _contractUri) public onlyOwner {
        contractUri = _contractUri;
    }

    /**
    * @notice Retrieve contract Uri
    */
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /**
    * @notice Retrieve Frozen status for a given tokenId
    */
    function getIsTokenUriFrozen(uint256 tokenId) public view returns (bool _isFrozen) {
        return isTokenUriFrozen[tokenId];
    }

    /**
    * @notice Retrieve owner's address for a given collectionId
    */
    function getCollectionOwner(uint256 collectionId) public view returns (address _owner) {
        return collectionOwner[collectionId];
    }

    /**
    * @notice Set a new collection Owner
    */
    function setCollectionOwner(uint256 collectionId, address newOwner) public onlyAuthorized {
        collectionOwner[collectionId] = newOwner;
        emit CollectionOwnerUpdated(collectionId, newOwner);
    }

    /**
    * @notice Retrieve collectionId for a given tokenId
    */
    function getTokenIdToCollectionId(uint256 tokenId) public view returns (uint256 _collectionId) {
        return tokenIdToCollectionId[tokenId];
    }

    /**
    * @notice Retrieve Collection status for a given collectionId
    */
    function getIsCollectionClosed(uint256 collectionId) public view returns (bool _isCollectionClosed) {
        return isCollectionClosed[collectionId];
    }

    /**
    * @notice Set the Uri for a given token
    * Only if token is not Frozen
    */
    function setTokenUri(uint256 tokenId, string memory newUri) public onlyAuthorized {
        require(isTokenUriFrozen[tokenId] == false, "Token is frozen");
        _tokenUris[tokenId] = newUri;
    }

    /**
    * @notice Freeze the Uri of a given token
    */
    function freezeTokenUri(uint256 tokenId) public onlyAuthorized {
        isTokenUriFrozen[tokenId] = true;
        emit PermanentURI(_tokenUris[tokenId], tokenId);
    }

    /**
    * @notice Retrieve the original creator for a given tokenId
    */
    function getTokenOriginalCreator(uint256 tokenId) public view returns (address creator) {
        return collectionOwner[tokenIdToCollectionId[tokenId]];
    }

    /**
    * @notice Retrieve Token Max Supply
    */
    function getTokenMaxSupply(uint256 tokenId) public view returns (uint256 maxSupply) {
        return tokenMaxSupply[tokenId];
    }

    /**
    * @notice Retrieve Token Minted amount
    */
    function getTokenMintedAmount(uint256 tokenId) public view returns (uint256 mintedAmount) {
        return tokenMinteds[tokenId];
    }

    /**
    * @notice Retrieve Royalties information for a given tokenId
    * If no custom royalties has been set, return base royalties (in Basis Points)
    */
    function getTokenRoyalties(uint256 tokenId) public view returns (uint256 royalties) {
        if (collectionRoyaltyPercentage[tokenIdToCollectionId[tokenId]] == 0) {
          return baseRoyaltiesInBasisPoints;
        }
        return collectionRoyaltyPercentage[tokenIdToCollectionId[tokenId]];
    }

    /**
    * @notice Retrieve paymentAddress for a given tokenId. If no alternative payment
    * address set, return the original creator's address
    */
    function getTokenRoyaltiesPaymentAddress(uint256 tokenId) public view returns (address creator) {
        if (collectionPaymentAddress[tokenIdToCollectionId[tokenId]] == address(0)) {
          return collectionOwner[tokenIdToCollectionId[tokenId]];
        }
        return collectionPaymentAddress[tokenIdToCollectionId[tokenId]];
    }

    /**
    * @notice Retrieve Royalty/Creator pair information for a given tokenId
    */
    function getRoyalties(uint256 tokenId) public view returns (address paymentAddress, uint256 royalties) {
        uint256 _royalties = getTokenRoyalties(tokenId);
        address _paymentAddress = getTokenRoyaltiesPaymentAddress(tokenId);
        return (_paymentAddress, _royalties);
    }

    /**
    * @notice Retrieve Royalties information for a given collectionId
    * If no custom royalties has been set, return base royalties (in Basis Points)
    */
    function getCollectionRoyalties(uint256 collectionId) public view returns (uint256 royalties) {
        if (collectionRoyaltyPercentage[collectionId] == 0) {
          return baseRoyaltiesInBasisPoints;
        }
        return collectionRoyaltyPercentage[collectionId];
    }

    /**
    * @notice Retrieve paymentAddress for a given collectionId. If no alternative payment
    * address set, return the original creator's address
    */
    function getCollectionRoyaltiesPaymentAddress(uint256 collectionId) public view returns (address creator) {
        if (collectionPaymentAddress[collectionId] == address(0)) {
          return collectionOwner[collectionId];
        }
        return collectionPaymentAddress[collectionId];
    }

    /**
    * @notice Retrieve Royalty/Creator pair information for a given collectionId
    */
    function getRoyaltiesPerCollection(uint256 collectionId) public view returns (address paymentAddress, uint256 royalties) {
        uint256 _royalties = getCollectionRoyalties(collectionId);
        address _paymentAddress = getCollectionRoyaltiesPaymentAddress(collectionId);
        return (_paymentAddress, _royalties);
    }

    /**
    * @notice Close a collection, no more token will are allowed to be minted
    */
    function setCloseCollection(uint256 collectionId) public onlyAuthorized {
        isCollectionClosed[collectionId] = true;
        emit CollectionClosed(collectionId);
    }

    /**
    * @notice Set an alternative payment address for a given collectionId
    * This address could be a contract address
    */
    function setCollectionPaymentAddress(uint256 collectionId, address _paymentAddress) public onlyAuthorized {
        collectionPaymentAddress[collectionId] = _paymentAddress;
        emit CollectionPaymentAddressUpdated(collectionId, _paymentAddress);
    }

    /**
    * @notice Set a custom Royalty fee, in basis points.
    * Maximum is 1000 (10%)
    * Custom Royalty can't be modified after a collection has been closed
    */
    function setCollectionRoyalties(uint256 collectionId, uint256 _royalties) public onlyAuthorized {
        require(_royalties <= 1000, "Royalties are too high");
        require(isCollectionClosed[collectionId] == false, "Collection is closed");
        collectionRoyaltyPercentage[collectionId] = _royalties;
        emit CollectionRoyaltiesUpdated(collectionId, _royalties);
    }

    /**
    * @notice Only an Authorized Contract can manage the Minting Function
    * The mintWrapper function is made to allow lazy minting
    * and lazy collection creation.
    *
    *
    * B A L L A D (R) *
    *
    */
    function mintWrapper(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        string memory targetUri,
        uint256 maxSupply,
        bool isFrozen,
        uint256 collectionId,
        bytes memory data
    ) public {
        // Only an Authorized Contract can use this function.
        require(authorizedContracts[msg.sender] == true, "Not Authorized");

        // Minting is only allowed in an opened collection
        require(isCollectionClosed[collectionId] == false, "Collection is closed");

        // If Collection Owner is set, only the owner should be able to mint.
        if (collectionOwner[collectionId] != address(0)) {
          require(from == collectionOwner[collectionId], "Minter is not the owner of the Collection");
        }

        // Froze the supply the first time a tokenId is minted
        if (tokenMaxSupply[id] == 0) {
            tokenMaxSupply[id] = maxSupply;
        }

        // The amount of token requested to be minted should be less than the total available supply
        require(
            (tokenMinteds[id] + amount) <= tokenMaxSupply[id],
            "Not enough supply"
        );

        // Minting process

        // The tokenUri is set the first time the minting function is called for a given tokenId.
        if (bytes(_tokenUris[id]).length == 0) {
            _tokenUris[id] = targetUri;
        }

        // Set whether the tokenUri is frozen or not
        if (isFrozen == true) {
            if (isTokenUriFrozen[id] == false) {
                isTokenUriFrozen[id] = true;
                emit PermanentURI(targetUri, id);
            }
        }

        // Assign every Token to a CollectionId - Once per Token
        if (tokenIdToCollectionId[id] == 0) {
          tokenIdToCollectionId[id] = collectionId;
          // The first minted token from a Collection should set the Collection Owner
          if (collectionOwner[collectionId] == address(0)) {
            collectionOwner[collectionId] = from;
          }
        }

        // Increment the current minted supply
        tokenMinteds[id] += amount;

        // Call original ERC1155 function from the original token creator
        _mint(from, id, amount, data);

        // Emit the minting event
        emit Minted(from, id, amount);

        // Transfer the token from the creator the buyer
        _safeTransferFrom(from, to, id, amount, data);
    }

    constructor(string memory _contractUri) ERC1155("") {
        baseRoyaltiesInBasisPoints = 500;
        contractUri = _contractUri;
    }
}
