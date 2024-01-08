// SPDX-License-Identifier: No-License
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract NFT is ERC721, Ownable {
    using SafeMath for uint256;


    constructor() ERC721("Stobox Ox NFT Demo", "STONFTD") public {
    }

   

    function transferFrom(address _from, address _to, uint256 _tokenId) public override 
    {
        ERC721.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override 
    {
        ERC721.safeTransferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override 
    {
        ERC721.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function mint(address _to, uint256 _tokenId, string memory _tokenURI) external onlyOwner {
        require(ERC721.totalSupply() <= 10000, "TooMuchSupply");
        ERC721._mint(_to, _tokenId);
        ERC721._setTokenURI(_tokenId, _tokenURI);
    }
}