pragma solidity 0.8.4;

import "./ERC721.sol";
import "./Ownable.sol";


contract UBIK is ERC721("UBIK certificate", "UBIK"), Ownable {
    uint256 public totalSupply;
    string private _uri = "ipfs://QmPTKbPSwMuBtV9nSRmsMHjUuaNZ95oUsQSk2pgoS4Kq9R";
    
    constructor(address[] memory _initialOwners) {
        mintMultiple(_initialOwners);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return _uri;
    }
    
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
        totalSupply++;
    }
    
    function setTokenUri(string calldata _tokenURI) external onlyOwner {
        _uri = _tokenURI;
    }
    
    function mintMultiple(address[] memory _owners) public onlyOwner {
        uint256 addrcount = _owners.length;
        for (uint256 i = 0; i < addrcount; i++) {
            _mint(_owners[i], totalSupply + i + 1);
        }
        totalSupply = totalSupply + addrcount;
    }
}