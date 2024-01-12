// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
// BILT by 4mat at Low Note Labs
//    ___   ___   _      _____     _             _ _             _         
//   | _ ) |_ _| | |    |_   _|   | |__ _  _    | | | _ __  __ _| |_       
//   | _ \  | |  | |__    | |     | '_ \ || |   |_  _| '  \/ _` |  _|      
//   |___/ |___| |____|   |_|     |_.__/\_, |     |_||_|_|_\__,_|\__|      
//         _      _                  _  |__/  _          _         _       
//    __ _| |_   | |   _____ __ __  | \| |___| |_ ___   | |   __ _| |__ ___
//   / _` |  _|  | |__/ _ \ V  V /  | .` / _ \  _/ -_)  | |__/ _` | '_ (_-<
//   \__,_|\__|  |____\___/\_/\_/   |_|\_\___/\__\___|  |____\__,_|_.__/__/
//     
interface Callee {
    function ownerOf(uint256 tokenId) external returns(address);
    function burn(uint256 tokenId) external;
    function incrementPassCounter(uint256 tokenId) external;
    function checkHowManyUsesPass(uint256 tokenId) external returns(uint256);
}
contract BILT is ERC721, ERC721Enumerable, Pausable, ReentrancyGuard, Ownable, AccessControl {

    uint256 public constant maxSupply = 250000;
    uint256 public totalTokens = 10000;
    uint256 public mintPricePass = 0 ether;
    mapping(address => uint256) public mintPrice;
    uint256 public perPass = 3;
    uint256 public tokenCounter = 0;
    uint256 biltVersionCap = 1;
    
    string baseTokenURI;
    string contractMetaURI;

    //splits
    address public teamAddressOne = 0xf600Ee6512ce2Cb2092aed317c229381924642DE;
    address public teamAddressTwo = 0x810eF17738261fb757d30DDbC97932f46645d89E;
    address public teamAddressThree = 0x1B8F066732C788FbDB77CAC81E5681dDCCbc4D9b;
    address public teamAddressFour = 0xc7fbF51A81a06587d24843c63b95f40A529116bC;
    address public teamAddressFive = 0x031ae51E05D84498345Fe57A6C19089030412dA8;
    address public teamAddressSix = 0xD56f916ee2B4511063DE6DDcD88D683036fFBd1C;
    address public treasuryAddress = 0x22AEB106ae5267A71d95E31941998f0050B97dB6;
    
    mapping(address => bool) public passContractList;
    mapping(address => bool) public eligibleContractList;
    mapping(address => bool) public eligibleContractIsOpen;
    mapping(uint256 => uint256) public howManyUsesPass;
    mapping(address => bool) private presaleList;
    mapping (address => mapping (uint256 => mapping (uint256 => bool))) public alreadyBilt;

    //log BILT PFPs
    struct logBilt {
        address pfpContract;
        uint256 pfpTokenId;
        uint8 biltVersion;
    }
    event biltLogger(uint256 tokenId, address pfpContract, uint256 pfpTokenId, uint256 biltVersion);

    mapping (uint => logBilt) public biltLog;

    bool public tokenURIFrozen = false;
    bool public publicSaleIsActive = false;
    bool public preSaleIsActive = false;
    bool public passSaleIsActive = false;

    //roles
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC721("BILT", "BILT") {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(BURNER_ROLE, msg.sender);
    }

    function checkToken(address addr, uint256 tokenId) public returns(address) {
        Callee c = Callee(addr);
        return c.ownerOf(tokenId);
    }
    
    function burnToken(address addr, uint256 tokenId) internal whenNotPaused  {
        Callee c = Callee(addr);
        c.burn(tokenId);
    }

    function incrementPassCounterRemotely(address addr, uint256 tokenId) internal whenNotPaused  {
        Callee c = Callee(addr);
        c.incrementPassCounter(tokenId);
    }

    function checkHowManyUsesPassRemotely(address addr, uint256 tokenId) public returns(uint256) {
        Callee c = Callee(addr);
        return c.checkHowManyUsesPass(tokenId);
    }

    function nextTokenId() internal view returns (uint256) {
        return tokenCounter + 1;
    }

    function mintPreSale(address pfpContract, uint256 pfpTokenId, uint8 biltVersion) external payable whenNotPaused nonReentrant {
        require(preSaleIsActive, "Presale not active");
        require(msg.value >= mintPrice[pfpContract], "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(presaleList[msg.sender] == true, "Not on presale list");
        require(eligibleContractList[pfpContract] == true, "Must be an eligible contract");
        require(eligibleContractIsOpen[pfpContract] == true || ERC721(pfpContract).ownerOf(pfpTokenId) == msg.sender, "Must own the PFP token");
        require(biltVersion > 0 && biltVersion <= biltVersionCap, "Invalid version.");
        require(!alreadyBilt[pfpContract][pfpTokenId][biltVersion], "PFP TokenID has already been BILT");
        
        alreadyBilt[pfpContract][pfpTokenId][biltVersion] = true;
    
        _safeMint(msg.sender, nextTokenId());
        biltLog[nextTokenId()] = logBilt(pfpContract, pfpTokenId, biltVersion);
        emit biltLogger(nextTokenId(), pfpContract, pfpTokenId, biltVersion);
        tokenCounter++;
    }

    function mintPublicSale(address pfpContract, uint256 pfpTokenId, uint8 biltVersion) external payable whenNotPaused nonReentrant {
        require(publicSaleIsActive, "Public sale not active");
        require(msg.value >= mintPrice[pfpContract], "More eth required");
        require(totalSupply() < totalTokens, "Sold out");
        require(eligibleContractList[pfpContract] == true, "Must be an eligible contract");
        require(eligibleContractIsOpen[pfpContract] == true || ERC721(pfpContract).ownerOf(pfpTokenId) == msg.sender, "Must own the PFP token");
        require(biltVersion > 0 && biltVersion <= biltVersionCap, "Invalid version.");
        require(!alreadyBilt[pfpContract][pfpTokenId][biltVersion], "PFP TokenID has already been BILT");
        
        alreadyBilt[pfpContract][pfpTokenId][biltVersion] = true;
    
        _safeMint(msg.sender, nextTokenId());
        biltLog[nextTokenId()] = logBilt(pfpContract, pfpTokenId, biltVersion);
        emit biltLogger(nextTokenId(), pfpContract, pfpTokenId, biltVersion);
        tokenCounter++;
    }

    function mintPassSale(address passContract, uint16 passTokenId, address pfpContract, uint256 pfpTokenId, uint8 biltVersion) external payable whenNotPaused nonReentrant {
        require(passSaleIsActive, "Pass Sale not active");
        require(totalSupply() < totalTokens, "Sold out");
        require(passContractList[passContract] == true, "Must be an eligible pass");
        require(ERC721(passContract).ownerOf(passTokenId) == msg.sender, "Must own the Pass");
        require(checkHowManyUsesPassRemotely(passContract, passTokenId) < (perPass - 1), "Pass must be burned to mint again.");
        require(eligibleContractList[pfpContract] == true, "Must be an eligible contract");
        require(eligibleContractIsOpen[pfpContract] == true || ERC721(pfpContract).ownerOf(pfpTokenId) == msg.sender, "Must own the PFP token");
        require(biltVersion > 0 && biltVersion <= biltVersionCap, "Invalid version.");
        require(!alreadyBilt[pfpContract][pfpTokenId][biltVersion], "PFP TokenID has already been BILT");
        
        //howManyUsesPass[passTokenId]++;
        incrementPassCounterRemotely(passContract, passTokenId);
        alreadyBilt[pfpContract][pfpTokenId][biltVersion] = true;
    
        _safeMint(msg.sender, nextTokenId());
        biltLog[nextTokenId()] = logBilt(pfpContract, pfpTokenId, biltVersion);
        emit biltLogger(nextTokenId(), pfpContract, pfpTokenId, biltVersion);
        tokenCounter++;
    }

    function mintPassBurn(address passContract, uint16 passTokenId, address pfpContract, uint256 pfpTokenId, uint8 biltVersion) external payable whenNotPaused nonReentrant {
        require(passSaleIsActive, "Pass Sale not active");
        require(totalSupply() < totalTokens, "Sold out");
        require(passContractList[passContract] == true, "Must be an eligible pass");
        require(checkHowManyUsesPassRemotely(passContract, passTokenId) == (perPass - 1), "Pass can still be used before burning.");
        require(ERC721(passContract).ownerOf(passTokenId) == msg.sender, "Must own the Pass");
        require(eligibleContractList[pfpContract] == true, "Must be an eligible contract");
        require(eligibleContractIsOpen[pfpContract] == true || ERC721(pfpContract).ownerOf(pfpTokenId) == msg.sender, "Must own the PFP token");    
        require(biltVersion > 0 && biltVersion <= biltVersionCap, "Invalid version.");
        require(!alreadyBilt[pfpContract][pfpTokenId][biltVersion], "PFP TokenID has already been BILT");
        
        incrementPassCounterRemotely(passContract, passTokenId);
        burnToken(passContract, passTokenId);
        alreadyBilt[pfpContract][pfpTokenId][biltVersion] = true;
        
        _safeMint(msg.sender, nextTokenId());
        biltLog[nextTokenId()] = logBilt(pfpContract, pfpTokenId, biltVersion);
        emit biltLogger(nextTokenId(), pfpContract, pfpTokenId, biltVersion);
        tokenCounter++;
    }

    function mintAdmin(address mintToWallet, address pfpContract, uint16 pfpTokenId, uint8 biltVersion) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(totalSupply() < totalTokens, "Sold out");
        require(!alreadyBilt[pfpContract][pfpTokenId][biltVersion], "PFP TokenID has already been BILT");

        alreadyBilt[pfpContract][pfpTokenId][biltVersion] = true;

        _safeMint(mintToWallet, nextTokenId());
        biltLog[nextTokenId()] = logBilt(pfpContract, pfpTokenId, biltVersion);
        emit biltLogger(nextTokenId(), pfpContract, pfpTokenId, biltVersion);
        tokenCounter++;
    }

    function walletHoldsToken(address _wallet, address _contract) public view returns (uint256) {
        return IERC721(_contract).balanceOf(_wallet);
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

    function flipPassSaleState() public onlyRole(DEFAULT_ADMIN_ROLE) {
        passSaleIsActive = !passSaleIsActive;
    }
    
    function flipPublicSaleState() public onlyRole(DEFAULT_ADMIN_ROLE) {
        publicSaleIsActive = !publicSaleIsActive;
    }

    function flipPreSaleState() public onlyRole(DEFAULT_ADMIN_ROLE) {
        preSaleIsActive = !preSaleIsActive;
    }

    function setMintPrice(address pfpContract, uint256 priceInWei) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(pfpContract != address(0), "Can't mint to the null address");
        mintPrice[pfpContract] = priceInWei;
    }

    function flipAlreadyBilt(address pfpContract, uint256 pfpTokenId, uint256 biltVersion) external onlyRole(DEFAULT_ADMIN_ROLE) {
        alreadyBilt[pfpContract][pfpTokenId][biltVersion] = !alreadyBilt[pfpContract][pfpTokenId][biltVersion];
    }

    function setTeamAddressOne(address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        teamAddressOne = _newAddress;
    }

    function setTeamAddressTwo(address _newAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
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

    function addToPassContractList(address addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(addresses != address(0), "Can't mint to the null address");
        passContractList[addresses] = true;
    }

    function removeFromPassContractList(address addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(addresses != address(0), "Can't mint to the null address");
        passContractList[addresses] = false;
    }

    function addToEligibleContractList(address addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(addresses != address(0), "Can't mint to the null address");
        eligibleContractList[addresses] = true;
    }
    
    function removeFromEligibleContractList(address addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(addresses != address(0), "Can't mint to the null address");
        eligibleContractList[addresses] = false;
    }

    function flipEligibleContractIsOpen(address pfpContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        eligibleContractIsOpen[pfpContract] = !eligibleContractIsOpen[pfpContract];
    }
    
    function resetAlreadyBilt(address pfpContract, uint16 pfpTokenId, uint8 biltVersion) external onlyRole(DEFAULT_ADMIN_ROLE) {
        alreadyBilt[pfpContract][pfpTokenId][biltVersion] = false;
    }
    
    function addToAllowList(address[] calldata addresses) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't mint to the null address");
            presaleList[addresses[i]] = true;
        }
    }
    
    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function setTotalTokens(uint256 _newTotalTokens) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newTotalTokens < maxSupply, "TotalTokens cannot exceed Max Supply");
        totalTokens = _newTotalTokens; 
    }

     function setTokenCounter(uint256 _newTokenCounter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenCounter = _newTokenCounter; 
    }

    function burn(uint256 tokenId) public virtual onlyRole(BURNER_ROLE){
        _burn(tokenId);
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