// contracts/GameItems.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ReentrancyGuard.sol";
import "./strings.sol";
import "./KeyInterface.sol";
import "./IERC20.sol";


contract headAlpha is KeyInterface, ReentrancyGuard {
    using Strings for uint256;

    struct AccessInfo {
        uint256 cost; 
        uint256 limit; 
        bool saleLive;
    }

    mapping (address => bool)     private admins;    
    mapping(uint256 => AccessInfo) accessInfo;
    uint256[] public accessIDs;
    uint256 public nextID = 0;
    IERC20 public erc20Token;


    constructor() ERC1155("https://game-api.headdao.com/_routes/tokens/1155/metadata/") {
        erc20Token = IERC20(0x6725363E565BAA1dda45d492810298ae0b25c4ac);
        m_Name = 'Head Alpha';
        m_Symbol = 'hAlpha';
        _addmonth(10000, 300, false);

    }

    function mintAccess(uint256 _amount, uint256 _type) external nonReentrant() {
        address msgsender = _msgSender();
        AccessInfo memory _info = accessInfo[_type];
        require(tx.origin == msgsender, "Only EOA");
        require(_info.saleLive,"Sale for this type is not active");
        require(totalSupply(_type) + _amount <= _info.limit,"Sale for this type is sold out");
        uint256 totalCost = _amount * _info.cost;        
        require(erc20Token.balanceOf(msgsender) >= totalCost, "Not enough $HEAD");
        erc20Token.transferFrom(_msgSender(), address(this), totalCost);
        _mint(msgsender, _type, _amount, "");

    }


    // Add Mint Change functions
    function addNewMonth(uint256 _cost, uint256 _limit, bool _live) external onlyAdmin {
        _addmonth(_cost,_limit,_live);
    }

    function addCustomAccess(uint256 _id, uint256 _cost, uint256 _limit, bool _live) external onlyAdmin {
        require(!exists(_id),"ID Already Exists");
        accessInfo[_id]  = AccessInfo(_cost * 10 ** 18, _limit, _live);
        accessIDs.push(_id);
        _mint(_msgSender(), _id, 1, "");
    }

    function setSaleStatus(uint256 _id, bool _status) external onlyAdmin {
        require(exists(_id),"ID Does not Exist");
        AccessInfo memory _info = accessInfo[_id];
        accessInfo[_id]  = AccessInfo(_info.cost, _info.limit, _status);
    }

    function setAccessPrice(uint256 _id, uint256 _cost) external onlyAdmin {
        require(exists(_id),"ID Does not Exist");
        AccessInfo memory _info = accessInfo[_id];
        accessInfo[_id]  = AccessInfo(_cost * 10 ** 18, _info.limit, _info.saleLive);
    }

    function setAccessLimit(uint256 _id, uint256 _limit) external onlyAdmin {
        require(exists(_id),"ID Does not Exist");
        AccessInfo memory _info = accessInfo[_id];
        accessInfo[_id]  = AccessInfo(_info.cost, _limit, _info.saleLive);
    }
    
    function _addmonth(uint256 _cost, uint256 _limit, bool _live) private {
        if (exists(nextID)) nextID++;
        accessInfo[nextID]  = AccessInfo(_cost * 10 ** 18, _limit, _live);
        accessIDs.push(nextID);
        _mint(_msgSender(), nextID, 1, "");
        nextID ++;
    }

    // Read Plan Information
    function getCost(uint256 _id) public view returns (uint256 cost) {
        AccessInfo memory _info = accessInfo[_id];
        cost = _info.cost;
    }

    function getSaleStatus(uint256 _id) public view returns (bool _status) {
        AccessInfo memory _info = accessInfo[_id];
        _status = _info.saleLive;
    }

    function getLimit(uint256 _id) public view returns (uint256 _limit) {
        AccessInfo memory _info = accessInfo[_id];
        _limit = _info.limit;
    }

    function nTypes() public view  returns (uint256) {
        return accessIDs.length;
    }

    function getAll() public view returns (uint256[] memory _accessIDs) {
        _accessIDs = accessIDs;
    }

    function getAccessInfo(uint256 _id) public view returns (AccessInfo memory _info) {
        _info = accessInfo[_id];
    }


    //  Admin Functions (Not Used Often)
    function setHeadAddress(address _head) external onlyAdmin {
       erc20Token = IERC20(_head);
    }
        
    function setURI(string memory newuri) external onlyAdmin {
        _setURI(newuri);
    }

    function addAdmin(address _address, bool status) public onlyAdmin {
        admins[_address] = status;
    }

    function withdrawTokens() external onlyAdmin {
        uint256 tokenSupply = erc20Token.balanceOf(address(this));
        erc20Token.transfer(msg.sender, tokenSupply);
    }

    
    // ETC
    function uri(uint256 _id) public view override returns (string memory) {
        require(totalSupply(_id) > 0, "URI: nonexistent token");
        return string(abi.encodePacked(super.uri(_id),_id.toString()));
    } 

    modifier onlyAdmin() {
        require(owner() == _msgSender() || admins[_msgSender()], "Only admins can call this");
        _;
    }


    
}