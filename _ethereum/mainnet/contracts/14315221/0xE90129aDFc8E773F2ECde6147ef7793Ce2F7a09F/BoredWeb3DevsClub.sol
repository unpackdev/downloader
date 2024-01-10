// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol"; 
import "./ERC2981.sol"; 
import "./ECDSA.sol";

contract BoredWEB3DevsClub 
    is Ownable, ERC721, ERC721Enumerable, AccessControl, ERC721Burnable, ReentrancyGuard,ERC2981 {

    using Counters for Counters.Counter;

    string  __licenseUri = "ipfs://QmTpE2iv5uzZyxWjPMSknkL3fysyvfKgkaoTNDUQSxqVQH/nft-license-v1.pdf";
    string  __baseUri = "ipfs://Qmadfj1cbrLfkmFSJEZkYChnpmgZ2SFAGqshJz1Ku6LWuQ/";
    bool __locked =false;
    bool __ownerMinted =false;
    bool __mintingStarted =false;
    uint __maxSupply = 1000;
    uint __maxOwnerMint = 10;
    uint256 __autoLockBlock = 0;
    address __royaltyAddress = 0x511fdEfBE8487f26855f4CAFB0ad4a7715c16fc8;
    uint16 __EnableMintBlockHeight = 50400; //7 days
    uint256 __autoEnableMintBlock= 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff; //7 days

    Counters.Counter private _tokenIdCounter;
    mapping(address=>bool) private __alreadyBatchMinted;

    constructor(uint256 _autoLockBlocks, uint256 _autoEnableMint) ERC721("Bored WEB3 Devs Club", "BW3D") {
        require(_autoLockBlocks>600,"auto-lock < 600 blocks");
        require(_autoEnableMint>600,"auto-enable < 600 blocks");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __autoLockBlock = block.number + _autoLockBlocks;
        __autoEnableMintBlock = block.number + _autoEnableMint;
        _tokenIdCounter.increment();//start at 1
        for (uint256 index = 0; index < __maxOwnerMint; index++) {
            ownerSafeMint(msg.sender);
        }
        __ownerMinted=true;
        //5% royalty
        _setDefaultRoyalty(__royaltyAddress,500);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }
    modifier mintingEnabled(){
        require(isMintingEnabled()==true,"Minting has not opened yet");
        _;
    }

    modifier whenUnlocked(){
        require(isLockedForever()==false,"Contract is locked forever");
        _;
    }
    function getLicensorAddress() public pure returns (address){
        return address(0xfaD7b839139937063064f80159c42cb37C7FB962);
    }
    function withdrawMoney() external  nonReentrant {
        require(address(__royaltyAddress)!=address(0),"no royalty receiver set");
        require(address(this).balance>0,"empty balance");
        (bool success, ) = address(__royaltyAddress).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
    function getBlocksLeftToEnableMint() public view returns(uint256){
        return __autoEnableMintBlock - block.number;
    }
    function getBlocksLeftToAutoLock() public view returns(uint256){
        return __autoLockBlock - block.number;
    }
    function getMintingStartBlock() public view returns(uint256){
        return __autoEnableMintBlock;
    }

    function isMintingEnabled() public view returns (bool){
        return (__mintingStarted==true || getBlocksLeftToEnableMint()<1); 
    }
    function startMinting() external onlyRole(DEFAULT_ADMIN_ROLE){
        __mintingStarted=true;
    }

    function isLockedForever() public view returns (bool){
        if(__locked){
            return true;
        }
        return (__autoLockBlock<block.number);
    }
    function lockForever() external onlyRole(DEFAULT_ADMIN_ROLE){
        __locked =true;
    }

    function changeRoyaltyInfo(address to,uint96 points) external onlyRole(DEFAULT_ADMIN_ROLE) 
    whenUnlocked {
        require(to!=address(0),"royalty address is empty");
        __royaltyAddress = to;
        _setDefaultRoyalty(to, points);
    }
    function license() public view returns (string memory){
        return __licenseUri;
    }

    function tokensOfOwner(address _owner) external view returns(uint16[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint16[](0);
        } else {
            uint16[] memory result = new uint16[](tokenCount);
            uint256 totalnfts = totalSupply();
            uint256 resultIndex = 0;

            // We count on the fact that all nfts have IDs starting at 1 and increasing
            // sequentially up to the totalnft count.
            uint16 nftId;

            for (nftId = 1; nftId <= totalnfts; nftId++) {
                if (ownerOf(nftId ) == _owner) {
                    result[resultIndex] = nftId;
                    resultIndex++;
                }
            }

            return result;
        }
    } 
    function setLicense(string memory _newUri) external onlyRole(DEFAULT_ADMIN_ROLE) 
    whenUnlocked {
        require(bytes(_newUri).length>0,"new license URI was empty.");
        __licenseUri = _newUri;
    }
    function setBaseURI(string memory _newUri) external onlyRole(DEFAULT_ADMIN_ROLE) 
    whenUnlocked {
        require(bytes(_newUri).length>0,"new base URI was empty.");
        __baseUri = _newUri;
    }
    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }
    function getMaxSupply() public view returns (uint256) {
        return __maxSupply;
    }
    function _baseURI() internal view override returns (string memory) {
        return __baseUri;
    }
    
   function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId),".json"))
        : "";
    
        }


    function ownerSafeMint(address to) internal 
    nonReentrant 
    whenUnlocked
    onlyRole(DEFAULT_ADMIN_ROLE)
     {
        require(totalSupply()<__maxSupply,"Max Supply Reached");
        require(balanceOf(to)<__maxOwnerMint,"owner mint max reached");
        require(__ownerMinted==false,"owner initial mint already happened");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    function safeMint(address to) 
    nonReentrant 
    callerIsUser 
    payable  
    public
    {
        require(__mintingStarted==true,"Minting has not opened yet");
        require(totalSupply() < __maxSupply,"Max Supply Reached");
        require(msg.value  >= 0.08 ether,"Minting costs 0.08 ether");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    function batchSafeMint(uint _amount, address to)  
     nonReentrant 
     callerIsUser 
     payable  
     public 
     {
        require(__mintingStarted==true,"Minting has not opened yet");
        require(_amount>1,"Amount not set or smaller than 2");
        require(_amount<21,"Max Batch is 20");
        require((totalSupply()+_amount)<(__maxSupply),"Minting over maximum supply");
        require(msg.value  >= (0.07 ether * _amount),"Minting costs 0.07 ether per batch mint token");

        for (uint256 index = 0; index < _amount; index++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _safeMint(to, tokenId);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721,ERC2981, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
