// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Governable.sol";
import "./Signature.sol";

contract DeFineBadge is Governable, ERC1155, Signature {
    using Strings for uint256;
    
    bool private saleIsActive;
    uint256 private _counter;
    string public name;
    string public symbol;
    string public baseURI;
    address public signer;

    struct BadgeInfo {
        string _type;
        uint256 _maxCount;
        uint256 startAt;
        uint256 endAt;
        uint256 _mintLimit;
        address _minter;
    }
    
    event Mint(address indexed owner, string _type, uint256 _id);

    mapping(uint256 => BadgeInfo) public BadgesInfo;
    mapping(string => uint256) public typeList; // string type => tokenId
    mapping(uint256 => uint256) public mintedCount; // tokenId => minted Count
    mapping(uint256 => mapping(address => uint256)) public userMinted; // [tokenId], user Address => minted Count

    modifier onlyMinter(string memory _type) {
        BadgeInfo memory badge = BadgesInfo[typeList[_type]];
        require(msg.sender == badge._minter, "only minter");
        _;
    }
    
    modifier whenSaleActive {
        require(saleIsActive, "Sale is not active");
        _;
    }
    
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _signer
    ) ERC1155(baseURI) {
        saleIsActive = true;
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        signer = _signer;
        _setURI(_baseURI);
        super.initialize(msg.sender);
    }

    function newBadge(
        string memory _type,
        uint256 _maxCount,
        uint256 startAt,
        uint256 endAt,
        uint256 _mintLimit,
        address minter
    ) external governance returns (bool) {
        require(typeList[_type] == 0, "Type is already created");
        _counter += 1;
        BadgeInfo memory badge = BadgeInfo(_type, _maxCount, startAt, endAt, _mintLimit, minter);
        BadgesInfo[_counter] = badge;
        typeList[_type] = _counter;
        return true;
    }

    function uri(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function mint(
        string memory _type,
        uint256 _nonce,
        bytes memory _signature
    ) public {
        address real_signer = verify(
            signer,
            msg.sender,
            _type,
            _nonce,
            _signature
        );
        require(signer == real_signer, "invalid signature");
        mintTo(_type, msg.sender);
    }

    function airdrop(
        string memory _type,
        address _to
    ) public onlyMinter(_type) {
        mintTo(_type, _to);
    }

    function mintTo(
        string memory _type,
        address _to
    ) internal whenSaleActive {
        uint256 _id = typeList[_type];
        BadgeInfo memory badge = BadgesInfo[_id];
        require(_id > 0, "invalid badge type");
        require(block.timestamp >= badge.startAt, "mint does't start");
        require(block.timestamp <= badge.endAt, "mint is already ended");
        require(mintedCount[_id] < badge._maxCount, "mint max cap reached");
        require((userMinted[_id])[_to] < badge._mintLimit, "mint per user limit reached");
        _mint(_to, _id, 1, "");
         mintedCount[_id] ++;
        (userMinted[_id])[_to] ++;
        emit Mint(msg.sender, _type, _id);
    }
    
    function setURI(string memory _baseURI) external governance returns (bool) {
        baseURI = _baseURI;
        _setURI(_baseURI);
        return true;
    }

    function setSigner(address _signer) external governance returns (bool) {
        signer = _signer;
        return true;
    }
    
    function setMinter(string memory _type, address _address) external governance returns (bool) {
        BadgeInfo storage badge = BadgesInfo[typeList[_type]];
        badge._minter = _address;
    }
    
    function setMaxCount(string memory _type, uint256 _count) external governance returns (bool) {
        BadgeInfo storage badge = BadgesInfo[typeList[_type]];
        badge._maxCount = _count;
    }
    
    function setStartTime(string memory _type, uint256 _startTime) external governance returns (bool) {
        BadgeInfo storage badge = BadgesInfo[typeList[_type]];
        badge.startAt = _startTime;
    }
    
    function setEndTime(string memory _type, uint256 _endTime) external governance returns (bool) {
        BadgeInfo storage badge = BadgesInfo[typeList[_type]];
        badge.endAt = _endTime;
    }
    
    function setMintLimit(string memory _type, uint256 _limit) external governance returns (bool) {
        BadgeInfo storage badge = BadgesInfo[typeList[_type]];
        badge._mintLimit = _limit;
    }
    
    function toogleSaleIsActive() external governance {
        saleIsActive = !saleIsActive;
    }
    
    function getSigner() external governance returns (address) {
        return signer;
    }
    
    function getMinter(string memory _type) external governance returns (address) {
        BadgeInfo memory badge = BadgesInfo[typeList[_type]];
        return badge._minter;
    }
    
    function getMaxCount(string memory _type, uint256 _count) external governance returns (uint256) {
        BadgeInfo memory badge = BadgesInfo[typeList[_type]];
        return badge._maxCount;
    }
    
    function getStartTime(string memory _type, uint256 _startTime) external governance returns (uint256) {
        BadgeInfo memory badge = BadgesInfo[typeList[_type]];
        return badge.startAt;
    }
    
    function getEndTime(string memory _type, uint256 _endTime) external governance returns (uint256) {
        BadgeInfo memory badge = BadgesInfo[typeList[_type]];
        return badge.endAt;
    }
    
    function getMintLimit(string memory _type, uint256 _limit) external governance returns (uint256) {
        BadgeInfo memory badge = BadgesInfo[typeList[_type]];
        return badge._mintLimit;
    }
}
