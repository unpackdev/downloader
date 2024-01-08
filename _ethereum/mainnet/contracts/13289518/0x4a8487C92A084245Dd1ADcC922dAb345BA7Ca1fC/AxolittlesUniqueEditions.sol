// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "./ERC721.sol";

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address tokenOwner) external view returns (uint balance);
  function allowance(address tokenOwner, address spender) external view returns (uint remaining);
  function transfer(address to, uint tokens) external returns (bool success);
  function approve(address spender, uint tokens) external returns (bool success);
  function transferFrom(address from, address to, uint tokens) external returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract AxolittlesUniqueEditions is ERC721 {

    event Mint(uint indexed _tokenId);

    address public owner;
    uint public totalSupply = 0; // This is our mint counter as well
    string public _baseTokenURI;

    constructor() payable ERC721("Axolittles Unique Editions", "AXOUNIQUE") {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function mint() external onlyOwner {
        _mint(msg.sender, totalSupply);
        emit Mint(totalSupply);
        totalSupply += 1; // Increment the counter
    }

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function setBaseTokenURI(string memory __baseTokenURI) external onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    // METADATA FUNCTIONALITY

    /**
     * @dev Returns a URI for a given token ID's metadata
     */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId)));
    }
}