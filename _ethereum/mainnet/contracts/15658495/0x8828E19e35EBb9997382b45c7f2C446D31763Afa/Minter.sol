// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;
import "./ERC1155.sol";

contract Minter is ERC1155 {
    struct dropInfo {
        address creator;
        uint256 supply;
        uint256 maxSupply;
        uint256 price;
        bool active;
        string uri;
    }

    uint256 id;
    mapping(uint256 => dropInfo) public drops;
    mapping(address => uint256[]) public userDrops;

    constructor() ERC1155("") {}

    modifier onlyCreator(uint256 _id) {
        require(drops[_id].creator == msg.sender, "Only creator can do this");
        _;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return drops[_id].uri;
    }

    function createDrop(
        uint256 _maxSupply,
        uint256 _price,
        string memory _uri
    ) public {
        userDrops[msg.sender].push(id);
        drops[id] = dropInfo(msg.sender, 0, _maxSupply, _price, false, _uri);
        id++;
    }

    function editDrop(
        uint256 _id,
        uint256 _maxSupply,
        uint256 _price,
        string memory _uri
    ) public onlyCreator(_id) {
        drops[_id].maxSupply = _maxSupply;
        drops[_id].price = _price;
        drops[_id].uri = _uri;
    }

    function creatorMint(uint256 _id, uint256 _amount) public onlyCreator(_id) {
        require(
            drops[_id].supply + _amount <= drops[_id].maxSupply,
            "Max supply reached"
        );
        drops[_id].supply += _amount;
        _mint(msg.sender, _id, _amount, "");
    }

    function devAirdrop(uint256 _id, address[] memory _users)
        public
        onlyCreator(_id)
    {
        for (uint256 i = 0; i < _users.length; i++) {
            _mint(_users[i], _id, 1, "");
        }
    }

    function activateDrop(uint256 _id) public onlyCreator(_id) {
        drops[_id].active = true;
    }

    function publicMint(uint256 _id, uint256 _amount) public payable {
        require(drops[_id].active, "Drop not active");
        require(
            drops[_id].supply + _amount <= drops[_id].maxSupply,
            "Max supply reached"
        );
        require(
            msg.value == drops[_id].price * _amount,
            "Incorrect amount sent"
        );
        drops[_id].supply += _amount;
        _mint(msg.sender, _id, _amount, "");
    }
}
