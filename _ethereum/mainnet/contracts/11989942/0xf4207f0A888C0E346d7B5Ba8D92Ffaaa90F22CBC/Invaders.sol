pragma solidity ^0.7.3;

import "./Ownable.sol";
import "./ERC721Tradable.sol";
import "./LocalStrings.sol";

contract Invaders is ERC721Tradable {
    using localStrings for string;
    using SafeMath for uint256;

    address public _recipient;
    string public contractMeta;

    constructor(address _nour, address _proxyRegistryAddress)
        ERC721Tradable("Invaders", "INVDR", _proxyRegistryAddress)
    {
      _recipient = _nour;
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
      mintTo(_recipient);
      _setTokenURI(nextId, ipfsIndex);
    }
}
