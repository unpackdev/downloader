// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./Pausable.sol";
import "./Address.sol";
import "./IERC721Enumerable.sol";
import "./CloneFactory.sol";
import "./ICollection.sol";

/// @title CollectionFactoryV2
/// @author Chain Labs
/// @notice a single factory to create multiple and various clones of collection.
/// @dev new collection type can be added and deployed
contract CollectionFactoryV2 is Pausable, Ownable, CloneFactory {
    //------------------------------------------------------//
    //
    //  Storage
    //
    //------------------------------------------------------//
    /// @notice version of Collection Factory
    /// @dev version of collection factory
    /// @return VERSION version of collection factory
    string public constant VERSION = "0.2.0";

    /// @notice address of Simplr Afffiliate Registry
    /// @dev address of simplr affiliate registry
    /// @return affiliateRegistry address of simple affiliate registry
    address public affiliateRegistry;

    /// @notice address of Simplr Early Access Token
    /// @dev only ERC721 contract address
    /// @return freePass address of SEAT (Simplr Early Access Token)
    address public freePass;

    /// @notice simplr fee receiver gnosis safe
    /// @dev all the fees is transfered to Simplr's Fee Receiver Gnosis Safe
    /// @return simplr Simplr Fee receiver gnosis safe
    address public simplr;

    /// @notice fixed share of simplr for each collection sale
    /// @dev in the beginning it is set to 0%, then gradually it will increase to 1% max
    /// @return simplrShares shares of simplr
    uint256 public simplrShares;

    /// @notice upfront fee to start a new collection
    /// @dev upfront fee to start a new collection
    /// @return upfrontFee upfront fee to start a new collection
    uint256 public upfrontFee;

    /// @notice total amount of upfront fee withdrawn from Factory
    /// @dev used to calculate total fee collected
    /// @return totalWithdrawn total amount of upfront fee withdrawn from Factory
    uint256 public totalWithdrawn;

    /// @notice ID of Simplr Collection in affiliate registry
    /// @dev ID that is used to identify Simplr Collection by affiliate registry
    /// @return affiliateProjectId ID of Simplr Collection in affiliate registry
    bytes32 public affiliateProjectId;

    /// @notice list of various collection types
    /// @dev mapping of collection id with master copy of collection
    /// @return mastercopies master copy address of a collection type
    mapping(uint256 => address) public mastercopies;

    /// @notice logs whenever new collection is created
    /// @dev emitted when new collection is created
    /// @param collection address of new collection
    /// @param admin admin address of new collection
    /// @param collectionType type of collection deployed
    event CollectionCreated(
        address indexed collection,
        address indexed admin,
        uint256 indexed collectionType
    );

    /// @notice logs when new collection type is added
    /// @dev emitted when new collection type is added
    /// @param collectionType ID of collection type
    /// @param mastercopy address of collection type master copy
    /// @param data collection type specific data eg. name of collection type
    event NewCollectionTypeAdded(
        uint256 indexed collectionType,
        address mastercopy,
        bytes data
    );

    //------------------------------------------------------//
    //
    //  Constructor
    //
    //------------------------------------------------------//

    /// @notice constructor
    /// @param _masterCopy address of implementation contract
    /// @param _data collection type specific data
    /// @param _simplr address of simplr beneficiary
    /// @param _newRegistry address of affiliate registry
    /// @param _newProjectId ID of Simplr Collection in Affiliate Registry
    /// @param _simplrShares shares of simplr, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
    /// @param _upfrontFee upfront fee to start a new collection
    constructor(
        address _masterCopy,
        bytes memory _data,
        address _simplr,
        address _newRegistry,
        bytes32 _newProjectId,
        uint256 _simplrShares,
        uint256 _upfrontFee
    ) {
        require(_masterCopy != address(0), "CFv2:001");
        require(_simplr != address(0), "CFv2:002");
        simplr = _simplr;
        simplrShares = _simplrShares;
        upfrontFee = _upfrontFee;
        affiliateRegistry = _newRegistry;
        affiliateProjectId = _newProjectId;
        _addNewCollectionType(_masterCopy, 1, _data);
    }

    //------------------------------------------------------//
    //
    //  Owner only functions
    //
    //------------------------------------------------------//

    /// @notice set simplr fee receiver address
    /// @dev set Simplr Fee Receiver Gnosis Safe
    /// @param _simplr address of Simplr Fee receiver
    function setSimplr(address _simplr) external onlyOwner {
        require(_simplr != address(0) && simplr != _simplr, "CFv2:003");
        simplr = _simplr;
    }

    /// @notice set Simplr Early Access Token address
    /// @dev it can only be ERC721 type contract
    /// @param _freePass adddress of SEAT (Simplr Early Access Token)
    function setFreePass(address _freePass) external onlyOwner {
        require(
            _freePass != address(0) &&
                IERC165(_freePass).supportsInterface(type(IERC721).interfaceId),
            "CFv2:010"
        );
        freePass = _freePass;
    }

    /// @notice set Simplr Shares
    /// @dev update simplr shares
    /// @param _simplrShares new shares of simplr
    function setSimplrShares(uint256 _simplrShares) external onlyOwner {
        simplrShares = _simplrShares;
    }

    /// @notice sets new upfront fee
    /// @dev sets new upfront fee
    /// @param _upfrontFee  new upfront fee
    function setUpfrontFee(uint256 _upfrontFee) external onlyOwner {
        upfrontFee = _upfrontFee;
    }

    /// @notice set Simplr Affiliate Registry address
    /// @dev set new Simplr Affiliate registry address
    /// @param _newRegistry address of new simplr affiliate registry address
    function setAffiliateRegistry(address _newRegistry) external onlyOwner {
        affiliateRegistry = _newRegistry;
    }

    /// @notice set project ID of Simplr Collection
    /// @dev Identifier of Simplr Collection in Affiliate Registry
    /// @param _newProjectId new project ID
    function setAffiliateProjectId(bytes32 _newProjectId) external onlyOwner {
        affiliateProjectId = _newProjectId;
    }

    /// @notice set new master copy for a collection type
    /// @dev set new master copy for a collection type
    /// @param _newMastercopy new master copy address
    /// @param _type collection type ID
    function setMastercopy(address _newMastercopy, uint256 _type)
        external
        onlyOwner
    {
        require(
            _newMastercopy != address(0) &&
                _newMastercopy != mastercopies[_type],
            "CFv2:004"
        );
        require(mastercopies[_type] != address(0), "CFv2:005");
        mastercopies[_type] = _newMastercopy;
    }

    /// @notice withdraw collected upfront fees
    /// @dev withdraw specific amount
    /// @param _value amount to withdraw
    function withdraw(uint256 _value) external onlyOwner {
        require(_value <= address(this).balance, "CFv2:008");
        totalWithdrawn += _value;
        Address.sendValue(payable(simplr), _value);
    }

    /// @notice pause creation of collection
    /// @dev pauses all the public methods, using OpenZeppelin's Pausable.sol
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice unpause creation of collection
    /// @dev unpauses all the public methods, using OpenZeppelin's Pausable.sol
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /// @notice add new collection type
    /// @dev only owner can add new collection type
    /// @param _mastercopy address of collection mastercopy
    /// @param _type type of collection
    /// @param _data bytes string to store  arbitrary data about the collection in emitted events eg. explaination about the  type
    function addNewCollectionType(
        address _mastercopy,
        uint256 _type,
        bytes memory _data
    ) external onlyOwner {
        _addNewCollectionType(_mastercopy, _type, _data);
    }

    //------------------------------------------------------//
    //
    //  Public function
    //
    //------------------------------------------------------//

    /// @notice create new collection
    /// @dev deploys new collection using cloning
    /// @param _type type of collection to be deployed
    /// @param _baseCollection struct with params to setup base collection
    /// @param _presaleable  struct with params to setup presaleable
    /// @param _paymentSplitter struct with params to setup payment splitting
    /// @param _projectURIProvenance  struct with params to setup reveal details
    /// @param _metadata ipfs hash or CID for the metadata of collection
    function createCollection(
        uint256 _type,
        ICollection.BaseCollectionStruct memory _baseCollection,
        ICollection.PresaleableStruct memory _presaleable,
        ICollection.PaymentSplitterStruct memory _paymentSplitter,
        bytes32 _projectURIProvenance,
        ICollection.RoyaltyInfo memory _royalties,
        uint256 _reserveTokens,
        string memory _metadata,
        bool _isAffiliable,
        bool _useSeat,
        uint256 _seatId
    ) external payable whenNotPaused {
        require(mastercopies[_type] != address(0), "CFv2:005");
        if (_useSeat && IERC721(freePass).balanceOf(msg.sender) > 0) {
            _paymentSplitter.simplrShares = 1;
            IERC721(freePass).transferFrom(msg.sender, address(this), _seatId);
        } else {
            require(msg.value == upfrontFee, "CFv2:006");
            _paymentSplitter.simplrShares = simplrShares;
        }
        _paymentSplitter.simplr = simplr;
        address collection = createClone(mastercopies[_type]);
        ICollection(collection).setMetadata(_metadata);
        if (
            _isAffiliable &&
            affiliateRegistry != address(0) &&
            affiliateProjectId != bytes32(0)
        ) {
            ICollection(collection).setupWithAffiliate(
                _baseCollection,
                _presaleable,
                _paymentSplitter,
                _projectURIProvenance,
                _royalties,
                _reserveTokens,
                IAffiliateRegistry(affiliateRegistry),
                affiliateProjectId
            );
        } else {
            ICollection(collection).setup(
                _baseCollection,
                _presaleable,
                _paymentSplitter,
                _projectURIProvenance,
                _royalties,
                _reserveTokens
            );
        }
        emit CollectionCreated(collection, _baseCollection.admin, _type);
    }

    //------------------------------------------------------//
    //
    //  Internal function
    //
    //------------------------------------------------------//

    /// @notice internal method to add new collection types
    /// @dev used to add new collection type by constrcutor too
    /// @param _mastercopy address of collection mastercopy
    /// @param _type type of collection
    /// @param _data bytes string to store  arbitrary data about the collection in emitted events eg. explaination about the  type
    function _addNewCollectionType(
        address _mastercopy,
        uint256 _type,
        bytes memory _data
    ) private {
        require(mastercopies[_type] == address(0), "CFv2:009");
        require(_mastercopy != address(0), "CFv2:001");
        mastercopies[_type] = _mastercopy;
        emit NewCollectionTypeAdded(_type, _mastercopy, _data);
    }
}
