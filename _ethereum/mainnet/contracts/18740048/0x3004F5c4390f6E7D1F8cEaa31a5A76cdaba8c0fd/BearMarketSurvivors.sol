//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol"; 
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

/** ***********************************************
* BMS BMS       BMS             BMS.    BMS BMS BMS
* BMS     BMS.  BMS BMS.    BMS BMS.  BMS
* BMS BMS       BMS.    BMS.    BMS.  BMS BMS 
* BMS     BMS   BMS     BMS.    BMS.     BMS BMS
* BMS     BMS.  BMS             BMS  BMS     BMS
* BMS BMS       BMS ....        BMS  BMS BMS
* *************************************************
* *************************************************
* -------  ------------------------------ ---------
*/

contract BMS is ERC721A, Ownable, Pausable, ReentrancyGuard {

    uint256 public maxSupply = 2023;
    
    mapping(string => uint256) public mintedCount; //map of total mints per phase
    mapping(address => uint256) minted; //map of addresses that minted
    mapping(string => mapping(address => uint8)) public mintedPerRole;  //map of addresses that minted per phase and their mint counts
    mapping(address => uint8) public mintedFree; //map of addresses that minted free and their mint counts
    
    mapping(string => string) private metadataRoot;

    uint8 publicMaxMintPerTransaction = 2; 
    uint256 publicSupply = 2023; 
    uint256 publicMintCost = 0.0099 ether;

    uint8 wlMaxMintPerTransaction = 2; 
    uint8 wlNumberOfFreemint = 1;
    uint256 wlSupply = 2023; 
    uint256 wlMintCost = 0.0077 ether;
    bytes32 root;
 
    enum Phases { N, Whitelist, Public } //mint phases, N = mint not live
    Phases public currentPhase;
    
    string private baseURI = "ipfs://bafybeia2m4h4fttolhesaobzmcgbpolzgbkqziymhtnezvfn4p6xb7dwre/";
    mapping(uint8 => string) levelsIPFS;
    bool isRevealed;

    bool isUpgradeLive;
    uint256 upgradeCost = 0.01 ether;
    mapping(uint256 => uint8) public levels;

    //events
    event Minted(address indexed to, uint8 numberOfTokens, uint256 amount);
    event SoldOut();
    event PhaseChanged(address indexed to, uint256 indexed eventId, uint8 indexed phaseId);
    event WithdrawalSuccessful(address indexed to, uint256 amount);

    //errors
    error WithdrawalFailed();

    constructor() ERC721A("Bear Market Survivors by Dotseemple_Ai", "BMS") {}

    /*
    * Mint functions 
    */
    
    function whitelistMint(uint8 numberOfTokens, bytes32[] calldata proof) external payable nonReentrant whenNotPaused {

        require(currentPhase == Phases.Whitelist, "ERROR: Whitelist Mint is not active.");
        string memory _minterPhase = "WHITELIST";
       
        uint256 _totalCost;

        //verify whitelist 
        require(isWhitelisted(msg.sender, proof, root), "ERROR: You are not allowed to mint on this phase.");

        require(numberOfTokens > 0, "ERROR: Number of tokens should be greater than zero");
        
        require(numberOfTokens <= wlMaxMintPerTransaction, "ERROR: Maximum number of mints per transaction exceeded");
        require((mintedPerRole[_minterPhase][msg.sender] + numberOfTokens) <= wlMaxMintPerTransaction, "ERROR: Your maximum NFT mint per wallet on this phase has been reached.");
        
        require((_totalMinted() + numberOfTokens) <= maxSupply, "ERROR: No tokens left to mint");
        require(mintedCount[_minterPhase] + numberOfTokens <= wlSupply, "ERROR: Maximum number of mints on this phase has been reached");

        //Free mint check
        if ((mintedFree[msg.sender] > 0)) {

            _totalCost = wlMintCost * numberOfTokens;
            require(msg.value >= _totalCost, "ERROR: You do not have enough funds to mint.");

        } else {

            //Block for free mint
           if (numberOfTokens > wlNumberOfFreemint) {

                _totalCost = wlMintCost * (numberOfTokens - wlNumberOfFreemint);
                require(msg.value >= _totalCost, "ERROR: You do not have enough funds to mint.");
            
            }
            
            mintedFree[msg.sender] = 1; // Register free mint
        }

        _safeMint(msg.sender, numberOfTokens);

        //after mint registry
        mintedCount[_minterPhase] += numberOfTokens; //adds the newly minted token count per minter Role
        mintedPerRole[_minterPhase][msg.sender] += numberOfTokens; //registers the address and the number of tokens of the minter per role

        emit Minted(msg.sender, numberOfTokens, _totalCost);
        
        //if total minted reach or exceeds max supply - pause contract
        if (_totalMinted() >= maxSupply) {
            emit SoldOut();
        }    
    }

    function publicMint(uint8 numberOfTokens) external payable nonReentrant whenNotPaused {
        
        require(currentPhase == Phases.Public, "ERROR: Mint is not active.");
        string memory _minterPhase = "PUBLIC";
        
        require(numberOfTokens > 0, "ERROR: Number of tokens should be greater than zero");

        require(numberOfTokens <= publicMaxMintPerTransaction, "ERROR: Maximum number of mints per transaction exceeded");
        require((mintedPerRole[_minterPhase][msg.sender] + numberOfTokens) <= publicMaxMintPerTransaction, "ERROR: Your maximum NFT mint per wallet on this phase has been reached.");
        
        require(mintedCount[_minterPhase] + numberOfTokens <= publicSupply, "ERROR: Maximum number of mints on this phase has been reached");
        require((_totalMinted() + numberOfTokens) <= maxSupply, "ERROR: No tokens left to mint");
        
        uint256 _totalCost;
        _totalCost = publicMintCost * numberOfTokens;
        require(msg.value >= _totalCost, "ERROR: You do not have enough funds to mint.");

        _safeMint(msg.sender, numberOfTokens);

        //after mint registry
        mintedCount[_minterPhase] += numberOfTokens; //adds the newly minted token count per minter Role
        mintedPerRole[_minterPhase][msg.sender] += numberOfTokens; //registers the address and the number of tokens of the minter per role

        emit Minted(msg.sender, numberOfTokens, _totalCost);
        
        //if total minted reach or exceeds max supply - pause contract
        if (_totalMinted() >= maxSupply) {
            emit SoldOut();
        }           
    }

    function internalMint(uint8 numberOfTokens) public onlyOwner {
        require((_totalMinted() + numberOfTokens) <= maxSupply, "ERROR: Not enough tokens");
        _safeMint(msg.sender, numberOfTokens);
        emit Minted(msg.sender, numberOfTokens, 0);
    }

    function airdrop(uint8 numberOfTokens, address recipient) public onlyOwner whenNotPaused {
        require((_totalMinted() + numberOfTokens) <= maxSupply, "ERROR: Not enough tokens left");
        _safeMint(recipient, numberOfTokens);
    }

    function multipleAirdrop(uint8 numberOfTokens, address[] memory recipients) public onlyOwner whenNotPaused {
        for (uint256 i = 0; i < recipients.length; i++) {
            airdrop(numberOfTokens, recipients[i]);
        }
    }

    function verifyWhitelist(address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        if (isWhitelisted(_address, _merkleProof, root))
            return true;
        return false;
    }

    //for whitelist check
    function isWhitelisted  (
        address _minterLeaf,
        bytes32[] calldata _merkleProof, 
        bytes32 _minterRoot
    ) public pure returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_minterLeaf));
        return MerkleProof.verify(_merkleProof, _minterRoot, _leaf);
    }

    //setters
    function setMintPhase(uint8 _phase) public onlyOwner {
        currentPhase = Phases(_phase);
        emit PhaseChanged(msg.sender, block.timestamp, uint8(currentPhase));
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPhaseMaxSupply(uint256 _maxSupply, bool _isPublic) public onlyOwner {
        if ( _isPublic )
            publicSupply = _maxSupply;
        else
            wlSupply = _maxSupply;
    }

    function setPhaseMaxMintPerTx(uint8 _maxMintPerTx, bool _isPublic) public onlyOwner {
        if ( _isPublic )
            publicMaxMintPerTransaction = _maxMintPerTx;
        else
            wlMaxMintPerTransaction = _maxMintPerTx;
    }

    function setPhaseMintCost(uint256 _mintCost, bool _isPublic) public onlyOwner {
        if ( _isPublic )
            publicMintCost = _mintCost;
        else
            wlMintCost = _mintCost;
    }

    //Function to set the Merkel root
    function setRoot(bytes32 _newRoot) public onlyOwner {
        root = _newRoot;
    }

    /***************************************************************************************/

    /*
    * Reveal functions
    */

    function revealCollection (string memory _baseURI, bool _isRevealed, uint8 _level) public onlyOwner {
        isRevealed = _isRevealed;
        baseURI = _baseURI;

        if (isRevealed) {
            levelsIPFS[_level] = _baseURI;
        }
    }

    /***************************************************************************************/

    /*
    * Levels functions
    */

    function upgradeNFT(uint256 nftId) external payable nonReentrant whenNotPaused {
        require(isUpgradeLive == true, "ERROR: Upgrade is not live.");
        require((msg.sender == ownerOf(nftId)), "ERROR: You are not the owner of this NFT");
        require(msg.value >= upgradeCost, "ERROR: You do not have enough funds to upgrade.");
        
        uint8 _currentLevel = levels[nftId];
        _currentLevel++;

        _upgradeNFTLevel(nftId, _currentLevel);
    }

    function _upgradeNFTLevel(uint256 _nftId, uint8 _level) internal {
        levels[_nftId] = _level; //add 1 step to upgrade
    }
    function setNFTUpgradingLiveStatus(bool _upgradeStatus) public onlyOwner {
        isUpgradeLive = _upgradeStatus;
    }
    function setNFTLevel(uint256 _nftId, uint8 _level) public onlyOwner {
        _upgradeNFTLevel(_nftId, _level);
    }
    function setNFTLevelBulk(uint256[] memory _nftIds, uint8 _level) public onlyOwner {

        uint256 _nftId;

        for (uint8 ctr = 0; ctr < _nftIds.length; ctr++) {
            _nftId = _nftIds[ctr];
            _upgradeNFTLevel(_nftId, _level);
        }
    }

    /***************************************************************************************/

    /*
    * Withdraw Function
    */

    function withdraw() public onlyOwner {

        require(address(this).balance > 0, "ERROR: No balance to withdraw.");
        uint256 amount = address(this).balance;
        //sends fund to team wallet
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");

        if (!success) {
            revert WithdrawalFailed();
        } 

        emit WithdrawalSuccessful(msg.sender, amount);
    }

    /***************************************************************************************/

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _baseURI = baseURI;
        uint8 _level = levels[_tokenId];

        if (isRevealed) {
            _baseURI = levelsIPFS[_level];
        }

        _tokenId += 1;
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    

    function unPause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
    }


    /*
    * Public - GETTER FUNCTIONS - specific for Frontend APPs 
    */

    //Function to get the MintDetails for a specific minter
    function getMintDetails(bool _isPublic, address _userAddress) public view returns (uint8, uint8, uint256, uint256, uint256, uint8) {

        string memory _minterPhase = (_isPublic)? "PUBLIC" : "WHITELIST";
        uint8 _mintedPerRole = mintedPerRole[_minterPhase][_userAddress];
        
        uint8 _maxMintPerTransaction = (_isPublic)? publicMaxMintPerTransaction : wlMaxMintPerTransaction;
        uint256 _mintCost = (_isPublic)? publicMintCost : wlMintCost;
        uint256 _supply = (_isPublic)? publicSupply : wlSupply;

        return (
            uint8(currentPhase),
            _maxMintPerTransaction,
            _mintCost, 
            _supply, 
            mintedCount[_minterPhase],
            _mintedPerRole
        );
    }

    function getSupplyInfo() public view returns (uint256, uint256, uint8) {
        return (maxSupply, totalSupply(), uint8(currentPhase));
    }

    //getter for levels
    function getLevel(uint256 _tokenId) public view returns (uint8) {
        return (levels[_tokenId]);
    } 

}


/*
* ***** ***** ***** ***** 
*/