// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract Cubelets is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;
    IERC20 token = IERC20(address(0x3D3D35bb9bEC23b06Ca00fe472b50E7A4c692C30));
    string  public base;
    uint256 public price;
    mapping(string => uint8) hashes;
    
    constructor(string memory _base, uint256 _price) ERC721("Cubelets", "CUBE") {
        base  = _base;
        price = _price;
    }

    function claim(string memory hash) public returns (uint256) {
        require(hashes[hash] != 1, "Cubelets: Hash already claimed.");
        require(token.transferFrom(msg.sender, address(this), price), "Cubelets: Token transfer failed.");
        hashes[hash] = 1;
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, hash);
        return newItemId;
    }
    
    function totalSupply() public view returns(uint256) {
        return _tokenIds.current();
    }
    
    function _baseURI() internal override view returns(string memory) {
        return base;
    }

    function changeBase(string memory _new) external onlyOwner { base = _new; }
    function changePrice(uint256 _new) external onlyOwner { price = _new; }
    
    function withdrawERC20(address _token) external onlyOwner {
        IERC20 erc20 = IERC20(_token);
        erc20.transfer(owner(), token.balanceOf(address(this)));
    }
}