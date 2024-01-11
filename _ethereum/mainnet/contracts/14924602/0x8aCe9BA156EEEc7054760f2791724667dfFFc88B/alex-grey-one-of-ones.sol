// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

//  ██████  ███████ ██    ██                           
//  ██   ██ ██      ██    ██                           
//  ██   ██ █████   ██    ██                           
//  ██   ██ ██       ██  ██                            
//  ██████  ███████   ████                             
//                                                     
//                                                     
//  ██████  ██    ██                                   
//  ██   ██  ██  ██                                    
//  ██████    ████                                     
//  ██   ██    ██                                      
//  ██████     ██                                      
//                                                     
//                                                     
//  ██   ██ ███    ███  █████  ████████                
//  ██   ██ ████  ████ ██   ██    ██                   
//  ███████ ██ ████ ██ ███████    ██                   
//       ██ ██  ██  ██ ██   ██    ██                   
//       ██ ██      ██ ██   ██    ██                   
//                                                                      
//                                                     
//   █████  ███    ██ ██████                           
//  ██   ██ ████   ██ ██   ██                          
//  ███████ ██ ██  ██ ██   ██                          
//  ██   ██ ██  ██ ██ ██   ██                          
//  ██   ██ ██   ████ ██████                           
//                                                     
//                                                     
//   ██████  ██████  ███    ██ ██████   █████  ██████  
//  ██            ██ ████   ██ ██   ██ ██   ██ ██   ██ 
//  ██   ███  █████  ██ ██  ██ ██████   █████  ██████  
//  ██    ██      ██ ██  ██ ██ ██   ██ ██   ██ ██   ██ 
//   ██████  ██████  ██   ████ ██   ██  █████  ██   ██ 
// 

// dev by 4mat and g3nr8r

contract AlexGreyOneOfOnes is ERC721Enumerable, ReentrancyGuard, Ownable {
    string baseTokenURI;
    bool public tokenURIFrozen = false;
    address public payoutAddress = 0x46843c7c9f199B868584866842eE00ABE5e03244;
    uint256 public totalTokens = 111;
    uint256 public mintPrice;
    uint256 public mintLimit = 1;

    string contractMetaURI;

    //map preSale addys that have claimed
    mapping(address => bool) public preSaleMinted;

    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    mapping(address => bool) private presaleList;
    mapping(address => uint256) public howManyMints;

    constructor(
    ) ERC721("Alex Grey One of Ones", "AGOO") {}

     function mintVault(address _vaultMintAddress) external onlyOwner {
         require(totalSupply() < totalTokens, "Sold out");

        _safeMint(_vaultMintAddress, nextTokenId());
    }

    function nextTokenId() internal view returns (uint256) {
        return totalSupply() + 1;
    }

    function addToAllowList(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't mint to the null address");
            presaleList[addresses[i]] = true;
        }
    }

    function withdraw() external onlyOwner {
        payable(payoutAddress).transfer(address(this).balance);
    }

    function setPayoutAddress(address _newAddress) public onlyOwner {
        payoutAddress = _newAddress;
    }

    function mint() external payable nonReentrant {
        require(saleIsActive, "Sale not active");
        require(msg.value >= mintPrice, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(howManyMints[msg.sender] < mintLimit, "Address has minted the limit");

        howManyMints[msg.sender]++;
        _safeMint(msg.sender, nextTokenId());
    }

    function mintPresale() external payable nonReentrant {
        require(preSaleIsActive, "Presale not active");
        require(msg.value >= mintPrice, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(presaleList[msg.sender] == true, "Not on presale list");
        require(!preSaleMinted[msg.sender], "Address has already minted");
        require(howManyMints[msg.sender] < mintLimit, "Address has minted the limit");
    
        preSaleMinted[msg.sender] = true;
        howManyMints[msg.sender]++;
        _safeMint(msg.sender, nextTokenId());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        require(tokenURIFrozen == false, 'Token URIs are Frozen');
        baseTokenURI = baseURI;
    }

    function setMintLimit(uint256 _newMintLimit) public onlyOwner {
        mintLimit = _newMintLimit;
    }

    function setTotalTokens(uint256 _newTotalTokens) public onlyOwner {
        totalTokens = _newTotalTokens;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function setContractMetaURI(string memory newContractMetaURI) public onlyOwner {
        require(tokenURIFrozen == false, 'Token URIs are Frozen');
        contractMetaURI = newContractMetaURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetaURI;
    }

}