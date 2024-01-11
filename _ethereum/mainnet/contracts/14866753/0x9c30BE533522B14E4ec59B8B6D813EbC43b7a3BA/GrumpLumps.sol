// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

// @author ACEWLBRN

contract GrumpLumps is 
    ERC721A, 
    Ownable, 
    ReentrancyGuard, 
    PaymentSplitter
{
    using Strings for uint256;

    bytes32 public root;
    
    address proxyRegistryAddress;
    
    uint256 public currentSuppply = 0;
    uint256 public maxSupply = 5010;

    string public baseURI; 
    string public notRevealedUri = "ipfs://QmcHJxuDQeaCJ8C4JsMEK3fZMHTjXbvCEEbrQkSXmM3nEH/hidden.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;
    bool public teamMinted;

    uint256 presaleAmountLimit = 5;
    mapping(address => uint256) public _presaleClaimed;

    uint256 _price = 20000000000000000; // 0.02 ETH
    uint256 _presalePrice = 10000000000000000; // 0.01 ETH

    uint256[] private _teamShares = [50, 50]; // 2 Wallets involved, Teams wallet & Community funds
    address[] private _team = [
        0x475Fb1e1b5AA9c9867f8849C7D7c09C9E2073549, // Grumps Team Wallet Account gets 50% of the total revenue
        0x8ed8C3546Ac818FD40D0430538e728b65e0988e3 // Community Funds Wallet Account gets 50% of the total revenue
    ];

    constructor(string memory uri, bytes32 merkleroot, address _proxyRegistryAddress)
        ERC721A("Grump Lumps", "Grump")
        PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
        
        root = merkleroot;
        proxyRegistryAddress = _proxyRegistryAddress;

        setBaseURI(uri);

    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setMerkleRoot(bytes32 merkleroot) 
    onlyOwner 
    public 
    {
        root = merkleroot;
    }

    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            root,
            keccak256(abi.encodePacked(msg.sender))
            ) == true, "Not allowed origin");
        _;
   }

    function togglePause() public onlyOwner {
        paused = !paused;
    }

    function togglePresale() public onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() public onlyOwner {
        publicM = !publicM;
    }

    function teamMint(uint256 _amount) external onlyOwner{
        require(!teamMinted, "Grump Lumps: Team already minted");
        teamMinted = true;

        for (uint256 a = 1; a <= 200; a++) {
           _safeMint(msg.sender, _amount);
        }
    }

    function presaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    public
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "Grump Lumps: Not allowed");
        require(presaleM,                       "Grump Lumps: Presale is OFF");
        require(!paused,                        "Grump Lumps: Contract is paused");
        require(_amount <= presaleAmountLimit,  "Grump Lumps: You can not mint that many tokens");
        require(_presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "Grump Lumps: You can not mint that many tokens");
        require(currentSuppply + _amount <= maxSupply, "Grump Lumps: max supply exceeded");

        if (msg.sender != owner()) {
      require(_presalePrice * _amount <= msg.value, "Grump Lumps: Not enough ethers sent");
        }

        _safeMint(msg.sender, _amount);

    }

    function publicSaleMint(uint256 _amount) 
    public 
    payable
    onlyAccounts
    {
        require(publicM,                        "Grump Lumps: Public Sale is OFF");
        require(!paused, "Grump Lumps: Contract is paused");
        require(_amount > 0, "Grump Lumps: zero amount");
        require(currentSuppply + _amount <= maxSupply, "Grump Lumps: Max supply exceeded");

        if (msg.sender != owner()) {
        require(_price * _amount <= msg.value, "Grump Lumps: Not enough ethers sent");
        }

        _safeMint(msg.sender, _amount);
        
    }    

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
    
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}



/**
  @title An OpenSea delegate proxy contract which we include for whitelisting.
  @author OpenSea
*/
contract OwnableDelegateProxy {}

/**
  @title An OpenSea proxy registry contract which we include for whitelisting.
  @author OpenSea
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}