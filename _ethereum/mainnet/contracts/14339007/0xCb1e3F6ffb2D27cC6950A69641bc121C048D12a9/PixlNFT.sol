// SPDX-License-Identifier: MIT
// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
pragma solidity ^0.8.1;

import "./IERC20.sol";
import "./Strings.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";


contract PixlNFT is ERC721URIStorage, Ownable, ReentrancyGuard{
    string private _collectionURI;
    string public baseURI;

    /**
      * team mint are from 0-24 (25 max supply)
      * whitelist are from 25-999 (974 max supply)
      * public mint from 1000 - 9998 (8998 max supply)
    **/

    uint256 immutable public maxGiftMintId = 24;
    uint256 public giftMintId = 0;

    uint256 immutable public maxWhitelistId = 999;
    uint256 public whitelistId = 25;
    uint256 public constant WHITELIST_SALE_PRICE = 0.01 ether;

    uint256 immutable public maxPublicMint = 9998;
    uint256 public publicMintId = 1000;
    uint256 public constant PUBLIC_SALE_PRICE = 0.08 ether;

    // used to validate whitelists
    bytes32 public giftMerkleRoot;
    bytes32 public whitelistMerkleRoot;

    // keep track of those on whitelist who have claimed their NFT
    mapping(address => bool) public claimed;

    constructor(string memory _baseURI, string memory collectionURI) ERC721("Pixl Genesis Series", "Pixl") {
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
        require(saleIsActive, "Sale not active");

        require(
            publicMintId + numberOfTokens <= maxPublicMint,
            "Not enough tokens remaining to mint"
        );
        _;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    /**
    * @dev mints 1 token per whitelisted gift address
    * Max supply: 25 (token ids: 0-24)
    * does not charge a fee
    */
    function mintGift(
        bytes32[] calldata merkleProof
    )
        public
        isValidMerkleProof(merkleProof, giftMerkleRoot)
        nonReentrant
    {
      require(giftMintId <= maxGiftMintId);
      require(!claimed[msg.sender], "NFT is already claimed by this wallet");
      _mint(msg.sender, giftMintId);
      giftMintId++;
    }

    /**
    * @dev mints 1 token per whitelisted address
    * Max supply: 974 (token ids: 25-999)
    * charges a fee
    */
    function mintWhitelist(
      bytes32[] calldata merkleProof
    )
        public
        payable
        isValidMerkleProof(merkleProof, whitelistMerkleRoot)
        isCorrectPayment(WHITELIST_SALE_PRICE, 1)
        nonReentrant
    {
        require(whitelistId <= maxWhitelistId, "minted the maximum # of whitelist tokens");
        require(!claimed[msg.sender], "NFT is already claimed by this wallet");
        _mint(msg.sender, whitelistId);
        whitelistId++;
        claimed[msg.sender] = true;
    }

    /**
    * @dev mints specified # of tokens to sender address
    * max supply 8998, no limit on # of tokens
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
     * Activation 
     * **/

    bool public saleIsActive = false;

    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    /**
    * @dev set collection URI for marketplace display
    */
    function setCollectionURI(string memory collectionURI) internal virtual onlyOwner {
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
}
