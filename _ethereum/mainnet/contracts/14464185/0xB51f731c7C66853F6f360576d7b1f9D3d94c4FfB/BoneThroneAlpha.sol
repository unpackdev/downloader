// SPDX-License-Identifier: MIT
                                        
//                                       
//                        B█▀ █▌      ,▄▄▄▄▄▄▄▄▄▄▄▄▄i     ╓▓█▐▀█s
//                       ╫█.▐▄ ▀██▓▄╔██▀▀▀▀▀▀▀▀▀▀▀▀▀██,▄▓█▀▀ ║⌐╙█╦
//                      ╔█¬  ▀█▄  '███              ╙███   ▄█▀  ▐█
//                      ╫█    ██m  ██▀      ▐█       ▀█▌  ▐██    █
//                      ╫██▄▐▓█████▀i       ▄█▄       l▀██████l▄██
//                      .▓█`███▀ `           ▄           ` ▀██▌╙█▌
//                       █▌▄█▀▀,,e▀▀▓▄       █       ▄▀▀h⌡,,▀██▄██
//                       ]█▀i██████▄ ╙▌     ▐█      █',▄██████r██
//                       ╫█▐█r╙██████▄╙⌐    ▐█⌐    ▐░▄██████a║█ █▌
//                       ╢█▐█║▄▐█████▌             `:▓█████▄█▐█ █▌
//        ╔▓▀▀▀▓▄,       ╨█▄██▀██████▌               ███████▀█▀▄█╛        ,╦▓▀▀▀▓╥
//       ╫█      █⌐       ╫█▄▀█▄▀▀▀▀███▓█▄▄▄  ,▄▄▄█▓███▀▀▀▀▄█▀██h         ▓▀"░░`'▀▌
//       █       ╙█,     ╔██▀█▄║████▀░╓▀╓▄█▄██▄██▄╙▀░░▀████░▄█▀██       ,▓▀       █
//       █        `▀▀Φ▄╓ ╫█m░║█▌▄█▀     ██▀████▀███e `░»▀█▄██n ║█▌  ,▄▄Φ▀i         █
//     ╓█             `░r╠██▐░▓███     ▓▐█  ███  ██▐▌ ╚r░╙███▌a"██▀▀░h"            █╕
//     ╫█              `╟██║░███░░▄   ███▄  ██▌  ███▌  ║▄░▐██▌  ██░"`              ║▒
//     ╙╫▓▄▄▄▄▄▓▀▀#▄▄,  "█▌║ ██▀▐█▌    █████████████  ii██╙██▌ m██     ▄▄▄▀▀▓▄▄▄▄▄▄▀╛
//       `""``      `╙▀▀#╫█' ╙█░█░▐█▀▓⌂,┘╙└¬▐█░└╙╙└ ▄▓▀█ ╙█║█ ╙╓█▌▄▄▀▀╨`      `""""
//                       '██  ╙▌█H,▌░ ██*-▄¿"█  µw*█▌ ░█ ]██   ██`
//                        ]██║ ██▄██░ ║▌  ▌ d█¿  ⌐ █▌ ░██║█▌▐▄██▄
//       ,╓╦▄▄╥      ,▄▄Φ▀▀╨██▌╙▌▀⌐▀▄ ▌╘ ▐▌ ██▌ ▐▌ ┘▌:║▌█▀█¬███░»▀▀Φ▄▄       ,╥╦╥╓
//      é▓▀   ╙▀▀Φ#▀▀╙─"┴"`  ▀█▄╙▀▌ ▀▄▌  ╜ ▐███^ ╟⌐ ▓▄▀ █▀-▄█▀        ╙▀▀▄▄K▀▀╙╙╠▀▓
//      ╫▌                   ╓╫█▄ `▀▀▀▀▄#▀æ▀███W#▀▄▄▀▀K▀ ,▄█▓▄¿                   ▐▌
//      ╚█              ╓▄#▀▀" ╨██▄         ╙█       , ,▄██╨ `╙▀▀▄▄¿              ▓▀
//       ╙▀▄        ╓#▀▀"       ╙███▄█,    Φ███M    ╔█▄███`        "▀▀╦▄        ▄▓╩
//         └█      ╓█`            "▀███▄▄µ≈╔██▌≈╓╔▄▄███▀`              █▄      ║M
//          ╫▓▄  ╓▄▌`                `"▀▀▀▀█████▀▀▀▀"                   ▀▄¿  ,▄▌
//           "╨▀▀╩"                                                      "╩▀▀╩^
                                                                    


pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./PaymentSplitter.sol";
import "./MerkleProof.sol";
import "./Counters.sol";
import "./Strings.sol";

// @creator:  Sekulab Studio
// @website:  https://bonethrone.io

contract BoneThroneAlpha is 
    ERC721,
    Ownable, 
    ReentrancyGuard, 
    PaymentSplitter 
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    bytes32 public root;
        
    address proxyRegistryAddress;

    uint256 public maxSupply = 10000;

    string public baseURI; 
    string public notRevealedUri = "ipfs://QmbeJJwNM84TkVsHtTE9sQvTUdVSt2rgXP3kmgheVkPDFZ/hidden.json";
    string public baseExtension = ".json";

    bool public paused = true;
    bool public revealed = false;
    bool public presaleM = false;
    bool public publicM = false;

    uint256 presaleAmountLimit = 3;
    mapping(address => uint256) public _presaleClaimed;

    uint256 AmountLimit = 20;
    mapping(address => uint256) public _Claimed;
    
    uint256 _price = 0.1 ether; // Public Price
    uint256 _preprice = 0.07 ether; // Presale Price

    Counters.Counter private _tokenIds;

    uint256[] private _teamShares = [30, 30, 30, 5, 5]; // 4 PEOPLE IN THE TEAM AND OWNER WALLET
    address[] private _team = [
        0x56E63E7623665247ab8d57FaaE23D5b819c03F82, // HKA Account gets 30% of the total revenue
        0x0431f7629204d3CD7A71D7BA8Ef654063AE06b6E, // KARUGU Account gets 30% of the total revenue
        0xb16ee612202174428C43A999E6A110bCDDce3D9C, // SGA Account gets 30% of the total revenue
        0x33608058672dd98FF671BFA7ea7B1FebD52D4ac0, // ICE COFFEE Account gets 5% of the total revenue
        0xDF945Aa571d884C51D9eF5E00bF9cba9e633c5DC //  Main Account gets 5% of the total revenue
    ];

    constructor(string memory uri, bytes32 merkleroot, address _proxyRegistryAddress)
        ERC721("BoneThroneMrAlpha", "BOTMA")
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
        require(msg.sender == account,          "BoneThroneAlpha: Not allowed");
        require(presaleM,                       "BoneThroneAlpha: Presale is OFF");
        require(!paused,                        "BoneThroneAlpha: Contract is paused");
        require(
            _amount <= presaleAmountLimit,      "BoneThroneAlpha: You can't mint so much tokens");
        require(
            _presaleClaimed[msg.sender] + _amount <= presaleAmountLimit,  "BoneThroneAlpha: You can't mint so much tokens");


        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "BoneThroneAlpha: max supply exceeded"
        );
        require(
            _preprice * _amount <= msg.value,
            "BoneThroneAlpha: Not enough ethers sent"
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
        require(publicM,     "BoneThroneAlpha: PublicSale is OFF");
        require(!paused,     "BoneThroneAlpha: Contract is paused");
         require(
            _amount <= AmountLimit,      "BoneThroneAlpha: You can't mint so much tokens");
        require(
            _Claimed[msg.sender] + _amount <= AmountLimit,  "BoneThroneAlpha: You can't mint so much tokens");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "BoneThroneAlpha: Max supply exceeded"
        );
        require(
            _price * _amount <= msg.value,
            "BoneThroneAlpha: Not enough ethers sent"
        );
        
        _Claimed[msg.sender] += _amount;

        for (uint i = 0; i < _amount; i++) {
            mintInternal();
        }
    }

    function OwnerMint(uint256 _amount) 
    external 
    onlyOwner
    {
        
        require(_amount > 0, "BoneThroneAlpha: zero amount");

        uint current = _tokenIds.current();

        require(
            current + _amount <= maxSupply,
            "BoneThroneAlpha: Max supply exceeded"
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



