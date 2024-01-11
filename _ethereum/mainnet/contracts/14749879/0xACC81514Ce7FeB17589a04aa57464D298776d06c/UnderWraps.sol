// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

abstract contract CoolCats {
    function walletOfOwner(address addr) public virtual view returns(uint256[] memory);
}

contract UnderWraps is ERC721A, Ownable {  
    using Address for address;

    CoolCats private cc;
    
    // Starting and stopping sale and presale
    bool public active = false;
    bool public presaleActive = false;

    // Reserved for the team for customs, giveaways, collabs and so on.
    uint256 public reserved = 100;

    // Price of each token
    uint256 public price = 0.05 ether;

    // Maximum limit of tokens that can ever exist
    uint256 constant MAX_SUPPLY = 10000;

    // The base link that leads to the image / video of the token
    string public baseTokenURI;

    bytes32 public whitelistRoot;

    bytes32 public holderWhitelistRoot;

    mapping (address => uint256) public freeReserved;

    // Team addresses for withdrawals
    address public a1;
    address public a2;
    address public a3;

    // List of addresses that have a number of reserved tokens for presale minted
    mapping (address => uint256) public presaleMinted;

    constructor (string memory newBaseURI, address ccAddress) ERC721A ("Under Wraps", "UW") {
        setBaseURI(newBaseURI);
        cc = CoolCats(ccAddress);
    }

    // Override so the openzeppelin tokenURI() method will use this method to create the full tokenURI instead
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // See which address owns which tokens
    function tokensOfOwner(address addr) public view returns(uint256[] memory) {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(addr);

        uint256[] memory tokensId = new uint256[](tokenCount);
        uint256 currentMatch = 0;

        if(tokenCount > 0) {
            for(uint256 i; i < supply; i++){
                address tokenOwnerAdd = ownerOf(i);
                if(tokenOwnerAdd == addr) {
                    tokensId[currentMatch] = i;
                    currentMatch = currentMatch + 1;
                }
            }
        }
        
        return tokensId;
    }

    // See which address owns which cc tokens
    function getCCTokenByWallet(address addr) public view returns(uint256[] memory) {
        return cc.walletOfOwner(addr);
    }

    // Exclusive presale minting
    function mintPresale(uint256 _amount, bytes32[] calldata _merkleProof, bytes32[] calldata _holderMerkleProof) public payable {
        require( presaleActive,                  "Presale isn't active" );

        uint256 supply = totalSupply();
        uint256 reservedAmt = 0;
        uint256 alreadyMinted = 0;
        uint256 preSaleLimit = 0;

        // Returns array of Cool Cats token IDs owned by the sender
        uint256[] memory ownedCCTokens = cc.walletOfOwner(msg.sender);
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

        bool isWhiteListed = MerkleProof.verify(_merkleProof, whitelistRoot, leaf);
        bool isHolderWhiteListed = MerkleProof.verify(_holderMerkleProof, holderWhitelistRoot, leaf);

        // add 5 if whitelisted
        if(isWhiteListed) {
            preSaleLimit = preSaleLimit + 5;
        }

        // add 5 for gen 1 holder
        if(isHolderWhiteListed) {
            preSaleLimit = preSaleLimit + 5;
        }

        // add 5 for CoolCats Holder
        if(ownedCCTokens.length > 0) {
            preSaleLimit = preSaleLimit + 5;
        }

        if(preSaleLimit > 0) {
            alreadyMinted = presaleMinted[msg.sender];
            if(alreadyMinted < preSaleLimit) {
                reservedAmt = preSaleLimit - alreadyMinted;
            }
        }

        require( reservedAmt > 0,                "No tokens reserved for your address" );
        require( _amount <= reservedAmt,         "Can't mint more than reserved" );
        require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
        require( msg.value == price * _amount,   "Wrong amount of ETH sent" );

        presaleMinted[msg.sender] = alreadyMinted + _amount;

        _safeMint( msg.sender, _amount );
    }

    // Standard mint function
    function mintToken(uint256 _amount) public payable {
        uint256 supply = totalSupply();
        require( active,                         "Sale isn't active" );
        require( _amount > 0 && _amount < 6,     "Can only mint between 1 and 5 tokens at once" );
        require( supply + _amount <= MAX_SUPPLY, "Can't mint more than max supply" );
        require( msg.value == price * _amount,   "Wrong amount of ETH sent" );

        _safeMint( msg.sender, _amount );
    }

    // Admin minting function to reserve tokens for the team, collabs, customs and giveaways
    function mintReserved(uint256 _amount) public onlyOwner {
        // Limited to a publicly set amount
        uint256 supply = totalSupply();
        require( supply + _amount <= MAX_SUPPLY,    "Can't mint more than max supply" );
        require( _amount <= reserved,               "Can't reserve more than set amount" );
        reserved -= _amount;

        _safeMint( msg.sender, _amount );
    }

    // Free mints for the winners for Reserved Addresses
    function mintFreeReserved(uint256 _amount) public {
        require( presaleActive || active,           "Sale isn't active" );
        uint256 supply = totalSupply();
        uint256 freeAmount = freeReserved[msg.sender];

        require( freeAmount > 0,                    "No free reseved tokens" );
        require( _amount <= freeAmount,             "Can't mint more than reserved" );
        require( supply + _amount <= MAX_SUPPLY,    "Can't mint more than max supply" );

        freeReserved[msg.sender] = freeAmount - _amount;
        _safeMint( msg.sender, _amount);
    }

    // Edit reserved presale spots
    function editFreeReserved(address[] memory _a, uint256[] memory _amount) public onlyOwner {
        for(uint256 i; i < _a.length; i++){
            freeReserved[_a[i]] = _amount[i];
        }
    }

    // Start and stop presale
    function setPresaleActive(bool val) public onlyOwner {
        presaleActive = val;
    }

    // Start and stop sale
    function setActive(bool val) public onlyOwner {
        active = val;
    }

    // Set new baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    // Set a different price in case ETH changes drastically
    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    // Set new MerkleTree Root 
    function setWhiteListRoot(bytes32 newRoot) public onlyOwner {
        whitelistRoot = newRoot;
    }

    // Set new Holder MerkleTree Root 
    function setHolderWhiteListRoot(bytes32 newRoot) public onlyOwner {
        holderWhitelistRoot = newRoot;
    }

    // Set team addresses
    function setAddresses(address[] memory _a) public onlyOwner {
        a1 = _a[0];
        a2 = _a[1];
        a3 = _a[2];
    }

    // Withdraw funds from contract for the team
    function withdrawTeam(uint256 amount) public payable onlyOwner {
        uint256 percent = amount / 100;
        require(payable(a1).send(percent * 60)); // 60% for James
        require(payable(a2).send(percent * 30)); // 30% for NFT Forge
        require(payable(a2).send(percent * 10)); // 10% for trnj
    }
}