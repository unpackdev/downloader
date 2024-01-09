// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Ownable.sol";
import "./Pausable.sol";
import "./CloneFactory.sol";
import "./ICollection.sol";

contract CollectionFactory is Pausable, Ownable, CloneFactory {
    address public mastercopy; //address of mastercopy of Project contract.
    address public nftify; // address of nftify beneficiary
    uint256 public nftifyShares; // shares of nftify, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
    uint256 public upfrontFee; // upfront fee to start a new project
    uint256 public totalWithdrawn; // total amount of upfront fee withdrawn from Factory

    event CollectionCreated(address indexed project, address indexed admin); // emitted when new project contract is created

    /**
     * @dev constructor
     * @param _masterCopy address of implementation contract
     * @param _nftify  address of nftify beneficiary
     * @param _nftifyShares shares of nftify, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
     * @param _upfrontFee upfront fee to start a new project
     */
    constructor(
        address _masterCopy,
        address _nftify,
        uint256 _nftifyShares,
        uint256 _upfrontFee
    ) {
        require(
            _masterCopy != address(0),
            "CollectionFactory: Master Copy address cannot be zero"
        );
        require(
            _nftify != address(0),
            "CollectionFactory: NFTify address cannot be zero"
        );
        mastercopy = _masterCopy;
        nftify = _nftify;
        nftifyShares = _nftifyShares;
        upfrontFee = _upfrontFee;
    }

    /**
     * @dev set nftify beneficiary address
     * @param _nftify address of nftify beneficiary
     */
    function setNFTify(address _nftify) external onlyOwner {
        require(
            _nftify != address(0) && nftify != _nftify,
            "CollectionFactory: Invalid nftify address"
        );
        nftify = _nftify;
    }

    /**
     * @dev set new nftify shares
     * @param _nftifyShares shares of nftify, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
     */
    function setNFTifyShares(uint256 _nftifyShares) external onlyOwner {
        nftifyShares = _nftifyShares;
    }

    /**
     * @dev set new upfront fee
     * @param _upfrontFee upfront fee to start a new project
     */
    function setUpfrontFee(uint256 _upfrontFee) external onlyOwner {
        upfrontFee = _upfrontFee;
    }

    /**
     * @dev                  set mastercopy address that will be used for creating project clones
     * @param _newMastercopy address of new mastercopy
     */
    function setMastercopy(address _newMastercopy) external onlyOwner {
        require(
            _newMastercopy != address(0) && _newMastercopy != mastercopy,
            "CollectionFactory: Invalid mastercopy"
        );
        mastercopy = _newMastercopy;
    }

    /**
     * @dev create new collection contract clone
     * @param _baseCollection struct with params to setup base collection
     * @param _presaleable  struct with params to setup presaleable
     * @param _paymentSplitter struct with params to setup payment splitting
     * @param _revealable  struct with params to setup reveal details
     * @param _metadata ipfs hash or CID for the metadata of collection
     */
    function createProject(
        ICollection.BaseCollectionStruct memory _baseCollection,
        ICollection.PresaleableStruct memory _presaleable,
        ICollection.PaymentSplitterStruct memory _paymentSplitter,
        ICollection.RevealableStruct memory _revealable,
        string memory _metadata
    ) external payable whenNotPaused {
        require(
            msg.value == upfrontFee,
            "CollectionFactory: transfer exact value"
        );
        address collection = createClone(mastercopy);
        _paymentSplitter.nftify = nftify;
        _paymentSplitter.nftifyShares = nftifyShares;
        ICollection(collection).setMetadata(_metadata);
        ICollection(collection).setup(
            _baseCollection,
            _presaleable,
            _paymentSplitter,
            _revealable
        );
        emit CollectionCreated(collection, _baseCollection.admin);
    }

    /**
     * @dev withdraw the upfront fee
     * @param _value amount of fee to be withdrawn
     */
    function withdraw(uint256 _value) external onlyOwner {
        require(
            _value <= address(this).balance,
            "CollectionFactory: Low balance"
        );
        totalWithdrawn += _value;
        payable(nftify).transfer(_value);
    }

    /**
     * @dev pause the factory, using OpenZeppelin's Pausable.sol
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev unpause the factory, using OpenZeppelin's Pausable.sol
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }
}
