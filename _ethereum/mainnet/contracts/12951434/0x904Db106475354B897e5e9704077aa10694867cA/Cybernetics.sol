// SPDX-License-Identifier: None
pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////((((((/////////////////////////////
/////////////////////////////////////////////@@@@@&#////////////////////////////
//////////////////////////////////////&&@@@@@@@@@@@(////////////////////////////
////////////////////////////#@@@@@@@@@@@@@@@@@@@@@@@@@@/////////////////////////
/////////////////////////&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@/////////////////////////
/////////////////////////@@@@@@@@@@@@@@@&&@@@@&&@@@@@@@/////////////////////////
//////////////////////@@@@@@(............,@@@@@@@@@@@@@/////////////////////////
//////////////////////@@@....................@@@.......@@@//////////////////////
//////////////////////@@@..............................@@@//////////////////////
//////////////////////@@@..............................@@@//////////////////////
//////////////////////@@@..............................@@@//////////////////////
//////////////////////@@@.......###%%%####......###%%%%@@@//////////////////////
///////////////////@@@..........,,,***..........,,,(%%%@@@//////////////////////
///////////////////@@@..........,,,***..........,,,(%%%@@@//////////////////////
///////////////@@@@,,,.................................@@@//////////////////////
///////////////@@@@....................................@@@//////////////////////
///////////////////@@@.......................,,,@@@/...@@@//////////////////////
///////////////////@@@.......................,,,@@@/...@@@//////////////////////
///////////////////@@@.......................@@@@@@/...@@@//////////////////////
//////////////////////@@@..............................@@@//////////////////////
/////////////////////////@@@(...,,,...,,,,,,,..........@@@//////////////////////
/////////////////////////@@@(...,,,...,,,,,,,..........@@@//////////////////////
/////////////////////////@@@(......@@@.............#@@@/////////////////////////
//////////////////////@@@@@@(.........@@@@@@@@@@@@@#////////////////////////////
///////////////////@@@&&&@@@(................@@@@@@@@@@/////////////////////////
////////////(((((((@@@&&&@@@(................@@@@@@@@@@(((//////////////////////
////////////@@@@@@@&&&&&&@@@(...,,,..........@@@&&&&&&&@@@//////////////////////
/////////@@@&&&&&&&&&&&&&&&&@@@@...,,,....,,,...@@@@&&&&&&@@@///////////////////

