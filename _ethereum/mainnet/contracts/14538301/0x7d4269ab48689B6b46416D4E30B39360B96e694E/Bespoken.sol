// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Bespoken is ERC721A, Ownable, ReentrancyGuard  {
    using SafeMath for uint256;

    string public _baseTokenURI;
    uint256 public maxSupply  = 1112;
    
    // Minter Address
    address public constant MINTER_ADDRESS = 0x02C9315B0D4dBfA20dF1AaF3cAd6c1dc35a6D8f3;
    
    constructor() ERC721A("BESPOKEN", "BESPOKEN", maxSupply, maxSupply) {}

    function exists(uint256 tokenId) public view returns(bool) {
        return _exists(tokenId);
    }

    /**
    *   Public function for minting.
    */

     function mintNFT(uint256 quantity) public {
        require(msg.sender == MINTER_ADDRESS, "Mint is not allowed");

        maxSupply -= quantity;
        _safeMint(msg.sender, quantity);
    }

    /*
    *   NumberOfNFT setter
    */
    function setNumberOfTokens(uint256 _numberOfTokens) public onlyOwner {
        maxSupply = _numberOfTokens;
    }

    /*
    *   Withdraw Funds to beneficiary
    */

     function withdraw(address _recipient) public payable onlyOwner {
         (bool success,) = payable(_recipient).call{value: address(this).balance}("");
         require(success, "ERROR");
    }

   
    /*
    *   setBaseUri setter
    */

     function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    function tokensOf(address owner) public view returns (uint256[] memory){
        uint256 count = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](count);
        for (uint256 i; i < count; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }


    receive () external payable virtual {}
}