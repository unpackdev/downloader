// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
Froot Invaders

BADFROOT x SPYR

  
                        _,semm                           ____
                       ]#bQ_ _@                         ;#"77@Mp
                       _j%#Q_ _@_                      ]b_ _###b
                          _7@p _@_                    ]b _,#W,_
                            _7N_j#_                  ,#__#C_
                              _@,@Mmmp_     __,;JJ,p,#_;#_
                          _;e#W7||__,j7755577|j'___'|\_#m,_
                       _,#Mh_                          _j7%#m _
                      ,#M_                  ____.__       _wj5#m_
                     ]#"_sMQQ@Wg_        _s########%Q_      '%p7#m_
                    ]#b.#s######m_     _############m%p      _3b3#b_
                   _@b_#@#########_  _.##############Q@p      _3b@#p
                   _#b_b###########,.b################db       _#j#b
                   _#b_b###########@@@################jb       _#j#b
                    @#_@]###########@@################@_       _\##'
                    _@b'p@########@^@@###############]b        _@#b
                     ^@p__5######b_ 'j##############}b        _##b
                      _@m_ _|37T_     j@###########^'        ,##^
                       _7#p      4jN   _|7W####MT"          @#b_
                         _%m_      _                      _@#b
                         __@#,   %WW-                     ]#mp_
                    _,asm##@W#Q                          ,#Wm##mmgp__
               _s##WjM5W,___|]@b                        ;M}_____#77Q7%#m,_
             ,##7_  @p;sb    _7*74NmwessssssssssmempKDkc^._    _7WmW  _j%#p_
            _#b_     __     _#55W_  _____'';pp~'___   _@C77m            j3#b
            _@m_            ]b__]b       _#'_jb       _@,_,#           _,##_
             _|7Wmp__       _j|||        _%msMb        _,|_       __,s#b}_
                __j7@##mmgp,__ _                             _.s##W2|_
                    _'|@Nh\CC4/|jCb27"YMMMmmmeym=mMV^^      /z@#b_
                       _|7@MQC/_\_Cf_,}ybCC_^/.`\____   _ am#M|_
                          _~j7W##MmmJp,, _____ __,,Jsm###W7|_
                                __|j7777777755777T77|j'_



---

# BADFROOT TEAM

## Badfroot (Jack Davidson)
Artist
* Website: https://badfroot.com
* Twitter: @theBadfroot


## Jeff Sarris
Brand/Strategy/Developer
* Website: https://SPYR.me
* Twitter: @jeffSARRIS

---

# BUILDING YOUR OWN NFT PROJECT?

## Need someone to handle the tech?
Work with Jeff at https://RYPS.co

## Need help developing your brand and business?
Work with Jeff at https://SPYR.me

---

Alpha  =^.^=

*/

import "./MerkleProof.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./ERC721AQueryable.sol";


contract FrootInvaders is ERC721AQueryable, Ownable, ReentrancyGuard {
    string  public baseURI;
    
    address public proxyRegistryAddress;

    address public badfroot;
    address public spyr;

    bytes32 public immortalsMerkleRoot;

    uint256 public constant MAX_SUPPLY = 999;
    uint256 public constant MAX_PER_TX = 25;

    uint256 public immortalsPrice = 0.003 ether;
    uint256 public publicPrice = 0.005 ether;

    bool public immortalsSaleActive;
    bool public publicSaleActive;

    mapping(address => bool) public projectProxy;

    constructor(string memory _setBaseURI,address _proxyRegistryAddress,address _badfroot,address _spyr)
        ERC721A("Froot Invaders", "FROOTINVADERS") {
        
        // Init Constants
        baseURI = _setBaseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        badfroot = _badfroot;
        spyr = _spyr;
    }
    

    // Modifiers
    modifier onlyImmortalsActive() {
        require(immortalsSaleActive, "Immortals sale is not live!");
        _;
    }

    modifier onlyPublicActive() {
        require(publicSaleActive, "Public sale is not live!");
        _;
    }
    // END Modifiers


    // Set Functions
    function setBaseURI(string memory _setBaseURI) public onlyOwner {
        baseURI = _setBaseURI;
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setPayoutAddresses(address _badfroot,address _spyr) external onlyOwner {
        badfroot = _badfroot;
        spyr = _spyr;
    }
    // END Set Functions


    // Merkle Functions
    function setImmortalsMerkleRoot(bytes32 _immortalsMerkleRoot) external onlyOwner {
        immortalsMerkleRoot = _immortalsMerkleRoot;
    }
    // END Merkle Functions


    // Mint Functions
    function immortalsMint(uint256 _quantity, bytes32[] calldata _proof) external payable onlyImmortalsActive nonReentrant() {
        require(MerkleProof.verify(_proof, immortalsMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Sorry, you're not an Immortal!");
        require(_quantity <= MAX_PER_TX, "Sorry! You can only mint a maximum of 25 Frootlings per transaction!");
        require(immortalsPrice * _quantity == msg.value, "Wrong amount of ETH sent");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");

        _safeMint(msg.sender, _quantity);
    }

    function publicMint(uint256 _quantity) external payable onlyPublicActive nonReentrant() {
        require(_quantity <= MAX_PER_TX, "Sorry! You can only mint a maximum of 25 Frootlings per transaction!");
        require(publicPrice * _quantity == msg.value, "Wrong amount of ETH sent");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");

        _safeMint( msg.sender, _quantity);
    } 

    // Dev minting function 
    function devMint(address _to, uint256 _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Exceeds maximum supply");
        _safeMint(_to, _quantity);
    }
    // END Mint Functions


    // Toggle Sale
    function toggleImmortalsSale() external onlyOwner {
        immortalsSaleActive = !immortalsSaleActive;
    }

    function togglePublicSale() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }
    // END Toggle Sale


    // Override start token in ERC721A
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }


    // Override _baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    // Withdraw Funds to Badfroot and SPYR
    function withdraw() public payable onlyOwner {
        uint256 _balance = address(this).balance;
        uint256 percent = _balance / 100;
        
        // 50% to Badfroot (Jack Davidson)
        require(payable(badfroot).send(percent * 50));

        // 50% to SPYR (Jeff Sarris)
        require(payable(spyr).send(percent * 50));
    }


    // Proxy Functions
    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function flipProxyState(address _proxyAddress) public onlyOwner {
        projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
    }

    // OpenSea Secondary Contract Approval - Removes initial approval gas fee from sellers
    // Allow future contract approval
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator || projectProxy[_operator]) return true;
        return super.isApprovedForAll(_owner, _operator);
    }
    // END Proxy Functions

}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}