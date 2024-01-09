/*
........................................................................................................
................................ffff...................................................OOOOOOOO.........
...................llllll....fffffff..DDDDDDDDDDDDDD.............AAAAAAA.............OOOOOOOOOOOO.......
...................llllll...ffffffff..DDDDDDDDDDDDDDDD...........AAAAAAAA..........OOOOOOOOOOOOOOOO.....
...................llllll...ffffffff..DDDDDDDDDDDDDDDDD..........AAAAAAAA..........OOOOOOOOOOOOOOOOO....
...................llllll...ffffffff..DDDDDDDDDDDDDDDDDD........AAAAAAAAA.........OOOOOOOOOOOOOOOOOO....
...................llllll...ffffff....DDDDDDDDDDDDDDDDDD........AAAAAAAAAA.......OOOOOOOO....OOOOOOOO...
.....eeeeeeee......llllll.lfffffffff..DDDDD......DDDDDDD.......AAAAAAAAAAA.......OOOOOOO......OOOOOOO...
....eeeeeeeeeee....llllll.lfffffffff..DDDDD.......DDDDDDD......AAAAAAAAAAA.......OOOOOO........OOOOOOO..
...eeeeeeeeeeeee...llllll.lfffffffff..DDDDD........DDDDDD......AAAAAAAAAAAA.....OOOOOOO........OOOOOOO..
..eeeeeeeeeeeeee...llllll.lfffffffff..DDDDD........DDDDDD.....AAAAAA.AAAAAA.....OOOOOO..........OOOOOO..
..eeeeeeeeeeeeeee..llllll.lfffffffff..DDDDD........DDDDDD.....AAAAAA.AAAAAA.....OOOOOO..........OOOOOO..
.eeeeeee...eeeeee..llllll...fffff.....DDDDD........DDDDDD.....AAAAAA..AAAAAA....OOOOOO..........OOOOOO..
.eeeeee....eeeeee..llllll...fffff.....DDDDD........DDDDDD....AAAAAA...AAAAAA....OOOOOO..........OOOOOO..
.eeeeeeeeeeeeeeee..llllll...fffff.....DDDDD........DDDDDD....AAAAAA...AAAAAAA...OOOOOO..........OOOOOO..
.eeeeeeeeeeeeeeee..llllll...fffff.....DDDDD........DDDDDD....AAAAAAAAAAAAAAAA...OOOOOO..........OOOOOO..
.eeeeeeeeeeeeeeee..llllll...fffff.....DDDDD.......DDDDDDD...AAAAAAAAAAAAAAAAA...OOOOOOO........OOOOOOO..
.eeeeeeeeeeeeeeee..llllll...fffff.....DDDDD.......DDDDDDD...AAAAAAAAAAAAAAAAAA...OOOOOO........OOOOOO...
.eeeeee.....eeeee..llllll...fffff.....DDDDD......DDDDDDD....AAAAAAAAAAAAAAAAAA...OOOOOOO......OOOOOOO...
.eeeeeee...eeeeee..llllll...fffff.....DDDDDDDDDDDDDDDDDD...AAAAAAAAAAAAAAAAAAA...OOOOOOOO....OOOOOOOO...
..eeeeeeeeeeeeeee..llllll...fffff.....DDDDDDDDDDDDDDDDD....AAAAAA.......AAAAAAA...OOOOOOOOOOOOOOOOOO....
..eeeeeeeeeeeeeee..llllll...fffff.....DDDDDDDDDDDDDDDDD...AAAAAAA........AAAAAA....OOOOOOOOOOOOOOOO.....
...eeeeeeeeeeeee...llllll...fffff.....DDDDDDDDDDDDDDDD....AAAAAAA........AAAAAA....OOOOOOOOOOOOOOOO.....
....eeeeeeeeeee....llllll...fffff.....DDDDDDDDDDDDDD......AAAAAA.........AAAAAAA.....OOOOOOOOOOOO.......
......eeeeeee..........................................................................OOOOOOOO.........
........................................................................................................

The inaugural web3 toy drive - elfDAO.eth

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


contract ElfDAO is ERC721URIStorage, Ownable, ReentrancyGuard{
    string private _collectionURI;
    string public baseURI;

    /**
      * santa are from 1-5 (5 max supply)
      * worker elves from 6-30 (25 max supply)
      * reindeer from 31-1000 (970 max supply)
      * elves are from 1001 onwards (unlimited supply)
    **/

    uint256 immutable public maxSantaId = 5;
    uint256 public santaId = 1;

    uint256 immutable public maxWorkerElfId = 25;
    uint256 public workerElfId = 6;

    uint256 immutable public maxReindeerId = 1000;
    uint256 public reindeerId = 31;

    uint256 public elfId = 1001;

    // used to validate whitelists
    bytes32 public workerElfMerkleRoot;
    bytes32 public reindeerMerkleRoot;
    bytes32 public elfMerkleRoot;

    // keep track of those who have claimed their NFT
    mapping(address => bool) public claimed;

    constructor(string memory _baseURI, string memory collectionURI) ERC721("elfDAO NFT", "ELFDAO") {
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

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    /**
    * @dev does not charge a fee
    * Max supply: 5 (token ids: 1-5)
    * will be minted and airdropped to santa recipients
    */
    function mintSanta()
        public
        nonReentrant
        onlyOwner
    {
      require(santaId <= maxSantaId);
      _mint(msg.sender, santaId);
      santaId++;
    }

    /**
    * @dev mints 1 token per whitelisted address, does not charge a fee
    * Max supply: 25 (token ids: 6-30)
    */
    function mintWorkerElf(
      bytes32[] calldata merkleProof
    )
        public
        isValidMerkleProof(merkleProof, workerElfMerkleRoot)
        nonReentrant
    {
        require(workerElfId <= maxWorkerElfId, "minted the maximum # of elves");
        require(!claimed[msg.sender], "Worker elf is already claimed by this wallet");
        _mint(msg.sender, workerElfId);
        workerElfId++;
        claimed[msg.sender] = true;
    }

    /**
    * @dev mints 1 token per whitelisted reindeer address, does not charge a fee
    * Max supply: 970 (token ids: 31-1000)
    */
    function mintReindeer(
      bytes32[] calldata merkleProof
    )
        public
        isValidMerkleProof(merkleProof, reindeerMerkleRoot)
        nonReentrant
    {
        require(reindeerId <= maxReindeerId);
        require(!claimed[msg.sender], "Reindeer is already claimed by this wallet");
        _mint(msg.sender, reindeerId);
        reindeerId++;
        claimed[msg.sender] = true;
    }

    /**
    * @dev mints 1 token per whitelisted elf address, does not charge a fee
    * no max supply
    */
    function mintElf(
      bytes32[] calldata merkleProof
    )
        public
        isValidMerkleProof(merkleProof, elfMerkleRoot)
        nonReentrant
    {
        require(!claimed[msg.sender], "Elf is already claimed by this wallet");
        _mint(msg.sender, elfId);
        elfId++;
        claimed[msg.sender] = true;
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
    function setCollectionURI(string memory collectionURI) internal virtual onlyOwner {
        _collectionURI = collectionURI;
    }

    function setWorkerElfMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        workerElfMerkleRoot = merkleRoot;
    }

    function setReindeerMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        reindeerMerkleRoot = merkleRoot;
    }

    function setElfMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        elfMerkleRoot = merkleRoot;
    }

    /**
     * @dev withdraw funds for elf dao to specified account
     * should not be needed ever
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
