pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./ERC721Tradable.sol";
import "./LocalStrings.sol";

contract NotFasterThanLight is ERC721Tradable {
    using localStrings for string;
    using SafeMath for uint256;

    string public contractMeta;

    constructor(address _proxyRegistryAddress)
        ERC721Tradable("Not Faster Than Light", "NFTL", _proxyRegistryAddress)
    {
      setBaseURI("ipfs://");
    }

    function baseTokenURI() public pure override returns (string memory) {
        return "ipfs://";
    }

    function setContractURI(string memory _contractMeta) public onlyOwner{
        contractMeta = localStrings.strConcat(baseTokenURI(), _contractMeta);
    }

    function contractURI() public view returns (string memory) {
        return contractMeta;
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(tokenId, _tokenURI);
    }

    function recordToken(string memory ipfsIndex) public onlyOwner{
      uint256 nextId = totalSupply().add(1);
      mintTo(address(msg.sender));
      _setTokenURI(nextId, ipfsIndex);
    }
}
