/*
 .S    sSSs   .S    S.   sdSS_SSSSSSbs   .S_SSSs     .S_sSSs    
.SS   d%%SP  .SS    SS.  YSSS~S%SSSSSP  .SS~SSSSS   .SS~YS%%b   
S%S  d%S'    S%S    S%S       S%S       S%S   SSSS  S%S   `S%b  
S%S  S%|     S%S    S%S       S%S       S%S    S%S  S%S    S%S  
S&S  S&S     S%S SSSS%S       S&S       S%S SSSS%S  S%S    d*S  
S&S  Y&Ss    S&S  SSS&S       S&S       S&S  SSS%S  S&S   .S*S  
S&S  `S&&S   S&S    S&S       S&S       S&S    S&S  S&S_sdSSS   
S&S    `S*S  S&S    S&S       S&S       S&S    S&S  S&S~YSY%b   
S*S     l*S  S*S    S*S       S*S       S*S    S&S  S*S   `S%b  
S*S    .S*P  S*S    S*S       S*S       S*S    S*S  S*S    S%S  
S*S  sSS*S   S*S    S*S       S*S       S*S    S*S  S*S    S&S  
S*S  YSS'    SSS    S*S       S*S       SSS    S*S  S*S    SSS  
SP                  SP        SP               SP   SP          
Y                   Y         Y                Y    Y           
                                                                
            S.       .S_SSSs     .S_SSSs      sSSs              
            SS.     .SS~SSSSS   .SS~SSSSS    d%%SP              
            S%S     S%S   SSSS  S%S   SSSS  d%S'                
            S%S     S%S    S%S  S%S    S%S  S%|                 
            S&S     S%S SSSS%S  S%S SSSS%P  S&S                 
            S&S     S&S  SSS%S  S&S  SSSY   Y&Ss                
            S&S     S&S    S&S  S&S    S&S  `S&&S               
            S&S     S&S    S&S  S&S    S&S    `S*S              
            S*b     S*S    S&S  S*S    S&S     l*S              
            S*S.    S*S    S*S  S*S    S*S    .S*P              
             SSSbs  S*S    S*S  S*S SSSSP   sSS*S               
              YSSP  SSS    S*S  S*S  SSY    YSS'                
                           SP   SP                              
                           Y    Y                               
                                                             
*/
// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Strings.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";


contract BattleAnglesNFT is ERC721URIStorage, Ownable, ReentrancyGuard{
    string private _collectionURI;
    string public baseURI;

  
    bool public pausedwl = true;
    bool public pausedgift = true;
    bool public pausedpublic = true;

 
    uint256 public maxGiftMintId = 380;
    uint256 public giftMintId = 1;


    uint256 public maxWhitelistId = 3333;
    uint256 public whitelistId = 381;
    uint256 public constant WHITELIST_SALE_PRICE = 0.2 ether;

    uint256 public maxPublicMint = 3333;
    uint256 public publicMintId = 1881;
    uint256 public constant PUBLIC_SALE_PRICE = 0.2 ether;

    // used to validate whitelists
    bytes32 public giftMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    // keep track of those on whitelist who have claimed their NFT
    mapping(address => bool) public giftclaimed;
    mapping(address => bool) public wlclaimed;

    constructor(string memory _baseURI, string memory collectionURI) ERC721("BattleAngles NFT", "BANFT") {
        setBaseURI(_baseURI);
        setCollectionURI(collectionURI);
    }

    /**
     * @dev validates merkleProof
     */
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

    modifier isCorrectPayment(uint256 price, uint256 numberOfTokens) {
        require(
            price * numberOfTokens == msg.value,
            "Incorrect ETH value sent"
        );
        _;
    }

    modifier canMint(uint256 numberOfTokens) {
        require(
            publicMintId + numberOfTokens <= maxPublicMint,
            "Not enough tokens remaining to mint"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    /**
    * @dev 
    */
    function mintGift(
        bytes32[] calldata merkleProof
    )
        public
        isValidMerkleProof(merkleProof, giftMerkleRoot)
        nonReentrant
    {
      require(!pausedgift);  
      require(giftMintId <= maxGiftMintId);
      require(!giftclaimed[msg.sender], "NFT is already claimed by this wallet");
      _mint(msg.sender, giftMintId);
      giftMintId++;
      giftclaimed[msg.sender] = true;
    }

    /**
    * @dev 
    */
    function mintWhitelist(
      bytes32[] calldata merkleProof,
      uint256 numberOfTokens
    )
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(WHITELIST_SALE_PRICE, numberOfTokens)
        nonReentrant
    {
        require(!pausedwl);
        require(numberOfTokens <= 3);
        require(whitelistId <= maxWhitelistId, "minted the maximum # of whitelist tokens");
        require(!wlclaimed[msg.sender], "NFT is already claimed by this wallet"); 
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(msg.sender, whitelistId);
            whitelistId++;
        }
        wlclaimed[msg.sender] = true;
    }

    /**
    * @dev 
    */
    function publicMint(
      uint256 numberOfTokens
    )
        public
        payable
        isCorrectPayment(PUBLIC_SALE_PRICE, numberOfTokens)
        canMint(numberOfTokens)
        nonReentrant
    {
       require(!pausedpublic);
       for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(msg.sender, publicMintId);
            publicMintId++;
        }

    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
    {
      require(_exists(tokenId), "ERC721Metadata: query for nonexistent token");
      return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    /**
    * @dev collection URI for marketplace display
    */
    function contractURI() public view returns (string memory) {
        return _collectionURI;
    }


    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setBaseURI(string memory _baseURI) public onlyOwner {
      baseURI = _baseURI;
    }

    /**
    * @dev set collection URI for marketplace display
    */
    function setCollectionURI(string memory collectionURI) public onlyOwner {
        _collectionURI = collectionURI;
    }

    function setGiftMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        giftMerkleRoot = merkleRoot;
    }

    function setWhitelistMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        whitelistMerkleRoot = merkleRoot;
    }

    /**
     * @dev withdraw funds for to specified account
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function pausepublic(bool _state) public onlyOwner {
        pausedpublic = _state;
    }

    function pausewl(bool _state) public onlyOwner {
        pausedwl = _state;
    }

    function pausegift(bool _state) public onlyOwner {
        pausedgift = _state;
    }

     function setwlId(uint256 _newmaxMintAmount) public onlyOwner {
        whitelistId = _newmaxMintAmount;
    }

      function setMaxWlId(uint256 _newmaxMintAmount) public onlyOwner {
        maxWhitelistId = _newmaxMintAmount;
    }
    
    function setpublicId(uint256 _newmaxMintAmount) public onlyOwner {
        publicMintId = _newmaxMintAmount;
    }

    function setMaxPublicId(uint256 _newmaxMintAmount) public onlyOwner {
        maxPublicMint = _newmaxMintAmount;
    }

}
