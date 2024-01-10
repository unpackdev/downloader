/*
TTTTTTTTTTTTTTTTTTTTTTTUUUUUUUU     UUUUUUUUNNNNNNNN        NNNNNNNNEEEEEEEEEEEEEEEEEEEEEE   SSSSSSSSSSSSSSS                                                 
T:::::::::::::::::::::TU::::::U     U::::::UN:::::::N       N::::::NE::::::::::::::::::::E SS:::::::::::::::S                                                
T:::::::::::::::::::::TU::::::U     U::::::UN::::::::N      N::::::NE::::::::::::::::::::ES:::::SSSSSS::::::S                                                
T:::::TT:::::::TT:::::TUU:::::U     U:::::UUN:::::::::N     N::::::NEE::::::EEEEEEEEE::::ES:::::S     SSSSSSS                                                
TTTTTT  T:::::T  TTTTTT U:::::U     U:::::U N::::::::::N    N::::::N  E:::::E       EEEEEES:::::S                                                            
        T:::::T         U:::::D     D:::::U N:::::::::::N   N::::::N  E:::::E             S:::::S                                                            
        T:::::T         U:::::D     D:::::U N:::::::N::::N  N::::::N  E::::::EEEEEEEEEE    S::::SSSS                                                         
        T:::::T         U:::::D     D:::::U N::::::N N::::N N::::::N  E:::::::::::::::E     SS::::::SSSSS                                                    
        T:::::T         U:::::D     D:::::U N::::::N  N::::N:::::::N  E:::::::::::::::E       SSS::::::::SS                                                  
        T:::::T         U:::::D     D:::::U N::::::N   N:::::::::::N  E::::::EEEEEEEEEE          SSSSSS::::S                                                 
        T:::::T         U:::::D     D:::::U N::::::N    N::::::::::N  E:::::E                         S:::::S                                                
        T:::::T         U::::::U   U::::::U N::::::N     N:::::::::N  E:::::E       EEEEEE            S:::::S                                                
      TT:::::::TT       U:::::::UUU:::::::U N::::::N      N::::::::NEE::::::EEEEEEEE:::::ESSSSSSS     S:::::S                                                
      T:::::::::T        UU:::::::::::::UU  N::::::N       N:::::::NE::::::::::::::::::::ES::::::SSSSSS:::::S                                                
      T:::::::::T          UU:::::::::UU    N::::::N        N::::::NE::::::::::::::::::::ES:::::::::::::::SS                                                 
      TTTTTTTTTTT            UUUUUUUUU      NNNNNNNN         NNNNNNNEEEEEEEEEEEEEEEEEEEEEE SSSSSSSSSSSSSSS                                                   
MMMMMMMM               MMMMMMMM                                                         PPPPPPPPPPPPPPPPP                                                    
M:::::::M             M:::::::M                                                         P::::::::::::::::P                                                   
M::::::::M           M::::::::M                                                         P::::::PPPPPP:::::P                                                  
M:::::::::M         M:::::::::M                                                         PP:::::P     P:::::P                                                 
M::::::::::M       M::::::::::M   ooooooooooo      ooooooooooo   nnnn  nnnnnnnn           P::::P     P:::::Paaaaaaaaaaaaa      ssssssssss       ssssssssss   
M:::::::::::M     M:::::::::::M oo:::::::::::oo  oo:::::::::::oo n:::nn::::::::nn         P::::P     P:::::Pa::::::::::::a   ss::::::::::s    ss::::::::::s  
M:::::::M::::M   M::::M:::::::Mo:::::::::::::::oo:::::::::::::::on::::::::::::::nn        P::::PPPPPP:::::P aaaaaaaaa:::::ass:::::::::::::s ss:::::::::::::s 
M::::::M M::::M M::::M M::::::Mo:::::ooooo:::::oo:::::ooooo:::::onn:::::::::::::::n       P:::::::::::::PP           a::::as::::::ssss:::::ss::::::ssss:::::s
M::::::M  M::::M::::M  M::::::Mo::::o     o::::oo::::o     o::::o  n:::::nnnn:::::n       P::::PPPPPPPPP      aaaaaaa:::::a s:::::s  ssssss  s:::::s  ssssss 
M::::::M   M:::::::M   M::::::Mo::::o     o::::oo::::o     o::::o  n::::n    n::::n       P::::P            aa::::::::::::a   s::::::s         s::::::s      
M::::::M    M:::::M    M::::::Mo::::o     o::::oo::::o     o::::o  n::::n    n::::n       P::::P           a::::aaaa::::::a      s::::::s         s::::::s   
M::::::M     MMMMM     M::::::Mo::::o     o::::oo::::o     o::::o  n::::n    n::::n       P::::P          a::::a    a:::::assssss   s:::::s ssssss   s:::::s 
M::::::M               M::::::Mo:::::ooooo:::::oo:::::ooooo:::::o  n::::n    n::::n     PP::::::PP        a::::a    a:::::as:::::ssss::::::ss:::::ssss::::::s
M::::::M               M::::::Mo:::::::::::::::oo:::::::::::::::o  n::::n    n::::n     P::::::::P        a:::::aaaa::::::as::::::::::::::s s::::::::::::::s 
M::::::M               M::::::M oo:::::::::::oo  oo:::::::::::oo   n::::n    n::::n     P::::::::P         a::::::::::aa:::as:::::::::::ss   s:::::::::::ss  
MMMMMMMM               MMMMMMMM   ooooooooooo      ooooooooooo     nnnnnn    nnnnnn     PPPPPPPPPP          aaaaaaaaaa  aaaa sssssssssss      sssssssssss                       
                                                                                
An 0nyX Labs Contract
0nyXLabs.io
Development by @White_Oak_Kong

ERC721A Implementation with Merkle Tree Allow List. 

*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./Strings.sol";


contract MoonPass is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string private baseURI;

    uint256 public constant MAX_PER_TXN = 10;
    uint256 public constant MAX_PER_WALLET_PRESALE = 3;
    uint256 public maxTunes;

    uint256 public SALE_PRICE = 0.1 ether;
    bool public isPublicSaleActive;

    uint256 public maxPreSaleTunes;
    bytes32 public preSaleMerkleRoot;
    bool public isPreSaleActive;

    mapping(address => uint256) public mintCounts;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier publicSaleActive() {
        require(isPublicSaleActive, "Public sale is not open");
        _;
    }

    modifier preSaleActive() {
        require(isPreSaleActive, "Presale is not open");
        _;
    }

    modifier canMintTunes(uint256 quantity) {
        require(
            totalSupply() + quantity <= maxTunes,
            "Not enough tunes remaining to mint"
        );
        _;
    }

    modifier isCorrectPayment(uint256 price, uint256 quantity) {
        require(
            price * quantity == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

        modifier maxTxn(uint256 quantity) {
        require(
            quantity <= MAX_PER_TXN,
            "Max tunes to mint is 10"
        );
        _;
    }


    constructor(
        uint256 _maxTunes,
        uint256 _maxPreSaleTunes
    ) ERC721A("Tunes Moon Pass", "TUNES") {
        maxTunes = _maxTunes;
        maxPreSaleTunes = _maxPreSaleTunes;
    }

    // ---  PUBLIC MINTING FUNCTIONS ---

    // mint allows for regular minting while the supply does not exceed maxTunes.
    function mint(uint256 quantity)
        external
        payable
        nonReentrant
        isCorrectPayment(SALE_PRICE, quantity)
        publicSaleActive
        canMintTunes(quantity)
        maxTxn(quantity)
    {
            _safeMint(msg.sender, quantity);

    }

    // mintPreSale allows for minting by allowed addresses during the pre-sale.
    function mintPreSale(
        uint8 quantity,
        bytes32[] calldata merkleProof)
        external
        payable
        nonReentrant
        preSaleActive
        canMintTunes(quantity)
        isCorrectPayment(SALE_PRICE, quantity)
        isValidMerkleProof(merkleProof, preSaleMerkleRoot)
    {
        uint256 numAlreadyMinted = mintCounts[msg.sender];

        require(
            numAlreadyMinted + quantity <= MAX_PER_WALLET_PRESALE,
            "Max tunes to mint in Presale is one"
        );

        require(
            totalSupply() + quantity <= maxPreSaleTunes,
            "Not enough tunes remaining to mint"
        );

        mintCounts[msg.sender] = numAlreadyMinted + quantity;

            _safeMint(msg.sender, quantity);
    }

    // -- OWNER ONLY MINT --
    function ownerMint(uint256 quantity)
        external
        nonReentrant
        onlyOwner
        canMintTunes(quantity)
    {
            _safeMint(msg.sender, quantity);

    }

    // --- READ-ONLY FUNCTIONS ---

    // getBaseURI returns the baseURI hash for collection metadata.
    function getBaseURI() external view returns (string memory) {
        return baseURI;
    }


    // -- ADMIN FUNCTIONS --

    // setBaseURI sets the base URI for token metadata.
    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    // setIsPublicSaleActive toggles the functionality of the public minting function.
    function setIsPublicSaleActive(bool _isPublicSaleActive)
        external
        onlyOwner
    {
        isPublicSaleActive = _isPublicSaleActive;
    }

    // updatePrice is an emergency function to adjust the price of Moon Pass.
    function updatePrice(uint256 _price) external onlyOwner {
        SALE_PRICE = _price;
    }

    // capSupply is an emergency function to reduce the maximum supply of Moon Pass.
    function capSupply(uint256 _supply) external onlyOwner {
        require(_supply > totalSupply(), "cannot reduce maximum supply below current count.");
        require(_supply < maxTunes, "cannot increase the maximum supply.");
        maxTunes = _supply;
    }

    // setIsPreSaleActive toggles the functionality of the presale minting function.
    function setIsPreSaleActive(bool _isPreSaleActive)
        external
        onlyOwner
    {
        isPreSaleActive = _isPreSaleActive;
    }

    // setPresaleListMerkleRoot sets the merkle root for presale allowed addresses.
    function setPresaleListMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        preSaleMerkleRoot = merkleRoot;
    }

    // withdraw allows for the withdraw of all ETH to the owner wallet.
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // withdrawTokens allow for the withdrawl of any ERC20 token from contract.
    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return
            string(abi.encodePacked(baseURI, "/", tokenId.toString()));
    }

}