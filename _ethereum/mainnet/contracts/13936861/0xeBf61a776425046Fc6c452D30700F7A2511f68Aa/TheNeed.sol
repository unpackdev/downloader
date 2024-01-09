// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Strings.sol";
import "./Ownable.sol";

/**

 ______   __  __     ______     __   __     ______     ______     _____    
/\__  _\ /\ \_\ \   /\  ___\   /\ "-.\ \   /\  ___\   /\  ___\   /\  __-.  
\/_/\ \/ \ \  __ \  \ \  __\   \ \ \-.  \  \ \  __\   \ \  __\   \ \ \/\ \ 
   \ \_\  \ \_\ \_\  \ \_____\  \ \_\\"\_\  \ \_____\  \ \_____\  \ \____- 
    \/_/   \/_/\/_/   \/_____/   \/_/ \/_/   \/_____/   \/_____/   \/____/ 
The Need 2022.                                                                  
 */

contract TheNeed is ERC721, Ownable {

    address public constant ADDRESS_1 = 0xB61bec1C7dA88d905b8b749f1222ce5d889b98B8;
    address public constant ADDRESS_2 = 0x22AE23Bf8A61301e9Fc36A23a759D681BA315470;
    address public constant ADDRESS_3 = 0xA9441365eaF746560c6C7525b8E0CF2d238E37bf;
    address public constant ADDRESS_4 = 0x03313d6CD88874a9c4344b6da1F8f77A652a463B;
    address public constant ADDRESS_5 = 0xC5aa93fF62C372E1097B8c04A313a7d9C16dd301;
    address public constant ADDRESS_6 = 0xDeDfA9DE0BBCA5234a4fc4500f7070048188533d; 

    mapping(uint256 => bool) private burnedTokens;
    mapping (address => uint256) public presaleWhitelist;
    bool public presaleActive = false;
    bool public saleActive = false;
    bool public ownerActive = false;
    uint256 public currentSupply;
    uint256 public maxSupply;
    uint256 public price = 0.1 ether;
    uint256 public bC = 9999;


    string private baseURI = "";
    

 constructor() ERC721("TheNeed", "NEED") { 
    }
    
    function totalSupply() external view returns (uint) {
        return currentSupply;
    }

    function mintPresale(uint256 numberOfMints) public payable {
        uint256 supply = currentSupply;
        uint256 reserved = presaleWhitelist[msg.sender];
        require(presaleActive, "No presale active");
        require(reserved > 0, "This address is not authorized for presale");
        require(numberOfMints <= reserved, "Exceeded allowed amount");
        require(supply + numberOfMints <= maxSupply, "This would exceed the max number of allowed nft");
        require(numberOfMints * price <= msg.value, "Amount of ether is not enough");

        presaleWhitelist[msg.sender] = reserved - numberOfMints;
        currentSupply += numberOfMints;

        for(uint256 i; i < numberOfMints; i++){
            _mint(msg.sender, supply + i);
        }
    }

    function mint(uint256 numberOfMints) public payable {
        uint256 supply = currentSupply;
        require(saleActive, "Sale must be active to mint");
        require(numberOfMints <= 10, "Invalid purchase amount");
        require(supply + numberOfMints <= maxSupply, "Mint would exceed max supply of nft");
        require(numberOfMints * price <= msg.value, "Amount of ether is not enough");

        currentSupply += numberOfMints;

        for(uint256 i; i < numberOfMints; i++) {
            _mint(msg.sender, supply + i);
        }
    }

        function ownerMint(uint256 numberOfMints) public payable {
        uint256 supply = currentSupply;
        require(ownerActive, "Owner Sale must be active to mint");
        require(balanceOf(msg.sender) >= 3);
        require(numberOfMints <= 2, "Invalid purchase amount");
        require(supply + numberOfMints <= maxSupply, "Mint would exceed max supply of nft");
        require(numberOfMints * price <= msg.value, "Amount of ether is not enough");

        currentSupply += numberOfMints;

        for(uint256 i; i < numberOfMints; i++) {
            _mint(msg.sender, supply + i);
        }
    }

    function airdrop(address[] calldata addresses) external onlyOwner {
        uint256 supply = currentSupply;
        require(supply+ addresses.length <= maxSupply,  "This would exceed the max number of allowed nft");
        currentSupply += addresses.length;
        for (uint256 i; i < addresses.length ; i++) {
            _mint(addresses[i], supply + i);
        }
    }
    
    function editPresale(address[] calldata presaleAddresses, uint256[] calldata amount) external onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = amount[i];
        }
    }
    
    function editPresaleSingle(address[] calldata presaleAddresses, uint256 amount) external onlyOwner {
        for(uint256 i; i < presaleAddresses.length; i++){
            presaleWhitelist[presaleAddresses[i]] = amount;
        }
    }

    function togglePresale() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSale() external onlyOwner {
        saleActive = !saleActive;
    }
    function toggleOwner() external onlyOwner {
        ownerActive = !ownerActive;
    }
    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }
    function setSupply(uint256 supply) external onlyOwner {
        require(supply < 10000);
        maxSupply = supply;
    }

    
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Balance is 0");
        payable(ADDRESS_1).transfer(balance * 50 / 1000);
        payable(ADDRESS_2).transfer(balance * 150 / 1000);
        payable(ADDRESS_3).transfer(balance * 150 / 1000);
        payable(ADDRESS_4).transfer(balance * 75 / 1000);
        payable(ADDRESS_5).transfer(balance * 400 / 1000);
        payable(ADDRESS_6).transfer(balance * 175 / 1000);

    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory ) {
      uint256 tokenCount = balanceOf(_owner);
      if (tokenCount == 0) {
        return new uint256[](0);
      } else {
        uint256[] memory result = new uint256[](tokenCount);
        uint256 index = 0;
        for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
            if (index == tokenCount) break;

            if (ownerOf(tokenId) == _owner) {
                result[index] = tokenId;
                index++;
            }
        }

        return result;
      }
    }

    function walletOfOwner(address _owner) external view returns(uint256[] memory ) {
      return this.tokensOfOwner(_owner, 0, currentSupply);
    }
    function burn(
        address _owner,
        uint256 token1,
        uint256 token2,
        uint256 token3,
        uint256 token4

    ) external  {
        require(
            ownerOf(token1) == _owner &&
                ownerOf(token2) == _owner &&
                ownerOf(token3) == _owner &&
                ownerOf(token4) == _owner,
            "Invalid owner for given tokens."
        );

        _burn(token1);
        _burn(token2);
        _burn(token3);
        _burn(token4);

        burnedTokens[token1] = true;
        burnedTokens[token2] = true;
        burnedTokens[token3] = true;
        burnedTokens[token4] = true;
        _safeMint(_msgSender(), bC + 1);
        bC += 1;


    
    }



}