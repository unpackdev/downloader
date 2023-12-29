//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol"; 
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

/**
*    Max Supply - 10000
*    Stage 1 - WL and Public for 2 hours (manually controlled)
*    
*    Whitelist
*    Supply: 6500
*    1 free then paid 0.0069, max 3 per transaction/wallet, 
*
*    Public: 3500
*    Paid at 0.0075, max 4 per transaction/wallet
*
*    Stage 2 - Open Stage
*    Public - All remaining supply
*    Paid at 0.0075, max 4 per transaction/wallet
*/

contract Maximals is ERC721A, Ownable, Pausable, ReentrancyGuard {

    uint256 public maxSupply = 10000;

    //minter roles configuration
    struct MintersInfo {
        uint8 maxMintPerTransaction; //max mint per wallet and per transaction
        uint8 numberOfFreemint;
        uint256 supply; //max allocated supply per minter role
        uint256 mintCost;
        bytes32 root; //Merkle root
    }

    mapping(string => MintersInfo) minters; //map of minter types
    mapping(string => uint256) public mintedCount; //map of total mints per type


    enum Phases { N, Phase1, Public } //mint phases, N = mint not live

    Phases public currentPhase;

    mapping(address => uint256) minted; //map of addresses that minted
    mapping(string => mapping(address => uint8)) public mintedPerRole;  //map of addresses that minted per phase and their mint counts
    mapping(address => uint8) public mintedFree; //map of addresses that minted free and their mint counts

    address[] public mintersAddresses; //addresses of minters    
    
    string private baseURI;
    string[] private prerevealedArtworks;
    bool isRevealed;

    //events
    event Minted(address indexed to, uint8 numberOfTokens, uint256 amount);
    event SoldOut();
   
    event PhaseChanged(address indexed to, uint256 indexed eventId, uint8 indexed phaseId);
    event WithdrawalSuccessful(address indexed to, uint256 amount);
    event CollectionRevealed(address indexed to);
    

    //errors
    error WithdrawalFailed();

    constructor() ERC721A("Maximals", "MAXIM") {
        _pause();
        currentPhase = Phases.N;

        //added an invalid root here to avoid zero comparison later
        addMintersInfo(
            "WL", //minter role name
            3, //max per wallet/per transaction
            1, //number of free mint
            6500, //allocated supply
            0.0069 ether, //mint cost
            0x8ac3d4f184349fb28ebb642349f97130ce71b7bc967acb07c881b5ec27ad725c //root dummy
        );

        addMintersInfo(
            "PUBLIC", //minter role name
            4, //max per wallet/per transaction
            0, //number of free mint
            3500, //allocated supply
            0.0075 ether, //mint cost
            0x8ac3d4f184349fb28ebb642349f97130ce71b7bc967acb07c881b5ec27ad725c //root dummy
        );

    }

    /*
    * ******** ******** ******** ******** ******** ******** ********
    * Public Mint functions
    * ******** ******** ******** ******** ******** ******** ********
    */
    
    function whitelistMint(uint8 numberOfTokens, bytes32[] calldata proof) external payable nonReentrant whenNotPaused {

        require(currentPhase == Phases.Phase1, "ERROR: Mint is not active.");
        string memory _minterRole = "WL"; //set minter role
       
        uint256 _totalCost;

        //verify whitelist
        require(_isWhitelisted(msg.sender, proof, minters[_minterRole].root), "ERROR: You are not allowed to mint on this phase.");

        require(mintedCount[_minterRole] + numberOfTokens <= minters[_minterRole].supply, "ERROR: Maximum number of mints on this phase has been reached");
        require(numberOfTokens <= minters[_minterRole].maxMintPerTransaction, "ERROR: Maximum number of mints per transaction exceeded");
        require((mintedPerRole[_minterRole][msg.sender] + numberOfTokens) <= minters[_minterRole].maxMintPerTransaction, "ERROR: Your maximum NFT mint per wallet on this phase has been reached.");

        //Free mint check
        if ((mintedFree[msg.sender] > 0)) {

            _totalCost = minters[_minterRole].mintCost * numberOfTokens;
            require(msg.value >= _totalCost, "ERROR: You do not have enough funds to mint.");

        } else {

            //Block for free mint
            if (numberOfTokens == 1) {
                
                require(mintedFree[msg.sender] == 0, "ERROR: You do not have enough funds to mint.");

            } else if (numberOfTokens > 1) {

                _totalCost = minters[_minterRole].mintCost * (numberOfTokens - minters[_minterRole].numberOfFreemint);
                require(msg.value >= _totalCost, "ERROR: You do not have enough funds to mint.");
            
            }
            
            mintedFree[msg.sender] = 1; // Register free mint
        }
        
        _phaseMint(_minterRole, numberOfTokens, _totalCost);
    }

    function publicMint(uint8 numberOfTokens) external payable nonReentrant whenNotPaused {
        
        require(currentPhase != Phases.N, "ERROR: Mint is not active.");
        string memory _minterRole = "PUBLIC";

        require(numberOfTokens <= minters[_minterRole].maxMintPerTransaction, "ERROR: Maximum number of mints per transaction exceeded");
        require((mintedPerRole[_minterRole][msg.sender] + numberOfTokens) <= minters[_minterRole].maxMintPerTransaction, "ERROR: Your maximum NFT mint per wallet on this phase has been reached.");

        if (currentPhase == Phases.Phase1) {
            //on this phase make sure that the allocated supply count per minter role will not be exceeded
            require(mintedCount[_minterRole] + numberOfTokens <= minters[_minterRole].supply, "ERROR: Maximum number of mints on this phase has been reached");
        }

        uint256 _totalCost;
        _totalCost = minters[_minterRole].mintCost * numberOfTokens;
        require(msg.value >= _totalCost, "ERROR: You do not have enough funds to mint.");
        
        _phaseMint(_minterRole, numberOfTokens, _totalCost);          
    }

    function verifyWhitelist(string memory _minterType, address _address, bytes32[] calldata _merkleProof) public view returns (bool) {
        require(minters[_minterType].root != bytes32(0), "ERROR: Minter Type not found.");
        if (_isWhitelisted(_address, _merkleProof, minters[_minterType].root))
            return true;
        return false;
    }

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

        if (isRevealed) {
            _tokenId += 1;
            return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
        }

        uint _ipfsIndex = _tokenId % prerevealedArtworks.length; //distribute pre-reveal images, alternating

        return prerevealedArtworks[_ipfsIndex];
    }

     /*
    * ******** ******** ******** ******** ******** ******** ********
    * Public - onlyOwner functions
    * ******** ******** ******** ******** ******** ******** ********
    */

    function setMintPhase(uint8 _phase) public onlyOwner {
        currentPhase = Phases(_phase);
        emit PhaseChanged(msg.sender, block.timestamp, uint8(currentPhase));
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    //Function to add MintersInfo to minters
    function addMintersInfo(
        string memory _minterName,
        uint8 _maxMintPerTransaction,
        uint8 _numberOfFreeMint,
        uint256 _supply,
        uint256 _mintCost,
        bytes32 _root
    ) public onlyOwner {
        MintersInfo memory newMintersInfo = MintersInfo(
            _maxMintPerTransaction,
            _numberOfFreeMint,
            _supply,
            _mintCost,
            _root
        );
        minters[_minterName] = newMintersInfo;
    }

    //Function to modify MintersInfo of a minterRole
    function modifyMintersInfo(
        string memory _minterName,
        uint8 _newMaxMintPerTransaction,
        uint8 _newNumberOfFreeMint,
        uint256 _newSupply,
        uint256 _newMintCost,
        bytes32 _newRoot
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintersInfo not found.");
        MintersInfo memory updatedMintersInfo = MintersInfo(
            _newMaxMintPerTransaction,
            _newNumberOfFreeMint,
            _newSupply,
            _newMintCost,
            _newRoot
        );

        minters[_minterName] = updatedMintersInfo;
    }

    function modifyMintersMintCost(
        string memory _minterName,
        uint256 _newMintCost
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintersInfo not found.");
        minters[_minterName].mintCost = _newMintCost;
    }

    function modifyMintersSupply(
        string memory _minterName,
        uint256 _newSupplyCount
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintersInfo not found.");
        minters[_minterName].supply = _newSupplyCount;
    }

    function modifyFreeMintCount(
        string memory _minterName,
        uint8 _newFreeMintCount
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintersInfo not found.");
        minters[_minterName].numberOfFreemint = _newFreeMintCount;
    }

    function modifyMintersMaxMintPerTransaction(
        string memory _minterName,
        uint8 _newMaxMintPerTransaction
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintersInfo not found.");
        minters[_minterName].maxMintPerTransaction = _newMaxMintPerTransaction;
    }

    //Function to get the MintersInfo for a specific minter
    function getMintInfo(string memory _minterName, address _userAddress) public view returns (uint8, uint8, uint256, uint256, uint256, uint8) {

        uint8 _mintedPerRole = mintedPerRole[_minterName][_userAddress];
        return (
           
            uint8(currentPhase),
            minters[_minterName].maxMintPerTransaction,
            minters[_minterName].mintCost, 
            minters[_minterName].supply, 
            mintedCount[_minterName],
            _mintedPerRole
        );
    }

    function getSupplyInfo() public view returns (uint256, uint256, uint8) {
        return (maxSupply, totalSupply(), uint8(currentPhase));
    }

    //Function to modify the root of an existing MintersInfo
    function modifyMintersRoot(string memory _minterName, bytes32 _newRoot) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "ERROR: MintersInfo not found."); //change
        minters[_minterName].root = _newRoot;
    }

    function modifyPrerevealImages(string[] memory _urlArray) public onlyOwner {
        prerevealedArtworks = _urlArray;
    }

    function revealCollection (string memory _baseURI, bool _isRevealed) public onlyOwner {
        isRevealed = _isRevealed;
        baseURI = _baseURI;

        if (isRevealed)
            emit CollectionRevealed(msg.sender);
    }

    function unPause() public onlyOwner {
        _unpause();
    }

    function pause() public onlyOwner whenNotPaused {
        _pause();
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

    /*
    * ******** ******** ******** ******** ******** ******** ********
    * Internal - functions
    * ******** ******** ******** ******** ******** ******** ********
    */  

    function _phaseMint(string memory _minterRole, uint8 _numberOfTokens, uint256 _totalCost) internal {
        
        require((_totalMinted() + _numberOfTokens) <= maxSupply, "ERROR: No tokens left to mint");
        require(_numberOfTokens > 0, "ERROR: Number of tokens should be greater than zero");

        _safeMint(msg.sender, _numberOfTokens);

        //after mint registry
        mintedCount[_minterRole] += _numberOfTokens; //adds the newly minted token count per minter Role
        //mintedPerPhase[uint8(currentPhase)][msg.sender] += _numberOfTokens; //registers the address and the number of tokens of the minter
        mintedPerRole[_minterRole][msg.sender] += _numberOfTokens; //registers the address and the number of tokens of the minter per role
        mintersAddresses.push(msg.sender); //registers minters address, for future purposes

        emit Minted(msg.sender, _numberOfTokens, _totalCost);
        
        //if total minted reach or exceeds max supply - pause contract
        if (_totalMinted() >= maxSupply) {
            emit SoldOut();
           // _pause();
        }    
    } 

    //for whitelist check
    function _isWhitelisted  (
        address _minterLeaf,
        bytes32[] calldata _merkleProof, 
        bytes32 _minterRoot
    ) public pure returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(_minterLeaf));
        return MerkleProof.verify(_merkleProof, _minterRoot, _leaf);
    }

    
}


/*
* ***** ***** ***** ***** 
*/