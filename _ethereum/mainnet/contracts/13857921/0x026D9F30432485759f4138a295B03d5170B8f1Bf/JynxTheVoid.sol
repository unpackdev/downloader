// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                          
import "./ERC721.sol";
import "./Ownable.sol";
import "./ECDSA.sol";

contract JynxTheVoid is ERC721, Ownable {
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5555;
    uint256 public constant PRESALE_ALLOC = 5535;
    uint256 public constant TEAM_ALLOC = 20;
    uint256 public constant PRICE = 0.066 ether;
    uint256 public constant PER_MINT = 10;
    uint256 public constant PER_PRESALE = 5;
    
    mapping(string => bool) private _usedNonces;
    string private _tokenBaseURI = "https://jynxthevoid.com/api/metadata/";
    address private _signerAddress = 0x11FB9d94C7A834acFe184Af69b18b9A64916FddE;

    mapping(address => uint256) public presalerPurchases;
    uint256 public publicCounter;
    uint256 public privateCounter;
    uint256 public giftCounter;
    bool public saleLive;
    bool public presaleLive;
    
    constructor() ERC721("JynxTheVoid", "JYNX") { }
    
    function verifyTransaction(address sender, uint256 amount, string calldata nonce, bytes calldata signature) private view returns(bool) {
        return _signerAddress == ECDSA.recover(keccak256(abi.encodePacked(sender, amount, nonce)), signature);
    }
    
    function gift(address[] calldata receivers) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + receivers.length <= MAX_SUPPLY, "MAX_MINT");
        require(giftCounter + receivers.length <= TEAM_ALLOC, "GIFTS_EMPTY");
        
        giftCounter += receivers.length;
        
        for (uint256 i = 1; i <= receivers.length; i++) {
            _safeMint(receivers[i - 1], supply + i);
        }
    }
    
    function purchase(uint256 amount, string calldata nonce, bytes calldata signature) external payable {
        require(saleLive && !presaleLive, "SALE_CLOSED");
        require(publicCounter + amount <= MAX_SUPPLY - privateCounter - TEAM_ALLOC, "OUT_OF_STOCK");
        require(verifyTransaction(msg.sender, amount, nonce, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(amount <= PER_MINT, "EXCEED_PER_MINT");
        require(PRICE * amount <= msg.value, "INSUFFICIENT_ETH");
        
        _usedNonces[nonce] = true;
        uint256 supply = totalSupply();
        publicCounter += amount;
        
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    
    function purchasePresale(uint256 amount, string calldata nonce, bytes calldata signature) external payable {
        require(!saleLive && presaleLive, "PRESALE_CLOSED");
        require(privateCounter + amount <= PRESALE_ALLOC, "EXCEED_PRIVATE");
        require(verifyTransaction(msg.sender, amount, nonce, signature), "DIRECT_MINT_DISALLOWED");
        require(!_usedNonces[nonce], "HASH_USED");
        require(presalerPurchases[msg.sender] + amount <= PER_PRESALE, "EXCEED_ALLOC");
        require(amount <= PER_MINT, "EXCEED_PER_MINT");
        require(PRICE * amount <= msg.value, "INSUFFICIENT_ETH");
        
        _usedNonces[nonce] = true;
        uint256 supply = totalSupply();
        privateCounter += amount;
        presalerPurchases[msg.sender] += amount;
        
        for (uint256 i = 1; i <= amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function totalSupply() public view returns (uint256) {
        return publicCounter + privateCounter + giftCounter;
    }

    function tokensOfOwner(address _owner, uint startId, uint endId) external view returns(uint256[] memory) {
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
    
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(0xc354c164bb52fB27074A5BcfDDEcefa2a5Aec19b).transfer(balance / 8);
        payable(0x43d54365476D23883630778D8E61Bb2Bb8976D63).transfer(balance / 8);
        payable(0x5d49a18C5f344EadD0A3757265B09b5593390bc4).transfer(balance / 100 * 8);
        payable(0x75Dfe5C62D469f0Ca719F1FCA922E926c66bbd54).transfer(balance / 5);
        payable(0xa511388e9A84a54cC8fE893b515a59c20Fa06bd5).transfer(balance / 5);
        payable(0x0979376CD57af355114f2DCE30Fd96e144343C7f).transfer(balance / 100 * 27);
    }
    
    function toggleSale() external onlyOwner {
        saleLive = !saleLive;
    }
    
    function togglePresale() external onlyOwner {
        presaleLive = !presaleLive;
    }
    
    function setSignerAddress(address addr) external onlyOwner {
        _signerAddress = addr;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }
}