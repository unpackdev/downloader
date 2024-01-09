// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC2981.sol";
import "./ERC721.sol";
import "./Counters.sol";

//=========================================================================================================
//=========================================================================================================
//   .d8888b.                         888      .d8888b.                    888      d8b
//  d88P  Y88b                        888     d88P  Y88b                   888      Y8P
//  888    888                        888     Y88b.                        888
//  888         .d88b.   .d88b.   .d88888      "Y888b.   888  888 .d8888b  88888b.  888
//  888  88888 d88""88b d88""88b d88" 888         "Y88b. 888  888 88K      888 "88b 888
//  888    888 888  888 888  888 888  888           "888 888  888 "Y8888b. 888  888 888
//  Y88b  d88P Y88..88P Y88..88P Y88b 888     Y88b  d88P Y88b 888      X88 888  888 888
//   "Y8888P88  "Y88P"   "Y88P"   "Y88888      "Y8888P"   "Y88888  88888P' 888  888 888
//
//           .d8888b.           888    d8b           .d888                   888    d8b
//          d88P  Y88b          888    Y8P          d88P"                    888    Y8P
//          Y88b.               888                 888                      888
//           "Y888b.    8888b.  888888 888 .d8888b  888888  8888b.   .d8888b 888888 888  .d88b.  88888b.
//              "Y88b.     "88b 888    888 88K      888        "88b d88P"    888    888 d88""88b 888 "88b
//                "888 .d888888 888    888 "Y8888b. 888    .d888888 888      888    888 888  888 888  888
//          Y88b  d88P 888  888 Y88b.  888      X88 888    888  888 Y88b.    Y88b.  888 Y88..88P 888  888
//           "Y8888P"  "Y888888  "Y888 888  88888P' 888    "Y888888  "Y8888P  "Y888 888  "Y88P"  888  888
//=========================================================================================================
//=========================================================================================================

contract GoodSushiSatisfaction is ERC721, IERC2981, Ownable
{
    //==============================
    // Variables
    //==============================
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    string private _tokenBaseUri;
    address private _royaltyAddress;
    uint256 private _royaltyPercent;
    bool private _enableBurn;

    //==============================
    // Functions
    //==============================
    constructor(string memory baseUri) ERC721("GoodSushiSatisfaction", "GSS")
    {
        _tokenBaseUri = baseUri;
        _royaltyAddress = owner();
        _royaltyPercent = 5;
        _enableBurn = false;
    }

    function mint(uint256 num, address recipient) public onlyOwner
    {
        for(uint256 i = 0; i < num; ++i) {
            _tokenIds.increment();
            _safeMint(recipient, _tokenIds.current());
        }
    }

    function burn(uint256 tokenId) public
    {
        require(_enableBurn, "Burning is disabled.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Sender is not owner or not approved.");
        _burn(tokenId);
    }

    function withdraw() public onlyOwner
    {
        uint256 balance = address(this).balance;
        (bool success, ) = owner().call{value: balance}("");
        require(success, "Withdraw failed.");
    }
    
    function setTokenBaseUri(string memory tokenBaseUri) public onlyOwner
    {
        _tokenBaseUri = tokenBaseUri;
    }

    function setRoyaltyAddress(address royaltyAddress) public onlyOwner
    {
        _royaltyAddress = royaltyAddress;
    }

    function setRoyaltyPercent(uint256 royaltyPercent) public onlyOwner
    {
        _royaltyPercent = royaltyPercent;
    }

    function setEnableBurn(bool enableBurn) public onlyOwner
    {
        _enableBurn = enableBurn;
    }

    //==============================
    // Override functions
    //==============================
    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view override returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "Token does not exist.");
        return (_royaltyAddress, salePrice * _royaltyPercent / 100);
    }

    function _baseURI() internal view override returns (string memory) {
        return _tokenBaseUri;
    }
}