contract Verify is Ownable {
    address verificationAddress;

    constructor (address _verificationAddress) {
        verificationAddress = _verificationAddress;
    }

    function isValidData(uint256 _number, string memory _word, bytes memory sig) public view returns(bool){
        bytes32 message = keccak256(abi.encodePacked(_number, _word));
        return (recoverSigner(message, sig) == verificationAddress);
    }

    function isValidData(uint256 _number, string memory _word, address _address, bytes memory sig) public view returns(bool){
        bytes32 message = keccak256(abi.encodePacked(_number, _word, _address));
        return (recoverSigner(message, sig) == verificationAddress);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address){
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(sig);
        return ecrecover(message, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
           // first 32 bytes, after the length prefix
           r := mload(add(sig, 32))
           // second 32 bytes
           s := mload(add(sig, 64))
           // final byte (first byte of the next 32 bytes)
           v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
   }

    // Owner Functions
    function setVerificationAddress(address _verificationAddress) public onlyOwner {
        verificationAddress = _verificationAddress;
    }
}

interface Cryptopunks {
    function punkIndexToAddress(uint index) external view returns(address);
}

contract Cybernetics is ERC721, ERC721Enumerable, Verify, ReentrancyGuard{
    constructor(address _verificationAddress, string memory _base) ERC721("Cybernetics", "CYB") Verify(_verificationAddress){
        baseURI = _base;
        creationBlock = block.number;
    }

    string private baseURI = "";
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public creationBlock;

    uint256 public mintPrice = 100000000000000000;
    bool public communityGrant = false;
    bool public publicSale = false;
    
    mapping (uint256 => uint256) internal punksUsedBlock;
    mapping (uint256 => uint256) public giveawaysUsed;
    address internal punkAddress = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    uint256 public punkMintsRemaining = 250;
    uint256 public giveawaysRemaining = 200;
    uint256 public mintAtOnceAmt = 20;
    uint256 randomMintMod = 4; // 1/4 chance
    uint256 blockRoundMod = 10; // Round every 10 blocks

    // Optional contract-accessible base64 image encoding
    mapping (uint256 => string) public tokenToImage;


    function _mintCybernetic(address _to) internal {
        require(totalSupply() < MAX_SUPPLY, 'Reached max supply');
        _safeMint(_to, totalSupply()); // totalSupply is new ID
    }   

    /*
     * Image and Contract Data is already accessible through the blockchain for every token via uploadData(),
     * but it's accessible via outside calls only. For individual images to be accessible to /contracts/, 
     * users can optionally save the base64 encoding of their tokens here.
     */
    function saveTokenImage(uint256 _tokenId, string memory imageData, bytes memory sig) public {
        require(isValidData(_tokenId, imageData, sig), "Invalid Sig");
        tokenToImage[_tokenId] = imageData;
    }

    function mintPublic(uint256 mintAmt) external payable nonReentrant{
        require(publicSale);
        require(mintAmt > 0 && mintAmt <= mintAtOnceAmt, "Must mint appropriate amount");
        require(msg.value >= mintPrice*mintAmt, 'Eth value below price');
        for (uint256 i = 0; i < mintAmt; i++) {
            _mintCybernetic(msg.sender);
        }
    }

    function giveawayMint(uint256 number, bytes memory sig) external nonReentrant {
        require(isValidData(number, "giveaway", sig) || isValidData(number, "giveaway", msg.sender, sig), "Invalid Sig");
        require(giveawaysUsed[number] == 0, "Already minted with this giveaway");
        require(giveawaysRemaining > 0, "No giveaway mints remaining");
        giveawaysUsed[number]++;
        giveawaysRemaining--;
        _mintCybernetic(msg.sender);
    }

    /**
     * Community grant minting.
     */
    function mintWithPunk(uint256 _punkId) external nonReentrant {
        require(communityGrant, "Community Grant is off");
        require(Cryptopunks(punkAddress).punkIndexToAddress(_punkId) == msg.sender, "Not the punk owner.");
        require(punkMintsRemaining > 0, "No punk mints remaining");
        
        /* Hash Check */
        checkAndMarkBlock(_punkId);

        punkMintsRemaining--;
        _mintCybernetic(msg.sender);
    }

    function checkAndMarkBlock(uint256 _punkId) internal {
        uint256 tokenBlockHash = getTokenBlockHash(_punkId, block.number);
        require(punksUsedBlock[tokenBlockHash] == 0, "Punk already used this block");
        require(internalWinningHash(tokenBlockHash), "Try again, bad timing");
        punksUsedBlock[tokenBlockHash]++;
    }

    function checkWinningHash(uint _punkId, uint blockNumber) public view returns (bool){
        uint256 tokenBlockHash = getTokenBlockHash(_punkId, blockNumber);
        return internalWinningHash(tokenBlockHash);
    }

    function internalWinningHash(uint256 tokenBlockHash) internal view returns (bool){
        uint256 index = tokenBlockHash % randomMintMod;
        return (index == 0);
    }

    function checkPunkUnusedThisBlock(uint _punkId, uint blockNumber) public view returns (bool){
        uint256 tokenBlockHash = getTokenBlockHash(_punkId, blockNumber);
        return (punksUsedBlock[tokenBlockHash] == 0);
    }

    function getTokenBlockHash(uint _tokenId, uint blockNumber) internal view returns (uint){
        uint256 blockRounded = blockNumber - (blockNumber % blockRoundMod);
        uint256 tokenBlockHash = uint(keccak256(abi.encodePacked(_tokenId, blockRounded)));
        return tokenBlockHash;
    }


    // Function exists solely for ease of metadata standards
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function randomSeeds(uint256 tokenId) public view returns (uint) {
        if (tokenId >= totalSupply()){
            return 0;
        }
        return uint(keccak256(abi.encodePacked(tokenId, creationBlock)));
    }



    // Owner Functions

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setCommunityGrant(bool _communityGrant) public onlyOwner {
        communityGrant = _communityGrant;
    }

    function setPublicSale(bool _publicSale) public onlyOwner {
        publicSale = _publicSale;
    }

    function setPunkMints(uint256 _punkMints) public onlyOwner {
        punkMintsRemaining = _punkMints;
    }

    function setGiveaways(uint256 _giveawayMints) public onlyOwner {
        giveawaysRemaining = _giveawayMints;
    }

    function setRandomMintMod(uint256 _mod) public onlyOwner {
        randomMintMod = _mod;
    }

    function setBlockRoundMod(uint256 _mod) public onlyOwner {
        blockRoundMod = _mod;
    }

    function setMintAtOnceAmt(uint256 _atOnce) public onlyOwner {
        mintAtOnceAmt = _atOnce;
    }

    function setPunkAddress(address _punkAddr) public onlyOwner {
        punkAddress = _punkAddr;
    }

    function setBaseURI(string memory _base) public onlyOwner {
        baseURI = _base;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(payable(msg.sender).send(_amount));
    }

    function withdrawAll() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    function devMint(uint mintAmt, address dropAddress) public onlyOwner {
        for (uint256 i = 0; i < mintAmt; i++) {
            _mintCybernetic(dropAddress);
        }
    }

    function devAirdrop(address[] memory dropAddresses) public onlyOwner {
        for (uint256 i = 0; i < dropAddresses.length; i++) {
            _mintCybernetic(dropAddresses[i]);
        }
    }

    function uploadData(bytes[] memory _data) public onlyOwner {
        // Images are encoded from left-to-right and then top-to-bottom
        emit UploadData();
    }

    event UploadData();

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}