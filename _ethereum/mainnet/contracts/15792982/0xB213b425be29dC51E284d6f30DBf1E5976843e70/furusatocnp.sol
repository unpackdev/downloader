pragma solidity ^0.8.13;

import "./Counters.sol";
import "./Context.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Base64.sol";

contract furusatocnp is ERC721, Ownable {
    using Strings for uint256;
    using Strings for string;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint256 thtime;
    mapping (uint256 => uint256) level;
    mapping (uint256 => string) token;
    mapping (uint256 => uint256)  transtime;
    address[] allowaddress;
    constructor(string memory name_, string memory symbol_) ERC721(name_,symbol_) {
        thtime = 365 * 3600 * 24;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns  (string memory)  {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return token[tokenId];
    }
    function createToken(string[] memory metas) public onlyOwner payable returns (string memory) {
        for(uint ins; ins<metas.length; ins++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            token[newItemId] = metas[ins];
            level[newItemId] = 0;
            _mint(owner(), newItemId);
        }
    }
    function isTime(uint256 _lastTransferredAt, uint256 _now) public view returns (bool) {
        return (_now - _lastTransferredAt) >= thtime;
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
        if (from == address(0) || from == owner()) {
            transtime[tokenId] = block.timestamp;
        } else {
            require(isTime(transtime[tokenId], block.timestamp),"ERC721Transfer: This NFT is currently locked");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function upgrade(uint256 tokenId,string memory meta) public onlyOwner returns (string memory) {
        require(level[tokenId] < 2, "ERC721Upgrade: This NFT has been max level");
        token[tokenId] = meta;
        level[tokenId] = level[tokenId] + 1;
        return "end";
    }
    function setApprovalForAll(address ope,bool approved) public virtual override {
        require(list(ope) == true, "ERC721Approve: This contract is not authorized");
        super.setApprovalForAll(ope, approved);
    }
    function approve(address to,uint256 tokenId) public virtual override {
        require(list(to) == true, "ERC721Approve: This contract is not authorized");
        super.approve(to, tokenId);
    }
    function list(address to) public view returns (bool) {
        for (uint ins;ins<allowaddress.length; ins++) {
            if (allowaddress[ins] == to) {
                return true;
            }
        }
        return false;
    }
    function _ViewList() public view returns (address[] memory) {
        return allowaddress;
    }
    function _SetList(address to) public onlyOwner returns (string memory) {
        allowaddress.push(to);
    }
    function _DelList(uint256 id) public onlyOwner returns (string memory) {
        delete allowaddress[id];
    }
    function _ViewLevel(uint256 tokenId) public view returns (uint256) {
        return level[tokenId];
    }
    function _ViewTime(uint256 tokenId) public view returns (uint256) {
        return block.timestamp - transtime[tokenId];
    }
}
