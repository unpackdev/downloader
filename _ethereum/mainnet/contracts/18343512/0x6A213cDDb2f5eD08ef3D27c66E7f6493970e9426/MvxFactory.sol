// SPDX-License-Identifier: MIT O
pragma solidity ^0.8.20;

import "./LibClone.sol";
import "./Clone.sol";
import "./IERC721A.sol";
import "./MvxCollection.sol";

/**
 * @title MvxFactory contract to create erc721's clones with immutable arguments
 * @author MoonveraLabs
 */
contract MvxFactory {
    // Keep track of collections/clones per user
    mapping(address => address) public collections;

    // MvxFactory  address(user) => validUntil;
    mapping(address => uint256) public members;

    // Current MvxCollection template
    address public _collectionImpl;

    // ownable by deployer
    address public _owner;

    // default art collection deploy fee
    uint256 public _deployFee;

    // Fee to charge for any mint
    uint96 public platformFee;

    // count of total number of collections
    uint256 _totalCollections;

    error CreateCloneError();
    error InvalidColletion(uint8);

    event CreateCloneEvent(address indexed sender, address impl, address cloneAddress);

    event InitOwnerEvent(address sender);
    event InitCollectionEvent(address sender, address collection);
    event CreateCollectionEvent(address sender, address template, address clone);

    constructor(uint96 _platformFee) {
        _owner = payable(msg.sender);
        platformFee = _platformFee;
        emit InitOwnerEvent(_owner);
    }

    receive() external payable {}

    fallback() external payable {
        revert("Unsupported");
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender] >= block.timestamp, "Only members");
        _;
    }

    modifier auth() {
        require(msg.sender == _owner || members[msg.sender] >= block.timestamp, "Only Auth");
        _;
    }

    /// @notice Access: only Owner
    /// @param _fee new fee on mint
    /// @dev payable for gas saving
    function updatePlatformFee(uint96 _fee) external payable onlyOwner {
        platformFee = _fee;
    }

    /// @notice Access: only Owner
    /// @param impl Clone's proxy implementation of MvxCollection logic
    /// @dev payable for gas saving
    function setCollectionImpl(address impl) external payable onlyOwner {
        if (!MvxCollection(impl).supportsInterface(type(IERC721A).interfaceId)) {
            revert InvalidColletion(2);
        }
        _collectionImpl = impl;
    }

    /// @notice Access: only Owner
    /// @dev payable for gas saving
    function transferOwnerShip(address newOner) external payable onlyOwner {
        require(newOner != address(0x0), "Zero address");
        _owner = newOner;
    }

    /// @notice Access: only Owner
    /// @dev payable for gas saving
    function withdraw() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /// @notice Access: only Owner
    /// @dev payable for gas saving
    function updateDeployFee(uint256 _newFee) external payable onlyOwner {
        require(_newFee > 0, "Invalid Fee");
        _deployFee = _newFee;
    }

    /// @notice Access: only Owner
    /// @param user only Owner
    /// @param expire days from today to membership expired
    /// @dev payable for gas saving
    function updateMember(address user, uint256 expire) external payable onlyOwner {
        uint256 validUntil = block.timestamp + (expire * 60 * 60 * 24);
        require(block.timestamp < validUntil, "Invalid valid until");
        members[user] = validUntil;
    }

    /// @notice Deploys MvxCollection Immutable proxy clone and call initialize
    /// @dev access: Admin or Current member
    /// @dev _deployFee & _mintFee are set by MvxFactory ADMIN
    /// @param nftsData only Owner
    /// @param initialOGMinters  List of OG memeber addresses
    /// @param initialWLMinters List of WL memeber addresses
    /// @param mintingStages Details of Regular,OG & WL minting stages
    function createCollection(
        bytes calldata nftsData,
        address[] calldata initialOGMinters,
        address[] calldata initialWLMinters,
        uint256[] calldata mintingStages
    ) external payable auth returns (address _clone) {
        require(msg.value >= _deployFee, "Missing deploy fee");

        bytes memory data = abi.encodePacked(msg.sender);

        _clone = LibClone.clone(address(_collectionImpl), data);

        if (_clone == address(0x0)) revert CreateCloneError();
        collections[msg.sender] = _clone;
        emit CreateCollectionEvent(msg.sender, _collectionImpl, _clone);

        if (msg.value - _deployFee > 0) {
            payable(msg.sender).transfer(msg.value - _deployFee);
        }
        delete members[msg.sender]; // only one time create clone

        // Init Art collection proxy clone
        MvxCollection(_clone).initialize(
            platformFee, // set by MvxFactory owner
            nftsData,
            initialOGMinters,
            initialWLMinters,
            mintingStages
        );

        unchecked {
            _totalCollections = _totalCollections + 1;
        }
        emit InitCollectionEvent(msg.sender, _clone);
    }

    function getTime() public view returns (uint256 _time) {
        _time = block.timestamp;
    }

    /// @param _daysFromNow current timestamp plus days
    function getTime(uint256 _daysFromNow) public view returns (uint256 _time) {
        _time = block.timestamp + (_daysFromNow * 60 * 60 * 24);
    }

    function totalCollections() external view returns (uint256 _total) {
        _total = _totalCollections;
    }
}
