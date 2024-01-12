// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

contract WarpedApeYachtClub is ERC721Tradable {

    event PermanentURI(string _value, uint256 indexed _id);

    using Counters for Counters.Counter;

    uint256 public maxSupply;
    string private _tokenURI;
    mapping(address => bool) public isMinter;

    modifier onlyMinter(){
        require(isMinter[_msgSender()], "Caller does not have permission to mint");
        _;
    }

    constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress, string memory _baseTokenURI, uint256 _maxSupply) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        _tokenURI = _baseTokenURI;
        maxSupply = _maxSupply;
        isMinter[_msgSender()] = true;
    }

    function mintTo(address _to) public override onlyMinter {
        require(canMint(), "No NFTs remain to be minted");
        uint256 currentTokenId = _nextTokenId.current();
        _nextTokenId.increment();
        _safeMint(_to, currentTokenId);
        emit PermanentURI(tokenURI(currentTokenId), currentTokenId);
    }

    function updateMinter(address _address, bool _isMinter) external onlyOwner {
        isMinter[_address] = _isMinter;
    }

    function baseTokenURI() public virtual view override returns (string memory) {
        return _tokenURI;
    }

    function canMint() public virtual view returns (bool) {
        return _nextTokenId.current() <= maxSupply;
    }
}
