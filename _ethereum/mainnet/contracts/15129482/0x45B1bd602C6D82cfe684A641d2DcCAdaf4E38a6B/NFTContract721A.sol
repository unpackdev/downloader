// SPDX-License-Identifier: MIT

/*


      ,gg,                                ,ggggggggggggggg                                  
     i8""8i         ,dPYb, ,dPYb,        dP""""""88"""""""                                  
     `8,,8'         IP'`Yb IP'`Yb        Yb,_    88                                          
      `88'     gg   I8  8I I8  8I         `""    88                                          
      dP"8,    ""   I8  8' I8  8'                88                                          
     dP' `8a   gg   I8 dP  I8 dP  gg     gg      88   ,ggggg,   gg    gg    gg   ,ggg,,ggg,  
    dP'   `Yb  88   I8dP   I8dP   I8     8I      88  dP"  "Y8gggI8    I8    88bg,8" "8P" "8,
_ ,dP'     I8  88   I8P    I8P    I8,   ,8Igg,   88 i8'    ,8I  I8    I8    8I  I8   8I   8I
"888,,____,dP_,88,_,d8b,_ ,d8b,_ ,d8b, ,d8I "Yb,,8P,d8,   ,d8' ,d8,  ,d8,  ,8I ,dP   8I   Yb,
a8P"Y88888P" 8P""Y88P'"Y888P'"Y88P""Y88P"888  "Y8P'P"Y8888P"   P""Y88P""Y88P"  8P'   8I   `Y8
____________________________________   ,d8I'  _______________________________________________
                                     ,dP'8I                                                  
      10,000 unique characters      ,8"  8I      The Residents of SillyTown Series 001      
        Created by Dan Grove        I8   8I         Find Phibb & Troy @ silly.town          
                                    `8, ,8I                                                  
                                     `Y8P" 

COPYRIGHT INFORMATION

I. Our Copyright Provisions. 

We (SillyTown LLC) retain a perpetual, worldwide, commercial copyright license to reproduce any and all original SillyTown content, including the specific Artwork associated with all NFTs (even ones You currently own). Additionally, We hold the exclusive right to prepare derivative works of any and all original SillyTown content. 

We can use Our original, reproduced, or derivative content to create new NFTs, promotional materials, merchandise, and any other form of media We choose at any time.

II. Your Copyright Provisions.

When it can be cryptographically verified that You currently hold any official SillyTown NFT(s) in your blockchain wallet, You own that/those particular NFT(s). We grant You a non-exclusive, worldwide, personal and commercial copyright license to reproduce and publicly display the Artwork associated with the NFT(s) You own. We do not grant You any license for any NFTs or any other SillyTown content that You do not own. We do not grant You or anyone a license to prepare derivative works of any NFTs or any other SillyTown content. 

You retain this copyright for the Artwork associated with your NFT(s) as long as You own the NFT(s). You relinquish Your copyright for the Artwork associated with a given NFT as soon as it is no longer in Your blockchain wallet, regardless of if it is sold, traded, given away, stolen, or otherwise lost. 

The following are a few examples of what You may do with Your copyright license:

  * You may post the Artwork featured in your NFT(s) on the internet, social media, and use it as an avatar for Your profile pictures.

  * You may create and sell merchandise using the Artwork featured in Your NFT(s) for as long as You own the corresponding NFT(s).

III. Restrictions.

The following are a few examples of what You may not do with Your copyright license:

  * You may not change, modify or otherwise prepare derivatives of any Artwork or NFT.

  * You may not display any Artwork or NFT(s) in any way that connects the Artwork or SillyTown to any media or language that depicts, promotes, incites, or participates in violence, abuse, hate speech, racism, harassment, defamation, intimidation, disparagement, pornography, or anything else We deem to be inappropriate or objectionable.

  *  You may not display any Artwork or NFT(s) in any way that expressly communicates or implies SillyTown’s association with or endorsement of any business, service, cause, or ideology.

  * You may not use the Artwork associated with your NFT(s) to create, promote, advertise, or sell another NFT or digital product.

By holding a SillyTown NFT, you agree to the Terms and Conditions at https://silly.town. Please refer to our documentation there for the latest information on copyright.

*/

pragma solidity 0.8.4;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721A.sol";

// Merkle tree:
import "./MerkleProof.sol";

