// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721Enum.sol";

contract BasicBatsVIP is ERC721Enum, Ownable {

    using Strings for uint256;
    
    string baseTokenUri;
    bool baseUriDefined = false;
    
    constructor(string memory baseURI) ERC721P("Basic Bats VIP", "BBTSVIP")  {
        setBaseURI(baseURI);

        address[16] memory honoraryAddrs = [0xeD98464BDA3cE53a95B50f897556bEDE4316361c, 0xaa9Bff236cF51518dA774714D50ad07Db5149479, 0x6e7592ff3C32c93A520A11020379d66Ab844Bf5B,
            0x8299B6f77B11af3040650cc77FD8a055Ed6dD879, 0x11360F0c5552443b33720a44408aba01a809905e, 0xfDeD90A3B1348425577688866f798f94d77A0D02,
            0xd863c0f47bDeB7f113EA85b3cb3D95c667f17Ab4, 0xaFf42573Bc515b878513e945E246d0F1B8Ff01Cc, 0x412F065CEdd5814a2De17CE41C5895886974737b,
            0x22871d53dDa2aEBDaD96272197E7cC52F81e92FD, 0xeB1c22baACAFac7836f20f684C946228401FF01C, 0x0F2F9D729E00DD4653e1045006e1eF644AF42BaF,
            0xed2ab4948bA6A909a7751DEc4F34f303eB8c7236, 0xD9895aE4A28f9edc5726034aB59E102d11C0E288, 0xA442dDf27063320789B59A8fdcA5b849Cd2CDeAC,
            0xC00aE171ACD39F84e66e19c7bAD7BB676C1Fe10c];

        for (uint i = 0; i < honoraryAddrs.length; i++) {
            _safeMint(honoraryAddrs[i], i);
        }
    }
    
    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenUri;
    }

    /*
    *   The setBaseURI function with a possibility to freeze it !
    */
    function setBaseURI(string memory baseURI) public onlyOwner() {
        require(!baseUriDefined, "Base URI has already been set");
        
        baseTokenUri = baseURI;
        
    }
    
    function lockMetadatas() public onlyOwner() {
        baseUriDefined = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

}