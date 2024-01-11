// SPDX-License-Identifier: MIT

/*
      Astral Pioneers NFTs
        ╔═╗╔═╗╔╦╗╦═╗╔═╗╦     
        ╠═╣╚═╗ ║ ╠╦╝╠═╣║      
        ╩ ╩╚═╝ ╩ ╩╚═╩ ╩╩═╝    
      ╔═╗╦╔═╗╔╗╔╔═╗╔═╗╦═╗╔═╗
      ╠═╝║║ ║║║║║╣ ║╣ ╠╦╝╚═╗
      ╩  ╩╚═╝╝╚╝╚═╝╚═╝╩╚═╚═╝
  10,000 amazing generative NFTs
      Alien encounter stories
      Astral projection chat
   To the metaverse and BEYOND!
        Dropping June 2022
        AstralPioneers.com

*/

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

contract AstralPioneers is Ownable, ERC721A, PaymentSplitter {

    uint public MAXSUPPLY = 10000;  // Hard-coded in setMaxSupply() also.
    uint public THEMINTPRICE = 0.0888 ether;
    uint public WALLETLIMIT = 12;
    string public PROVENANCE_HASH;
    string private METADATAURI;
    string private CONTRACTURI;
    bool public SALEISLIVE = false;
    bool private MINTLOCK;
    bool private PROVENANCE_LOCK = false;
    uint public RESERVEDNFTS;
    uint id = totalSupply();
    uint public RANDOMOFFSET;

    struct Account {
        uint nftsReserved;
        uint mintedNFTs;
        uint isAdmin;
    }

    mapping(address => Account) public accounts;

    event Mint(address indexed sender, uint totalSupply);
    event PermanentURI(string _value, uint256 indexed _id);
    event Burn(address indexed sender, uint indexed _id);

    address[] private _distro;
    uint[] private _distro_shares;

    constructor(address[] memory distro, uint[] memory distro_shares, address[] memory teamclaim)
        ERC721A("Astral-Pioneers", "AP")
        PaymentSplitter(distro, distro_shares)
    {
        // AP will launch using an instant reveal API and, upon sellout,
        // will move the metadata to its permanent IPFS home.
        METADATAURI = "ipfs://QmVPLq3wPzs1K429DLJy8iJuSdRWoVDiTb4TA8JFi7fNGb/";

        accounts[msg.sender] = Account( 0, 0, 0 );

        // Set Project / Team NFTs & Initial Admin Levels:
        accounts[teamclaim[0]] = Account( 50, 0, 1); 
        accounts[teamclaim[1]] = Account( 50, 0, 1); 
        accounts[teamclaim[2]] = Account( 25, 0, 1); 
        accounts[teamclaim[3]] = Account( 25, 0, 1); 
        accounts[teamclaim[4]] = Account( 25, 0, 1); 
        accounts[teamclaim[5]] = Account( 25, 0, 1); 

        RESERVEDNFTS = 200;

        _distro = distro;
        _distro_shares = distro_shares;

    }

    // ~(<>..<>)~ Modifiers ~(<>..<>)~

    modifier minAdmin1() {
        require(accounts[msg.sender].isAdmin > 0 , "Error: Level 1(+) admin clearance required.");
        _;
    }

    modifier minAdmin2() {
        require(accounts[msg.sender].isAdmin > 1, "Error: Level 2(+) admin clearance required.");
        _;
    }

    modifier noReentrant() {
        require(!MINTLOCK, "Error: No re-entrancy.");
        MINTLOCK = true;
        _;
        MINTLOCK = false;
    } 

    // ~(<>..<>)~ Overrides ~(<>..<>)~ 

    // Start token IDs at 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }    

    // ~(<>..<>)~ Setters ~(<>..<>)~

    function adminLevelRaise(address _addr) external onlyOwner { 
        accounts[_addr].isAdmin ++; 
    }

    function adminLevelLower(address _addr) external onlyOwner { 
        accounts[_addr].isAdmin --; 
    }

    function provenanceLock() external onlyOwner {
        PROVENANCE_LOCK = true;
    }
    
    function provenanceSet(string memory _provenanceHash) external onlyOwner {
        require(PROVENANCE_LOCK == false);
        PROVENANCE_HASH = _provenanceHash;
    }  

    function reservesDecrease(uint _decreaseReservedBy, address _addr) external onlyOwner {
        require(RESERVEDNFTS - _decreaseReservedBy >= 0, "Error: This would make reserved less than 0.");
        require(accounts[_addr].nftsReserved - _decreaseReservedBy >= 0, "Error: User does not have this many reserved NFTs.");
        RESERVEDNFTS -= _decreaseReservedBy;
        accounts[_addr].nftsReserved -= _decreaseReservedBy;
    }

    function reservesIncrease(uint _increaseReservedBy, address _addr) external onlyOwner {
        require(RESERVEDNFTS + totalSupply() + _increaseReservedBy <= MAXSUPPLY, "Error: This would exceed the max supply.");
        RESERVEDNFTS += _increaseReservedBy;
        accounts[_addr].nftsReserved += _increaseReservedBy;
        if ( accounts[_addr].isAdmin == 0 ) { accounts[_addr].isAdmin ++; }
    }

    function salePublicActivate() external minAdmin2 {
        SALEISLIVE = true;
    }

    function salePublicDeactivate() external minAdmin2 {
        SALEISLIVE = false;
    } 

    function setBaseURI(string memory _newURI) external minAdmin2 {
        METADATAURI = _newURI;
    }

    function setContractURI(string memory _newURI) external onlyOwner {
        CONTRACTURI = _newURI;
    }

    function setMaxSupply(uint _maxSupply) external onlyOwner {
        require(_maxSupply <= 10000, 'Error: New max supply cannot exceed original max.');        
        MAXSUPPLY = _maxSupply;
    }

    function setMintPrice(uint _newPrice) external onlyOwner {
        THEMINTPRICE = _newPrice;
    }

    function setRandomValue(address account, uint lowValue, uint highValue) external onlyOwner returns (uint) {
    	require(RANDOMOFFSET==0, "Error: Random offset has already been set.");
    	require(highValue > lowValue, "Error: Low value has to be lower than High value.");
    	uint mod_operator = highValue + 1 - lowValue;
        uint random_id = lowValue + uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.gaslimit, account)))% mod_operator;
        RANDOMOFFSET = random_id;
        return random_id;
    }    

    function setWalletLimit(uint _newLimit) external onlyOwner {
        WALLETLIMIT = _newLimit;
    }
    
    // ~(<>..<>)~ Getters ~(<>..<>)~

    // -- For OpenSea
    function contractURI() public view returns (string memory) {
        return CONTRACTURI;
    }

    // -- For Metadata
    function _baseURI() internal view virtual override returns (string memory) {
        return METADATAURI;
    }

    // -- For Convenience
    function getMintPrice() public view returns (uint){ 
        return THEMINTPRICE; 
    }

    // -- For the Optional Start Index / Offset
    function getRandomValue() public view returns (uint){
        return RANDOMOFFSET;
    }    

    // ~(<>..<>)~ Functions ~(<>..<>)~

    function airDropNFT(address[] memory _addr) external minAdmin2 {

        require(totalSupply() + _addr.length <= (MAXSUPPLY - RESERVEDNFTS), "Error: You would exceed the airdrop limit.");

        for (uint i = 0; i < _addr.length; i++) {
             _safeMint(_addr[i], 1);
             emit Mint(msg.sender, totalSupply());
        }

    }

    function claimReserved(uint _amount) external minAdmin1 {

        require(_amount > 0, "Error: Need to have reserved supply.");
        require(accounts[msg.sender].nftsReserved >= _amount, "Error: You are trying to claim more NFTs than you have reserved.");
        require(totalSupply() + _amount <= MAXSUPPLY, "Error: You would exceed the max supply limit.");

        accounts[msg.sender].nftsReserved -= _amount;
        RESERVEDNFTS -= _amount;

        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());
        
    }

    function mint(uint _amount) external payable noReentrant {

        require(SALEISLIVE, "Error: Sale is not active.");
        require(totalSupply() + _amount <= (MAXSUPPLY - RESERVEDNFTS), "Error: Purchase would exceed max supply.");
        require((_amount + accounts[msg.sender].mintedNFTs) <= WALLETLIMIT, "Error: You would exceed the wallet limit.");
        require(!isContract(msg.sender), "Error: Contracts cannot mint.");
        require(msg.value >= (THEMINTPRICE * _amount), "Error: Not enough ether sent.");

	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());

    }

    function burn(uint _id) external returns (bool, uint) {

        require(msg.sender == ownerOf(_id) || msg.sender == getApproved(_id) || isApprovedForAll(ownerOf(_id), msg.sender), "Error: You must own this token to burn it.");
        _burn(_id);
        emit Burn(msg.sender, _id);
        return (true, _id);

    }

    function distributeShares() external minAdmin2 {

        for (uint i = 0; i < _distro.length; i++) {
            release(payable(_distro[i]));
        }

    }

    function isContract(address account) internal view returns (bool) {  
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }    

    // ~(<>..<>)~ THE END. ~(<>..<>)~
    // .--- .. -- .--.-. --. . -. . .-. .- - .. ...- . -. ..-. - ... .-.-.- .. ---

}
