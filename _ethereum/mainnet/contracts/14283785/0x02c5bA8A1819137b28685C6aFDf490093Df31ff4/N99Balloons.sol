/*
999 Balloons NFT (https://999balloons.io)
Twitter @999BalloonsNFT

All proceeds directly benefit Ukraine

Direct donation address:
0x165CD37b4C644C2921454429E7F9358d18A45e14

Launched by
Fueled on Bacon (https://fueledonbacon.com)
Twitter @fueledonbacon
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721.sol";

contract N99Balloons is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint;
    enum SaleStatus{ PAUSED, PUBLIC }

    Counters.Counter private _tokenIds;

    uint public constant MINT_PRICE = 0.01 ether;
    SaleStatus public saleStatus = SaleStatus.PAUSED;

    string private _baseUri;
  
    mapping(address => uint) private _mintedCount;

    constructor(string memory baseUri)
      ERC721("999Balloons", "999B")
    {
        _baseUri = baseUri;
    }

    function totalSupply() external view returns (uint) {
        return _tokenIds.current();
    }
    /// @dev override base uri
    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    /// @notice Set sales status
    function setSaleStatus(SaleStatus status) onlyOwner external {
        saleStatus = status;
    }

    /// @notice change metadata for all the tokens
    function setBaseUri(string memory baseUri) onlyOwner external {
        _baseUri = baseUri;
    }

    /// @notice Get token's URI. In case of delayed reveal we give user the json of the placeholer metadata.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        tokenId;
        return _baseUri;
    }

    /// @notice Withdraw's contract's balance to Ukraine
    /*
        This address was sent out by the verified @Ukraine account on Twitter
        and confirmed by multiple other sources to be an ETH address which is
        controlled by Ukraine's government directly, so funds will be used to
        support efforts there.

        We believe this information to be accurate, DYOR.

        Original post:
        https://twitter.com/Ukraine/status/1497594592438497282

        Anyone can call this function to pay the gas to trigger the withdrawal

        */
    function withdraw() external {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance");
        
        payable(0x165CD37b4C644C2921454429E7F9358d18A45e14).transfer(balance);
    }

    /// @dev only requirement is to send more than .01 ether to get a token.
    function mint() external payable {
        require(saleStatus != SaleStatus.PAUSED, "Sales are off");
        require(msg.value >= MINT_PRICE, "Ether value sent is not sufficient");

        _mintedCount[msg.sender] += 1;
        _tokenIds.increment();
        uint newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
    }
}
