// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

// WeMint Full Washington Edition ERC721 

// Calling mint mints a full size version of the corresponding Washington
// Mint costs 0.009 Ether

// WeMint.Cash 

contract WeMintFullWashington is ERC721, Ownable {
    ERC721 Washies;
    using Strings for uint256;
    mapping(uint256 => bool) public claimed;
    bool public enabled;
    uint256 public maxSupply;
    uint256 public totalSupply;
    uint256 public price;
    string internal baseURI;

    constructor()
    ERC721("WeMint Full Washington", "WEMINT FULL WASHINGTON")
    {
        enabled = true;
        maxSupply = 10000;
        totalSupply = 0;
        price = 0.009 ether;
        setWashie(0xA9cB55D05D3351dcD02dd5DC4614e764ce3E1D6e);
        baseURI = "ipfs://Qme7JvCAooDwQ4BcVhT45RFCwhYx5sGSnKA2wC4cvmCuYg/";
    }

    function mint(uint256[] memory tokenIds) public payable returns (uint256[] memory){
        require(enabled, "Contract not enabled");
        require(tx.origin == msg.sender, "CANNOT MINT THROUGH A CUSTOM CONTRACT");
        uint256[] memory newTokenIds = new uint[](tokenIds.length);
        if (msg.sender != owner()) {  
            require(msg.value >= tokenIds.length * price, "Invalid amount sent");
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(claimed[tokenIds[i]] == false, "Token already claimed");
            require(Washies.ownerOf(tokenIds[i]) == msg.sender, "You dont own that Washie");
            claimed[tokenIds[i]] = true;
            uint256 newTokenId = tokenIds[i];
            _safeMint(_msgSender(), newTokenId);
            newTokenIds[i] = newTokenId;
        }
        totalSupply += tokenIds.length;
        return newTokenIds;
    }

    function setWashie(address _washieAddress) public onlyOwner {
        Washies = ERC721(_washieAddress);
        return;
    }

    function enable(bool _enabled) public onlyOwner {
        enabled = _enabled;
    }

    function setBaseUri(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}
