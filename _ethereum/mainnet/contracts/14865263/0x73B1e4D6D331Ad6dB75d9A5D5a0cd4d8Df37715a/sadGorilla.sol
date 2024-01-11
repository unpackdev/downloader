// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract SadGorilla is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    uint256 private _Ids;
    mapping(uint256 => string) private tokenURIs;
    // Base URI
    uint256 private MAX_MONKEYS = 999;
    string private baseURI = "https://gateway.pinata.cloud/ipfs/QmPecMJC6XnJPii8o61jTH4nX48K1Zq2XGUuWXocM1YR6y/";
    uint256 private MINT_COST = 0.0999 ether;

    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        _Ids = 0;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function mint() external payable returns (uint256) {
        require(_Ids < MAX_MONKEYS, "Sold Out");
        require(msg.value >= MINT_COST, "Insufficient Ether");
        if(_Ids == 300 || _Ids == 633 || _Ids == 966) {
            _Ids += 33;
        }
        _Ids++;
        _mint(msg.sender, _Ids);
        return _Ids;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
	  require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
      return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawMoney() public onlyOwner{
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }
}