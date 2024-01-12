// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ERC721Tradable.sol";

contract WarpedApeYachtClubLimitedEdition is ERC721Tradable {

    event PermanentURI(string _value, uint256 indexed _id);

    using Counters for Counters.Counter;

    string private _tokenURI;
    mapping(address => bool) public isMinter;
    mapping(uint256 => string) private _URI;

    modifier onlyMinter(){
        require(isMinter[_msgSender()], "Caller does not have permission to mint");
        _;
    }

    constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
        _tokenURI = "ipfs://";
        isMinter[_msgSender()] = true;
    }

    function mintTo(address) public override onlyMinter {
        require(canMint(), "No NFTs remain to be minted");
        require(false);
    }

    function updateMinter(address _address, bool _isMinter) external onlyOwner {
        isMinter[_address] = _isMinter;
    }

    function baseTokenURI() public virtual view override returns (string memory) {
        return _tokenURI;
    }

    function canMint() public virtual view returns (bool) {
        return isMinter[_msgSender()];
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), _URI[_tokenId]));
    }

    function generateLTD(address _to, string memory _uri) public onlyMinter {
        _generateLTD(_to, _uri, _nextTokenId.current());
        _nextTokenId.increment();
    }

    function _generateLTD(address _to, string memory _uri, uint256 _id) private {
        _URI[_id] = _uri;
        _safeMint(_to, _id);
    }

    function batchGenerateLTD(address[] memory _to, string[] memory _uri) external onlyMinter {
        uint256 batchIndex = _nextTokenId.current();
        for(uint256 i = 0; i < _to.length; i++) {
            _generateLTD(_to[i], _uri[i], batchIndex);
            batchIndex = batchIndex + 1;
        }

        _nextTokenId._value = batchIndex;
    }

    function ownerClaim() external onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    function freeStuckTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(this), "Cannot withdraw this token, only external tokens");
        IERC20(tokenAddress).transfer(_msgSender(), IERC20(tokenAddress).balanceOf(address(this)));
    }

}
