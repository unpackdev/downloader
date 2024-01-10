// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";

contract CryptidHorsemen is 
    ERC721, 
    Ownable, 
    ReentrancyGuard, 
    PaymentSplitter 
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    
    address proxyRegistryAddress;

    uint256 public maxSupply = 3000;

    string public baseURI; 
    string public notRevealedUri = "ipfs://QmdmVz1GtE1qz6wTYTQMppEQMdw9xWdB186GC3xPQwZkSJ/hidden.json";
    string public baseExtension = ".json";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;

    uint256 presaleAmountLimit = 3;
    mapping(address => uint256) public _presaleClaimed;

    uint256 _price = 10000000000000000; // 0.01 ETH

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [50, 25, 25]; // 3 PEOPLE IN THE TEAM
    address[] private _team = [
        0x677eF3A1912008b450dD639e40b76baD1Cc77850, // Admin1 Account gets 50% of the total revenue
        0xC7832Ee84b43ef2eFB9AA1701E4799f3cBE6B27B, // Admin2 Account gets 25% of the total revenue
        0x7DFdb6C811D87c77eD347bD2b0dc50C5F793c29C // Admin3 Account gets 25% of the total revenue
    ];

    constructor(string memory uri, bytes32 merkleroot, address _proxyRegistryAddress)
        ERC721("CryptidHorsemen", "CRHM")
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


    function presaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "CryptidHorsemen: Not allowed");
        require(presaleM,                       "CryptidHorsemen: Presale is OFF");
        require(!paused,                        "CryptidHorsemen: Contract is paused");
        require(
            _amount <= presaleAmountLimit,      "CryptidHorsemen: You can't mint so much tokens");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "CryptidHorsemen: You can't mint so much tokens");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "CryptidHorsemen: max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "CryptidHorsemen: Not enough ethers sent"
        );
             
        _presaleClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount) 
    external 
    payable
    onlyAccounts
    {
        require(publicM,                        "CryptidHorsemen: PublicSale is OFF");
        require(!paused, "CryptidHorsemen: Contract is paused");
        require(_amount > 0, "CryptidHorsemen: zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "CryptidHorsemen: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "CryptidHorsemen: Not enough ethers sent"
        );
        
        
        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function mintInternal() internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        _safeMint(msg.sender, tokenId);
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

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
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



