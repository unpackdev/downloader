//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Strings.sol";

contract AssholeSBT {
    using Address for address;
    using Strings for uint256;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    address private _owner;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    uint256 amountStored;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(uint256 => string) private _uris;

    uint256 totalSupply;

    constructor() {
        _name = "Asshole Soul Bound Token";
        _symbol = "ASBT";
        _owner = msg.sender;
        totalSupply = 0;
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "wtf");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "wtf");
        return owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "wtf");

        return string(_uris[tokenId]);
    }

    function mint(address to, string memory _reason) public payable {
        require(to != address(0), "dumbass");
        require(to != msg.sender, "no self owns");
        require(msg.value >= 0.05 ether, "ain't a charity...");
        amountStored += msg.value;
        ++totalSupply;
        _balances[to] += 1;
        _owners[totalSupply] = to;
        _uris[totalSupply] = _reason;
        emit Transfer(address(0), to, totalSupply);
    }

    function burn(uint256 id) public payable {
        if (msg.sender != _owner) {
            require(msg.value >= 32 ether, "stake me");
        }
        amountStored += msg.value;
        address owner = ownerOf(id);
        _balances[owner] -= 1;
        delete _owners[id];

        emit Transfer(owner, address(0), id);
    }

    function withdraw() public payable {
        require(msg.sender == _owner, "f off");
        payable(msg.sender).transfer(amountStored);
    }
}
