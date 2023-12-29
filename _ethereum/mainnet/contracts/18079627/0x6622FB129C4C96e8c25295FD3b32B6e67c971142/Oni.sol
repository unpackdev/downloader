// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IOni.sol";

contract Oni is ERC721, Ownable, IOni {
    using Strings for uint256;
    
    mapping(uint256 => uint256) _parent;
    mapping(address => bool) _canMint;
    mapping(uint256 => uint256) public allTokenId;

    uint256 public totalSupply;

    mapping(uint256 => uint256) _status;
    mapping(address => bool) _canEditStatus;

    // do not store original nft info here
    // backend shoud listen to Bite event and create metadata with 
    // original nft info.
    // mapping(uint256 => uint256) _originalTokenId;
    // mapping(uint256 => address) _originalAddress;

    event Bite(address owner, uint256 tokenId, uint256 parentTokenId, address originalAddress, uint256 originalTokenId);
    
    string __baseURI;

    constructor(string memory uri, string memory name, string memory symbol) ERC721(name, symbol) {
        setMintStatus(msg.sender, true);
        __baseURI = uri;
    }

    function setAdminForStatus(address target, bool value) public onlyOwner {
        _canEditStatus[target] = value;
    }

    function getStatus(uint256 tokenId) public view returns (uint256){
        return _status[tokenId];
    }

    function setStatus(uint256 tokenId, uint256 status) public {
        require(_canEditStatus[msg.sender], "You're not allowed to edit status.");
        _status[tokenId] = status;
    }

    function unsecureRandomNumber() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp
        )));
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return __baseURI;
    }

    function changeURI(string memory newURI) public onlyOwner {
        __baseURI = newURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function setMintStatus(address user, bool status) public onlyOwner {
        _canMint[user] = status;
    }

    function canMint(address user) internal view returns (bool) {
        return _canMint[user];
    }

    function mintPlaceholder(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }

    function mint(address to, uint256 parent, address originalAddress, uint256 originalTokenId) public returns (uint256){
        require(canMint(msg.sender), "You are not allowed to mint.");

        uint256 tokenId = unsecureRandomNumber();

        _mint(to, tokenId);
        setParent(tokenId, parent);
        // _originalAddress[tokenId] = originalAddress;
        // _originalTokenId[tokenId] = originalTokenId;

        allTokenId[totalSupply] = tokenId;
        totalSupply += 1;

        emit Bite(to, tokenId, parent, originalAddress, originalTokenId);

        return tokenId;
    }

    // function getOriginalInfo(uint256 tokenId) public view returns (address, uint256){
    //     return (_originalAddress[tokenId], _originalTokenId[tokenId]);
    // }

    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    function setParent(uint256 chindren, uint256 parent) internal {
        _parent[chindren] = parent;
    }

    function getParent(uint256 tokenId) public virtual view returns (uint256) {
        return _parent[tokenId];
    }

    function getDepth(uint256 tokenId) public view returns (uint256) {
        uint256 depth = 0;
        uint256 parent = getParent(tokenId);
        while (parent != 0) {
            depth += 1;
            parent = getParent(parent);
        }
        return depth;
    }

    function getMaxTokenId() public view returns (uint256) {
        return totalSupply;
    }

    // only for query
    // do not use this in your contract or you'll get a large amount of gas fee
    function getParentBatch(uint256 start, uint256 end) public override view returns (uint256[] memory) {
        if (end == 0 || end > totalSupply) {end = totalSupply;}

        uint256 arrayLength = end - start;
        uint256[] memory parent = new uint256[](arrayLength);

        for (uint256 i=start; i<end; i++) {
            parent[i-start] = _parent[allTokenId[i]];
        }
        return parent;
    }

    function getOwnerBatch(uint256 start, uint256 end) public view returns (address[] memory) {
        if (end == 0 || end > totalSupply) {end = totalSupply;}

        uint256 arrayLength = end - start;
        address[] memory owner = new address[](arrayLength);

        for (uint256 i=start; i<end; i++) {
            owner[i-start] = ownerOf(allTokenId[i]);
        }
        return owner;
    }

    function getTokenIdBatch(uint256 start, uint256 end) public view returns (uint256[] memory) {
        if (end == 0 || end > totalSupply) {end = totalSupply;}

        uint256 arrayLength = end - start;
        uint256[] memory owner = new uint256[](arrayLength);

        for (uint256 i=start; i<end; i++) {
            owner[i-start] = allTokenId[i];
        }
        return owner;
    }

    function getTokenId(uint256 num) public view returns (uint256 tokenId) {
        return allTokenId[num];
    }
}