// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

contract Zarah is ERC721, IERC2981, Ownable {
    event PermanentURI(string _value, uint256 indexed _id);
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private _uriBase;
    address private _proxy;
    uint256 private _royalties;

    constructor(string memory cid, address proxy) ERC721("zarah.ai", "ZAH") {
        _proxy = proxy;
        _uriBase = string(abi.encodePacked("ipfs://", cid, "/"));
        _royalties = 500;
    }

    function mintNFTs() public onlyOwner {
        for (uint i = 0; i < 22; i++) {
            _tokenIds.increment();
            uint256 newId = _tokenIds.current();
            _mint(msg.sender, newId);
            emit PermanentURI(tokenURI(newId), newId);
        }
    }

    function setRoyalties(uint256 amount) external onlyOwner {
        require(amount < 1001, "Royalties: new amount is more than than 10%");
        _royalties = amount;
    }

    function royaltyInfo(uint256 token, uint256 price) external view override returns (address receiver, uint256 royaltyAmount) {
        if (ownerOf(token) == owner()) { return (owner(), 0); }
        return (owner(), (price * _royalties) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    function mixinSender() private view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly { sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff) }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }

    function _msgSender() internal override view returns (address) {
        return mixinSender();
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_uriBase, Strings.toString(tokenId), ".json"));
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        if (operator == _proxy) { return true; }
        return super.isApprovedForAll(account, operator);
    }

}