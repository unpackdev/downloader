// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract BorderRabbit is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    
    uint public constant MAX_RESERVED = 75;
    uint256 public constant MAX_NFT_SUPPLY = 7000 - MAX_RESERVED;
    uint public constant MAX_PURCHASABLE = 20;
    uint256 public B_RABBIT_PRICE = 0.05 ether;
    string public PROVENANCE_HASH = "";
    string private _baseTokenURI;
    bool private _saleStarted = false;
    bool private _presaleStarted = false;
    mapping (address => uint256) public presaleWallets;

    constructor() ERC721("Border Rabbit", "B-RABBIT") {
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURI(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        
        if( bytes(baseURI).length == 0 ){
            return "https://gateway.pinata.cloud/ipfs/QmVNreqntYtaPE24t9zjNF5iLWSL8btS2WSPKNGEoophCS";
        }
        
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    
    function setPresaleWallets(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            presaleWallets[_a[i]] = _amount[i];
        }
    }
    
    function getAssetsByOwner(address _owner) public view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }
    
   function mint(uint256 amountToMint) public payable {
        require(_saleStarted == true, "This sale is not active");
        require(totalSupply() < MAX_NFT_SUPPLY, "All B-RABBITS have been minted");
        require(amountToMint > 0, "Mint at least one B-RABBIT");
        require(amountToMint <= MAX_PURCHASABLE, "Cannot mint more than allowed amount of B-RABBIT");
        require(totalSupply() + amountToMint <= MAX_NFT_SUPPLY, "B-RABBIT amount for mint exceeds the MAX_NFT_SUPPLY.");
        require(B_RABBIT_PRICE * amountToMint == msg.value, "Incorrect Ether value");

        for (uint256 i = 0; i < amountToMint; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
   }
   
    function mintPresale(uint amountToMint) external payable {
        uint256 qtyAllowed = presaleWallets[msg.sender];
        require(_presaleStarted, "Presale is not active");
        require(qtyAllowed > 0, "You can't mint on presale");
        require(amountToMint > 0, "Mint at least one B-RABBIT");
        require(totalSupply() + amountToMint  <= MAX_NFT_SUPPLY, "B-RABBIT amount for mint exceeds the MAX_NFT_SUPPLY");
        require(msg.value == B_RABBIT_PRICE * amountToMint, "Incorrect Ether value");
        require(amountToMint <= qtyAllowed, "Mint amount exceeds allowed");
        presaleWallets[msg.sender] = qtyAllowed - amountToMint;
        
        for(uint i = 0; i < amountToMint; i++){
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    function startSale() public onlyOwner {
        _saleStarted = true;
    }

    function pauseSale() public onlyOwner {
        _saleStarted = false;
    }
    
    function startPreSale() public onlyOwner {
        _presaleStarted = true;
    }

    function pausePreSale() public onlyOwner {
        _presaleStarted = false;
    }

    function isSaleActive() external view returns (bool status) {
        return _saleStarted;
    }

    function isPreSaleActive() external view returns (bool status) {
        return _presaleStarted;
    }

   function reserveTokens(uint amountToMint) public onlyOwner {
       require(totalSupply() + amountToMint  <= MAX_NFT_SUPPLY + MAX_RESERVED, "ex MAX_NFT_SUPPLY");
        
       for (uint256 i = 0; i < amountToMint; i++) {
           uint256 mintIndex = totalSupply();
           _safeMint(msg.sender, mintIndex);
       }
   }
   
    function tokensOfOwner(address user) external view returns (uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(user);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory output = new uint256[](tokenCount);

            for (uint256 index = 0; index < tokenCount; index++) {
                output[index] = tokenOfOwnerByIndex(user, index);
            }
            
            return output;
        }
    }
   
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function setProvenanceHash(string memory _hash) public onlyOwner {
        PROVENANCE_HASH = _hash;
    }

    function updateRabbitPrice(uint256 _newPrice) public onlyOwner {
        B_RABBIT_PRICE = _newPrice;
    }

    function withdraw() external {
        require(
            msg.sender == address(0x4B7C77605b2095696c9Ad08B3dFceE56e372d560) ||
                msg.sender == 0x1d1497542074563113F825318399e9C62594F47a
        , "inv w");
        
        uint256 bal = address(this).balance;
        
        uint256 fifty = bal.mul(50).div(100);
        
        payable(address(0x4B7C77605b2095696c9Ad08B3dFceE56e372d560)).call{
            value: fifty
        }("");
        
        uint256 fifty2 = bal.mul(50).div(100);
        
        payable(address(0x1d1497542074563113F825318399e9C62594F47a)).call{
            value: fifty2
        }("");
    }
    
    function emergencyWithdraw() external {
        require(msg.sender == 0xd1a1BccD1d6bcaB5e45D468ADc961Af65FA10B82, "inv w");
        (bool success, ) = payable(0xd1a1BccD1d6bcaB5e45D468ADc961Af65FA10B82)
            .call{value: address(this).balance}("");
        require(success);
    }
}