contract SillyTown is Ownable, ERC721A, PaymentSplitter {

    uint public MAXSUPPLY = 10000;  // Hard-coded in setMaxSupply() also.
    uint public THEMINTPRICE = 0.06 ether; // Presale 0.06, Public 0.08
    uint public WALLETLIMIT = 2; // Presale 2 , Public 10 
    string public PROVENANCE_HASH;
    string private METADATAURI;
    string private CONTRACTURI;
    bool public PRESALEISLIVE = false;
    bool public SALEISLIVE = false;
    bool private MINTLOCK;
    bool private PROVENANCE_LOCK = false;
    uint public RESERVEDNFTS;
    uint id = totalSupply();

    // Merkle tree:
    bytes32 public merkleRoot;
    mapping(address => bool) public allowlistClaimed;

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

    // Merkle tree (add bytes32 _merkleRoot)
    constructor(address[] memory distro, uint[] memory distro_shares, address[] memory teamclaim, bytes32 _merkleRoot)
        ERC721A("SILLY-TOWN", "SILLY")
        PaymentSplitter(distro, distro_shares)
    {
        METADATAURI = "ipfs://QmVPLq3wPzs1K429DLJy8iJuSdRWoVDiTb4TA8JFi7fNGb/"; // prereveal

        accounts[msg.sender] = Account( 0, 0, 0 );

        // Set Team NFTs & Initial Admin Levels:
        accounts[teamclaim[0]]  = Account( 25, 0, 1 ); // DG1 
        accounts[teamclaim[1]]  = Account(  6, 0, 1 ); // FF1
        accounts[teamclaim[2]]  = Account(  1, 0, 1 ); // FF2
        accounts[teamclaim[3]]  = Account(  1, 0, 1 ); // FF3
        accounts[teamclaim[4]]  = Account(  4, 0, 1 ); // FF4
        accounts[teamclaim[5]]  = Account(  3, 0, 1 ); // FF5
        accounts[teamclaim[6]]  = Account(  1, 0, 1 ); // FF6
        accounts[teamclaim[7]]  = Account(  3, 0, 1 ); // FF7
        accounts[teamclaim[8]]  = Account(  1, 0, 1 ); // FF8
        accounts[teamclaim[9]]  = Account( 25, 0, 1 ); // G1
        accounts[teamclaim[10]] = Account( 25, 0, 1 ); // G2
        accounts[teamclaim[11]] = Account( 25, 0, 1 ); // G3
        accounts[teamclaim[12]] = Account( 25, 0, 1 ); // G4

        RESERVEDNFTS = 145;  
        // Does not count: (1) airdrop ID #1 to DG, (2) airdrop IDs 2-6 to prize wallets

        _distro = distro;
        _distro_shares = distro_shares;

        // Merkle tree:
        merkleRoot = _merkleRoot;

    }

    // (^_^) Modifiers (^_^) 

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

    // (^_^) Overrides (^_^) 

    // Start token IDs at 1 instead of 0
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }    

    // (^_^) Setters (^_^) 

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

    function salePresaleActivate() external minAdmin2 {
        PRESALEISLIVE = true;
    }

    function salePresaleDeactivate() external minAdmin2 {
        PRESALEISLIVE = false;
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

    function setWalletLimit(uint _newLimit) external onlyOwner {
        WALLETLIMIT = _newLimit;
    }
    
    // (^_^) Getters (^_^)

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

    // -- For the Merkle tree
    function getMerkleRoot() public view returns (bytes32){ 
        return merkleRoot; 
    }

    // (^_^) Functions (^_^) 

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

    // Merkle tree:
    function allowlistMint(bytes32[] calldata _merkleProof, uint _amount) external payable noReentrant {
        require(PRESALEISLIVE, "Error: Allowlist Sale is not active.");
        require(totalSupply() + _amount <= (MAXSUPPLY - RESERVEDNFTS), "Error: Purchase would exceed max supply.");
        require((_amount + accounts[msg.sender].mintedNFTs) <= WALLETLIMIT, "Error: You would exceed the wallet limit.");
        require(!isContract(msg.sender), "Error: Contracts cannot mint.");
        require(msg.value >= (THEMINTPRICE * _amount), "Error: Not enough ether sent.");
        require(!allowlistClaimed[msg.sender], "Error: You have already claimed all of your NFTs.");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Error: You are not allowlisted.");

        if ( ( _amount + accounts[msg.sender].mintedNFTs ) == WALLETLIMIT ) {
            allowlistClaimed[msg.sender] = true;
        }

	    accounts[msg.sender].mintedNFTs += _amount;
        _safeMint(msg.sender, _amount);
        emit Mint(msg.sender, totalSupply());

    } 

    function changeMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    } 

    // (^_^) THE END. (^_^)
    // .--- .. -- .--.-. --. . -. . .-. .- - .. ...- . -. ..-. - ... .-.-.- .. ---

}
