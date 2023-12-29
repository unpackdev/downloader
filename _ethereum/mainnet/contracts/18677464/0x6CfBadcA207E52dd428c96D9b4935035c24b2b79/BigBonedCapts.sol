//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol"; 
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";

contract BigBonedCapts is ERC721A, Ownable, Pausable, ReentrancyGuard {

    event Minted(address indexed to, uint8 numberOfTokens, uint256 amount);
    event SoldOut();
    event PhaseChanged(address indexed to, uint256 indexed eventId, uint8 indexed phaseId);
    event WithdrawalSuccessful(address indexed to, uint256 amount);
    event CollectionRevealed(address indexed to);
    error WithdrawalFailed();

    uint256 public maxSupply = 8888;

    mapping(string => MintData) minters; //map of minter types
    mapping(string => uint256) public mintedCount; //map of total mints per type
 
    mapping(address => uint256) minted; //map of addresses that minted
    mapping(string => mapping(address => uint8)) public mintedPerRole;  //map of addresses that minted per phase and their mint counts
    mapping(address => uint8) public mintedFree; //map of addresses that minted free and their mint counts

    enum Phases { N, Phase1, Public } //mint phases, N = mint not live

    Phases public currentPhase;
    
    string private baseURI = "ipfs://bafybeiapufuayua4ffs67leiixf34wkplw5bsb7nl5hfjkikzy5dzauomm/";
    bool isRevealed;

    //minter roles configuration
    struct MintData {
        uint8 maxMintPerTransaction; //max mint per wallet and per transaction
        uint8 numberOfFreemint;
        uint256 supply; //max allocated supply per minter role
        uint256 mintCost;
        bytes32 root; //Merkle root
    }

    constructor() ERC721A("Big boned Capt's", "BBC") {}
    
    function presaleMint(uint8 numberOfTokens, bytes32[] calldata proof) external payable nonReentrant whenNotPaused {

        require(currentPhase == Phases.Phase1, "ERROR: Mint is not active.");
        string memory _minterPhase = "WHITELIST"; //set minter role
       
        uint256 _totalCost;

        require(_isWhitelisted(msg.sender, proof, minters[_minterPhase].root), "ERROR: You are not allowed to mint on this phase.");
        require(mintedCount[_minterPhase] + numberOfTokens <= minters[_minterPhase].supply, "ERROR: Maximum number of mints on this phase has been reached");
        require(numberOfTokens <= minters[_minterPhase].maxMintPerTransaction, "ERROR: Maximum number of mints per transaction exceeded");
        require((mintedPerRole[_minterPhase][msg.sender] + numberOfTokens) <= minters[_minterPhase].maxMintPerTransaction, "ERROR: Your maximum NFT mint per wallet on this phase has been reached.");

        //For FREE mint
        if ((mintedFree[msg.sender] > 0)) {

            _totalCost = minters[_minterPhase].mintCost * numberOfTokens;
            require(msg.value >= _totalCost, "ERROR: You do not have enough funds to mint.");

        } else {

            //FREE mint
            if (numberOfTokens > 1) {
                _totalCost = minters[_minterPhase].mintCost * (numberOfTokens - 1);
                require(msg.value >= _totalCost, "ERROR: You do not have enough funds to mint.");
            }
            
            mintedFree[msg.sender] = 1; //flag free mint
        }
        
        _phaseMint(_minterPhase, numberOfTokens, _totalCost);
    }

    function publicMint(uint8 numberOfTokens) external payable nonReentrant whenNotPaused {
        
        require(currentPhase != Phases.N, "ERROR: Mint is not active.");
        string memory _minterPhase = "PUBLIC";

        require(numberOfTokens <= minters[_minterPhase].maxMintPerTransaction, "ERROR: Maximum number of mints per transaction exceeded");
        require((mintedPerRole[_minterPhase][msg.sender] + numberOfTokens) <= minters[_minterPhase].maxMintPerTransaction, "ERROR: Your maximum NFT mint per wallet on this phase has been reached.");

        if (currentPhase == Phases.Phase1) {
            require(mintedCount[_minterPhase] + numberOfTokens <= minters[_minterPhase].supply, "ERROR: Maximum number of mints on this phase has been reached");
        }

        uint256 _totalCost;
        _totalCost = minters[_minterPhase].mintCost * numberOfTokens;
        require(msg.value >= _totalCost, "ERROR: You do not have enough funds to mint.");
        
        _phaseMint(_minterPhase, numberOfTokens, _totalCost);          
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

        _tokenId += 1;
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    //Function to add MintData to minters
    function addMintData(
        string memory _minterName,
        uint8 _maxMintPerTransaction,
        uint8 _numberOfFreeMint,
        uint256 _supply,
        uint256 _mintCost,
        bytes32 _root
    ) public onlyOwner {
        MintData memory newMintData = MintData(
            _maxMintPerTransaction,
            _numberOfFreeMint,
            _supply,
            _mintCost,
            _root
        );
        minters[_minterName] = newMintData;
    }

    //SETTERS

    function setMintPhase(uint8 _phase) public onlyOwner {
        currentPhase = Phases(_phase);
        emit PhaseChanged(msg.sender, block.timestamp, uint8(currentPhase));
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMintersMintCost(
        string memory _minterName,
        uint256 _newMintCost
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintData not found.");
        minters[_minterName].mintCost = _newMintCost;
    }

    function setMintersSupply(
        string memory _minterName,
        uint256 _newSupplyCount
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintData not found.");
        minters[_minterName].supply = _newSupplyCount;
    }

    function setFreeMintCount(
        string memory _minterName,
        uint8 _newFreeMintCount
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintData not found.");
        minters[_minterName].numberOfFreemint = _newFreeMintCount;
    }

    function setMintersMaxMintPerTransaction(
        string memory _minterName,
        uint8 _newMaxMintPerTransaction
    ) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "MintData not found.");
        minters[_minterName].maxMintPerTransaction = _newMaxMintPerTransaction;
    }

    //Function to set the root of an existing MintData
    function setMintersRoot(string memory _minterName, bytes32 _newRoot) public onlyOwner {
        require(minters[_minterName].root != bytes32(0), "ERROR: MintData not found."); //change
        minters[_minterName].root = _newRoot;
    }

    //Function to get the MintData for a specific minter
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
    * Internal - functions
    */  

    function _phaseMint(string memory _minterPhase, uint8 _numberOfTokens, uint256 _totalCost) internal {
        
        require((_totalMinted() + _numberOfTokens) <= maxSupply, "ERROR: No tokens left to mint");
        require(_numberOfTokens > 0, "ERROR: Number of tokens should be greater than zero");

        _safeMint(msg.sender, _numberOfTokens);

        //after mint registry
        mintedCount[_minterPhase] += _numberOfTokens; //adds the neWHITELISTy minted token count per minter Role
        mintedPerRole[_minterPhase][msg.sender] += _numberOfTokens; //registers the address and the number of tokens of the minter per role

        emit Minted(msg.sender, _numberOfTokens, _totalCost);
        
        //if total minted reach or exceeds max supply - pause contract
        if (_totalMinted() >= maxSupply) {
            emit SoldOut();
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