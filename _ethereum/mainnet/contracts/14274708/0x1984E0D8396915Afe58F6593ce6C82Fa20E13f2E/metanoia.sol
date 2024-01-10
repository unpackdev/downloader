// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
// dev by 4mat

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

contract Metanoia is ERC721Enumerable, ReentrancyGuard, Ownable {
    uint256 public totalTokens = 333;
    uint256 public vaultLimit = 20;
    uint256 public vaultMinted = 0;
    uint256 public mintPrice = 0.14 ether;
    uint256 public perWallet = 1;
    string baseTokenURI;
    bool public tokenURIFrozen = false;
    //map addys that have minted
    mapping(address => bool) public alreadyMinted;
    mapping(address => bool) public alreadyMintedPresale;
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    mapping(address => bool) private presaleList;
    bool public contractPaused = false;

    address public teamAddressOne = 0x0AC02BBd689e54BF8DD5694e341Bb1A25ceB34d6;
    address public teamAddressTwo = 0xBc2E16F8058636334962D0C0E4e027238A09Ed82;
    address public teamAddressThree = 0x8430ea031C8EDb2c4951F4f7BF28B92527078bc5;
    address public teamAddressFour = 0x4bdeCc52e3bdd8d3b5403390c3F756d95f291101;

constructor(
    ) ERC721("Metanoia", "MTNOIA") {
    }

    function mintVault(uint256 _vaultMintQuantity, address _vaultMintAddress) 
        external 
        nonReentrant 
        onlyOwner {
        require(vaultMinted < vaultLimit, "Vault Minted"); 
        for (uint256 i = 0; i < _vaultMintQuantity; i++) {
            if (vaultMinted < vaultLimit) {
                _safeMint(_vaultMintAddress, nextTokenId());
                vaultMinted++;
            }  
        }
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
        uint256 oneSplit = address(this).balance / 10;
        uint256 fourSplit = oneSplit * 4;
        require(payable(teamAddressOne).send(fourSplit));
        require(payable(teamAddressTwo).send(fourSplit));
        require(payable(teamAddressThree).send(oneSplit));
        require(payable(teamAddressFour).send(address(this).balance));
    }

    function circuitBreaker() public onlyOwner { // onlyOwner can call
        if (contractPaused == false) { contractPaused = true; }
        else { contractPaused = false; }
    }
    // If the contract is paused, stop the modified function
    // Attach this modifier to all public functions
    modifier checkIfPaused() {
        require(contractPaused == false);
        _;
    }

    function mint() external payable nonReentrant {
        require(saleIsActive, "Sale not active");
        require(msg.value >= mintPrice, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(!alreadyMinted[msg.sender], "Address has already minted");
        require(balanceOf(msg.sender) < perWallet, "Per wallet limit exceeded");

        alreadyMinted[msg.sender] = true;
        _safeMint(msg.sender, nextTokenId());
    }

    function mintPresale() external payable nonReentrant {
        require(preSaleIsActive, "Presale not active");
        require(msg.value >= mintPrice, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(presaleList[msg.sender] == true, "Not on presale list");
        require(!alreadyMintedPresale[msg.sender], "Address has already minted");
        require(balanceOf(msg.sender) < perWallet, "Per wallet limit exceeded");
    
        alreadyMintedPresale[msg.sender] = true;
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

    function setVaultLimit(uint256 _newVaultLimit) public onlyOwner() {
        vaultLimit = _newVaultLimit;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function setPrice(uint256 _newPrice) public onlyOwner() {
        mintPrice = _newPrice;
    }

    function setPerWallet(uint256 _newPerWallet) public onlyOwner() {
        perWallet = _newPerWallet;
    }

    function checkBalance() public view returns (uint256){
        return address(this).balance;
    }
}