// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract MintableERC1155 is Initializable, ERC1155Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;

    string public name;
    string public symbol;
    string private _uri;

    uint256 private _currentTokenID;

    mapping (uint256 => address) public creators;
    mapping (uint256 => uint256) public tokenSupply;
    mapping (uint256 => uint256) public maxTokenSupply;
    mapping (uint256 => uint256) public tokenPrice;

    modifier creatorOnly(uint256 _id) {
        require(creators[_id] == msg.sender, "ONLY_CREATOR_ALLOWED");
        _;
    }

    function initialize(
        string memory uri_,
        string memory name_,
        string memory symbol_
    ) initializer public {
        __ERC1155_init(uri_);
        __Ownable_init();
        __UUPSUpgradeable_init();
        name = name_;
        symbol = symbol_;
        _currentTokenID = 0;
        _setURI(uri_);
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        require(_exists(_id), "NONEXISTENT_TOKEN");
        return string(abi.encodePacked(_uri, StringsUpgradeable.toString(_id), ".json"));
    }

    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function mintMembership(uint256 _id, bytes memory _data)
        public
        payable
    {
        require(_exists(_id), "NONEXISTENT_TOKEN");
        uint256 maxSupply = maxTokenSupply[_id];
        uint256 supply = tokenSupply[_id];
        require(supply < maxSupply, "max limit");

        uint256 price = tokenPrice[_id];
        require(price <= msg.value, "insuffient amount");

        address creator = creators[_id];

        (bool sent, /* bytes memory data */) = creator.call{value: msg.value.div(1000).mul(975)}("");
        require(sent, "Failed to send Ether");

        tokenSupply[_id] = tokenSupply[_id].add(1);
        _mint(msg.sender, _id, 1, _data);
    }

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public creatorOnly(_id) {
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }

    function create(
        uint256 _maxTokenSupply,
        uint256 _tokenPrice,
        bytes calldata _data
    ) external returns (uint256) {
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();
        creators[_id] = msg.sender;
        maxTokenSupply[_id] = _maxTokenSupply;
        tokenPrice[_id] = _tokenPrice;

        _mint(msg.sender, _id, 1, _data);
        tokenSupply[_id] = 1;
        return _id;
    }

    function setCreator(
        address _to,
        uint256[] memory _ids
    ) public {
        require(_to != address(0), "INVALID_ADDRESS");
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            _setCreator(_to, id);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;

        (bool sent, /* bytes memory data */) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    function contractURI() public pure returns (string memory) {
        return "https://connect.club/";
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function _setCreator(address _to, uint256 _id) internal creatorOnly(_id) {
        creators[_id] = _to;
    }

    function _setURI(string memory newuri) internal override virtual {
        _uri = newuri;
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID.add(1);
    }

    function _incrementTokenTypeId() private  {
        _currentTokenID++;
    }

    function _exists(
        uint256 _id
    ) internal view returns (bool) {
        return creators[_id] != address(0);
    }
}