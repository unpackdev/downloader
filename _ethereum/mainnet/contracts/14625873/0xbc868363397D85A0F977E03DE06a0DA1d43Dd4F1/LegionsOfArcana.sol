// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*

           ▄█          ▄████████    ▄██████▄   ▄█   ▄██████▄  ███▄▄▄▄      ▄████████                  
          ███         ███    ███   ███    ███ ███  ███    ███ ███▀▀▀██▄   ███    ███                  
          ███         ███    █▀    ███    █▀  ███▌ ███    ███ ███   ███   ███    █▀                   
          ███        ▄███▄▄▄      ▄███        ███▌ ███    ███ ███   ███   ███                         
          ███       ▀▀███▀▀▀     ▀▀███ ████▄  ███▌ ███    ███ ███   ███ ▀███████████                  
          ███         ███    █▄    ███    ███ ███  ███    ███ ███   ███          ███                  
          ███▌    ▄   ███    ███   ███    ███ ███  ███    ███ ███   ███    ▄█    ███                  
          █████▄▄██   ██████████   ████████▀  █▀    ▀██████▀   ▀█   █▀   ▄████████▀                   
          ▀                                                                                           
 ▄██████▄     ▄████████         ▄████████    ▄████████  ▄████████    ▄████████ ███▄▄▄▄      ▄████████ 
███    ███   ███    ███        ███    ███   ███    ███ ███    ███   ███    ███ ███▀▀▀██▄   ███    ███ 
███    ███   ███    █▀         ███    ███   ███    ███ ███    █▀    ███    ███ ███   ███   ███    ███ 
███    ███  ▄███▄▄▄            ███    ███  ▄███▄▄▄▄██▀ ███          ███    ███ ███   ███   ███    ███ 
███    ███ ▀▀███▀▀▀          ▀███████████ ▀▀███▀▀▀▀▀   ███        ▀███████████ ███   ███ ▀███████████ 
███    ███   ███               ███    ███ ▀███████████ ███    █▄    ███    ███ ███   ███   ███    ███ 
███    ███   ███               ███    ███   ███    ███ ███    ███   ███    ███ ███   ███   ███    ███ 
 ▀██████▀    ███               ███    █▀    ███    ███ ████████▀    ███    █▀   ▀█   █▀    ███    █▀  
                                            ███    ███                                                

*/

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";

// @author Genesis Dragons ali and neek

contract LegionsOfArcana is
    ERC721,
    Ownable,
    ReentrancyGuard,
    PaymentSplitter
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
    bytes32 public freeRoot;

    address proxyRegistryAddress;

    uint256 public maxSupply = 3000;

    string public baseURI;
    string public notRevealedUri = "ipfs://QmcikpV4SwacoURjRbhxiS5gQoNrt2LgEYXYrowXmjKFTR/0";

    bool public paused = false;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;
    bool public freesaleM = true;

    uint256 presaleAmountLimit = 3;
    uint256 freeAmountLimit = 2;
    mapping(address => uint256) public _presaleClaimed;
    mapping(address => uint256) public _freeClaimed;

    uint256 _price = 80000000000000000; // 0.08 ETH
    uint256 _freePrice = 0;
    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [16, 14, 14, 14, 14, 14, 14]; // Deployer + 6 PEOPLE IN THE TEAM
    address[] private _team = [
        0x32536039434Ed2A3DB192Acb7706578C497A29b5, // Deployer Account gets 16% of the total revenue
        0x795f8fcF04726557f126799545Fc4B0d1C49b058, // Dev Account gets 14% of the total revenue
        0x43eD8C36C4f0AC62461a67C634ceFF906d46cA29, // Dev Account gets 14% of the total revenue
        0xf9117ae62fC43605b12B98C527bAc262BB517461, // Artist Account gets 14% of the total revenue
        0xaf29ab7418516cc3F22E609dC783D75864AB545a, // Artist Account gets 14% of the total revenue
        0xB3Af24e9507ee048D014fF154E8C2663Ef31257F, // Team Account gets 14% of the total revenue
        0xA3442905c5C0dE9D29E2cd660C859E91d7b5226e // Team Account gets 14% of the total revenue
    ];

    constructor(string memory uri, bytes32 merkleroot, bytes32 freeMerkleRoot, address _proxyRegistryAddress)
        ERC721("LegionsOfArcana", "DRAGONS")
        PaymentSplitter(_team, _teamShares) // Split the payment based on the teamshares percentages
        ReentrancyGuard() // A modifier that can prevent reentrancy during certain functions
    {
        root = merkleroot;
        freeRoot = freeMerkleRoot;
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

     function setFreeMerkleRoot(bytes32 freeMerkleRoot)
    onlyOwner
    public
    {
        freeRoot = freeMerkleRoot;
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

    modifier isValidFreeMerkleProof(bytes32[] calldata _proof) {
         require(MerkleProof.verify(
            _proof,
            freeRoot,
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

        function toggleFreeSale() public onlyOwner {
        freesaleM = !freesaleM;
    }


    function presaleMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "LegionsOfArcana: Not allowed");
        require(presaleM,                       "LegionsOfArcana: Presale is OFF");
        require(!paused,                        "LegionsOfArcana: Contract is paused");
        require(
            _amount <= presaleAmountLimit,      "LegionsOfArcana: You can not mint so much tokens");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "LegionsOfArcana: You can not mint so much tokens");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "LegionsOfArcana: max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "LegionsOfArcana: Not enough ethers sent"
        );

        _presaleClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function freeMint(address account, uint256 _amount, bytes32[] calldata _proof)
    external
    payable
    isValidFreeMerkleProof(_proof)
    onlyAccounts
    {
        require(msg.sender == account,          "LegionsOfArcana: Not allowed");
        require(!paused,                        "LegionsOfArcana: Contract is paused");
        require(freesaleM,                       "LegionsOfArcana: Presale is OFF");
        require(
            _amount <= freeAmountLimit,      "LegionsOfArcana: You can not mint so much tokens");
        require(
            _freeClaimed[msg.sender] + _amount <= freeAmountLimit,  "LegionsOfArcana: Only 2 Free Mints per Genesis Owner");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "LegionsOfArcana: max supply exceeded"
        );
        require(
            _freePrice * _amount <= msg.value,
            "LegionsOfArcana: Not enough ethers sent"
        );

        _freeClaimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function publicSaleMint(uint256 _amount)
    external
    payable
    onlyAccounts
    {
        require(publicM, "LegionsOfArcana: PublicSale is OFF");
        require(!paused, "LegionsOfArcana: Contract is paused");
        require(_amount > 0, "LegionsOfArcana: zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "LegionsOfArcana: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "LegionsOfArcana: Not enough ethers sent"
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
                        tokenId.toString()
                    )
                )
                : "";
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function totalSupply() public view returns (uint) {
        return _tokenIds.current();
    }
    
     function withdraw_all() public onlyOwner{
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
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
