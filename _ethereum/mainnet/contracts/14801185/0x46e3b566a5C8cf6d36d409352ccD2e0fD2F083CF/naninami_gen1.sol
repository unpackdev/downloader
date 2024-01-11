// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";

// Naninami Generation 1
// @author RoSS
// @contact rosanwork@gmail.com

contract naninamigen1 is 
    ERC721, 
    Ownable, 
    ReentrancyGuard, 
    PaymentSplitter 
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    
    address proxyRegistryAddress;

    uint256 public maxSupply = 3;

    string public baseURI; 
    string public notRevealedUri = "https://www.naninami.com/nft/hidden.json";
    string public baseExtension = ".json";
    string public contractMetadataURI = "https://www.naninami.com/nft/sc_gen1.json";

    bool public paused = false;
    bool public presaleM = false;
    bool public revealed = true;
    bool public publicM = true;

    uint256 presaleAmountLimit = 3;
    mapping(address => uint256) public _presaleClaimed;

    
    uint256 _price = 17000000000000000; // 0.017 ETH

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [50, 50]; // Split Rules
    address[] private _team = [
        0xf52036630D3F64e52cF4fa7f7EEaCB7c1967bf62, // Dev2 50
        0x7d907614c8A78B454027cDD21020850d70B94328 // Dev3 50
    ];

    constructor(string memory uri, bytes32 merkleroot, address _proxyRegistryAddress)
        ERC721("naninamiGen1", "nnmg1")
        PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
        root = merkleroot;
        proxyRegistryAddress = _proxyRegistryAddress;

        setBaseURI(uri);
    }

    function setHiddenURI(string memory _tokenHiddenURI) 
    public 
    onlyOwner 
    {
        notRevealedUri = _tokenHiddenURI;
    }

    function _hiddenURI() internal view returns (string memory) {
        return notRevealedUri;
    }

    function setBaseURI(string memory _tokenBaseURI) public onlyOwner {
        baseURI = _tokenBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function reveal() public onlyOwner {
        revealed = !revealed;
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

    function setSalePrice(uint256 newPrice) public onlyOwner {
        _price = newPrice;
    }


    function getCurrentPrice() 
    public 
    view 
    returns (uint256) 
    {
        return _price;
    }


    // Check if NFTID has been minted
    function checkMinted(uint256 _tokenSelector) 
    public 
    view
    returns (bool)
    {
        if (_exists(_tokenSelector)) {
            return true;
        }
        else {
            return false;
        }
    }


    
    function presaleMint(address account, uint256 _amount, bytes32[] calldata _proof, uint256 _tokenSelector)
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "NFT: Not allowed");
        require(presaleM,                       "NFT: Presale is OFF");
        require(!paused,                        "NFT: Contract is paused");
        require(
            _amount <= presaleAmountLimit,      "NFT: You can't mint so many tokens");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "NFT: You can't mint so much tokens");
        
        require(
            _tokenSelector < maxSupply+1,
            "NTF : Impossible Mint"
        );        

        require(
            !_exists(_tokenSelector),
            "NFT : You can not mint this token."
        );
             
        _presaleClaimed[msg.sender] += _amount;

        mintInternal(_tokenSelector);
        
    }


    function publicSaleMint(uint256 _tokenSelector)
    external 
    payable
    onlyAccounts
    {
        require(publicM,                        "NFT: PublicSale is OFF");
        require(!paused,                        "NFT: Contract is paused");
        require(_tokenSelector > 0,             "NFT: Undefined Token");

        uint current = _tokenIds.current();

        require(
            _tokenSelector < maxSupply+1,
            "NTF : Impossible Mint"
        );

        require(
            _price <= msg.value,
            "NFT: Not enough ethers sent"
        );

        require(
           !_exists(_tokenSelector),
            "NFT: Token has been minted before"
        );
        
        mintInternal(_tokenSelector);
    }

    function mintInternal(uint256 _tokenSelector) internal nonReentrant {
        _tokenIds.increment();

        uint256 tokenId = _tokenSelector;
        if (!_exists(tokenId)) {
            _safeMint(msg.sender, tokenId);
        }
        
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


    /**
        Opensea contract Metadata
    */
    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function setContractURI(string memory _newContractURI) 
    public onlyOwner 
    {
        contractMetadataURI = _newContractURI;
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



