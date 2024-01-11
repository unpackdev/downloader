// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
// dev by 4mat at Low Note Labs
//  ______   _____   _       _____    ______                     ______             
//  | ___ \ |_   _| | |     |_   _|   |  ___|                    | ___ \            
//  | |_/ /   | |   | |       | |     | |_ ___  _ __ __ _  ___   | |_/ /_ _ ___ ___ 
//  | ___ \   | |   | |       | |     |  _/ _ \| '__/ _` |/ _ \  |  __/ _` / __/ __|
//  | |_/ /  _| |_  | |____   | |     | || (_) | | | (_| |  __/  | | | (_| \__ \__ \
//  \____/   \___/  \_____/   \_/     \_| \___/|_|  \__, |\___|  \_|  \__,_|___/___/
//                                                   __/ |                          
//                                                  |___/                           
//       _               _                ___                 _                     
//      | |             | |              /   |               | |                    
//    __| | _____   __  | |__  _   _    / /| |_ __ ___   __ _| |_                   
//   / _` |/ _ \ \ / /  | '_ \| | | |  / /_| | '_ ` _ \ / _` | __|                  
//  | (_| |  __/\ V /   | |_) | |_| |  \___  | | | | | | (_| | |_                   
//   \__,_|\___| \_/    |_.__/ \__, |      |_/_| |_| |_|\__,_|\__|                  
//                              __/ |                                               
//                             |___/                                                
                                                               
contract BILTForgePass is ERC721, ERC721Enumerable, Pausable, ReentrancyGuard, Ownable, AccessControl {
    uint256 public constant maxSupply = 1111;
    uint256 public totalTokens = 1111;
    uint256 public vaultLimit = 44;
    uint256 public vaultMinted = 0;
    uint256 public mintPrice = 0.08 ether;
    uint256 public mintPricePreSale = 0.08 ether;
    uint256 public tokenCounter = 0;
    uint256 public mintLimit = 10;

    string baseTokenURI;
    bool public tokenURIFrozen = false;
    string contractMetaURI;

    address public teamAddressOne = 0xf600Ee6512ce2Cb2092aed317c229381924642DE;
    address public teamAddressTwo = 0x810eF17738261fb757d30DDbC97932f46645d89E;
    address public teamAddressThree = 0x1B8F066732C788FbDB77CAC81E5681dDCCbc4D9b;
    address public teamAddressFour = 0xc7fbF51A81a06587d24843c63b95f40A529116bC;
    address public teamAddressFive = 0x031ae51E05D84498345Fe57A6C19089030412dA8;
    address public teamAddressSix = 0xD56f916ee2B4511063DE6DDcD88D683036fFBd1C;
    address public treasuryAddress = 0x22AEB106ae5267A71d95E31941998f0050B97dB6;

    //map addys that have minted

    mapping(address => bool) public alreadyClaimedHonorary;
    mapping(address => bool) public alreadyMintedPublicSale;
    mapping(address => uint256) public howManyMints;
    mapping(uint256 => uint256) public howManyUsesPass;
    mapping(address => bool) private presaleList;
    mapping(address => bool) private claimHonoraryList;

    bool public saleIsActive = false;
    bool public claimHonoraryIsActive = false;
    bool public preSaleIsActive = false;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

constructor() ERC721("BILT Forge Pass", "BILTFP") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(BURNER_ROLE, msg.sender);
    }
    
    function nextTokenId() internal view returns (uint256) {
        return tokenCounter + 1;
    }

    function addToClaimHonoraryList(address[] calldata addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't mint to the null address");
            claimHonoraryList[addresses[i]] = true;
        }
    }

    function mint() external payable whenNotPaused nonReentrant {
        require(saleIsActive, "Sale not active");
        require(msg.value >= mintPrice, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(howManyMints[msg.sender] < mintLimit, "Address has minted the limit");
        
        howManyMints[msg.sender]++;
        _safeMint(msg.sender, nextTokenId());
        tokenCounter++;
    }

    function claimHonorary() external payable whenNotPaused nonReentrant {
        require(claimHonoraryIsActive, "Claim not active");
        require(totalSupply() < totalTokens, "Sold out");
        require(claimHonoraryList[msg.sender] == true, "Not on claim list");
        require(!alreadyClaimedHonorary[msg.sender], "Address has already claimed");
           
        alreadyClaimedHonorary[msg.sender] = true;
        _safeMint(msg.sender, nextTokenId());
        tokenCounter++;
    }

    function mintPreSale() external payable whenNotPaused nonReentrant {
        require(preSaleIsActive, "Presale not active");
        require(msg.value >= mintPricePreSale, "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(presaleList[msg.sender] == true, "Not on presale list");
        require(howManyMints[msg.sender] < mintLimit, "Address has minted the limit");
        
        howManyMints[msg.sender]++;
        _safeMint(msg.sender, nextTokenId());
        tokenCounter++;
    }

    function mintVault(uint256 _vaultMintQuantity, address _vaultMintAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(vaultMinted < vaultLimit, "Vault Minted"); 
        for (uint256 i = 0; i < _vaultMintQuantity; i++) {
            if (vaultMinted < vaultLimit) {
                _safeMint(_vaultMintAddress, nextTokenId());
                tokenCounter++;
                vaultMinted++;
            }  
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function freezeBaseURI() public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenURIFrozen = true;
    }

    function setBaseURI(string memory baseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenURIFrozen == false, 'Token URIs are Frozen');
        baseTokenURI = baseURI;
    }

    
    function setContractMetaURI(string memory newContractMetaURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokenURIFrozen == false, 'Token URIs are Frozen');
        contractMetaURI = newContractMetaURI;
    }

    function contractURI() public view returns (string memory) {
        return contractMetaURI;
    }

    function flipSaleState() public onlyRole(DEFAULT_ADMIN_ROLE) {
        saleIsActive = !saleIsActive;
    }

    function flipClaimHonoraryState() public onlyRole(DEFAULT_ADMIN_ROLE) {
        claimHonoraryIsActive = !claimHonoraryIsActive;
    }

    function flipPreSaleState() public onlyRole(DEFAULT_ADMIN_ROLE) {
        preSaleIsActive = !preSaleIsActive;
    }
    
    function addToAllowList(address[] calldata addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't mint to the null address");
            presaleList[addresses[i]] = true;
        }
    }

    function setPrice(uint256 _newPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPrice = _newPrice;
    }

    function setPricePreSale(uint256 _newPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPricePreSale = _newPrice;
    }

    function setMintlimit(uint256 _newMintlimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintLimit = _newMintlimit;
    }

    function setTeamAddressOne(address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        teamAddressOne = _newAddress;
    }

    function setTeamAddresstwo(address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        teamAddressTwo = _newAddress;
    }

    function setTeamAddressThree(address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        teamAddressThree = _newAddress;
    }

    function setTeamAddressFour(address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        teamAddressFour = _newAddress;
    }

    function setTeamAddressFive(address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        teamAddressFive = _newAddress;
    }

    function setTeamAddressSix(address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        teamAddressSix = _newAddress;
    }

    function setTreasuryAddress(address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        treasuryAddress = _newAddress;
    }

    function checkBalance() public view returns (uint256){
        return address(this).balance;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 oneSplit = address(this).balance / 100;
        uint256 twentySplit = oneSplit * 20;
        uint256 tenSplit = oneSplit * 10;
        uint256 fiveSplit = oneSplit * 5;
        require(payable(teamAddressOne).send(twentySplit));
        require(payable(teamAddressTwo).send(twentySplit));
        require(payable(teamAddressThree).send(tenSplit));
        require(payable(teamAddressFour).send(tenSplit));
        require(payable(teamAddressFive).send(tenSplit));
        require(payable(teamAddressSix).send(fiveSplit));
        require(payable(treasuryAddress).send(address(this).balance));
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setTotalTokens(uint256 _newTotalTokens) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newTotalTokens <= maxSupply, "TotalTokens cannot exceed Max Supply");
        
        totalTokens = _newTotalTokens; 
    }

    function setTokenCounter(uint256 _newTokenCounter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenCounter = _newTokenCounter; 
    }

    function burn(uint256 tokenId) public virtual onlyRole(BURNER_ROLE){
        _burn(tokenId);
    }

    function incrementPassCounter(uint256 tokenId) public virtual onlyRole(BURNER_ROLE){
        howManyUsesPass[tokenId]++;
    }

    function checkHowManyUsesPass(uint256 tokenId) public view returns (uint256){
        return howManyUsesPass[tokenId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
        {
            return super.supportsInterface(interfaceId);
        }

}