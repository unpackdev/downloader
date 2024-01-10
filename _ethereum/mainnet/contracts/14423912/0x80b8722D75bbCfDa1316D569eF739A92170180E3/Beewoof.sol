// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";

contract Beowoofs is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    struct BeowoofPack{
        uint256 counter;
        uint256 supply;
    }
    //BeowoofDetails = 16_0_6_3_5_4_8_16_002003004005 where the first 7 are fixed and denotes , color code, gender, background subsequently each 3 digit represents an attribute the first one being experience
    //body, collar, eye, mouth,..., XX-> extend in future
    //16_0_6_3_5_4_8_16_002003004005 - color code 16, gender - 0, background = 6 ...
    struct BeowoofDetails{
        uint8 colorCode;
        uint8 gender;
        uint8 background;
        uint8 body;
        uint8 collar;
        uint8 face;
        uint8 mouth;
        uint16 attributes; 
    }

    string public baseURI;
    string public initialURI;
    string public levelUpUri;
    
    mapping(uint => BeowoofPack) public beowoofsWithColor;
    mapping(uint => BeowoofDetails) public beowoofs;

    uint256 public price = 0.06 ether;
    uint256 public beowoofLaunchTime = block.timestamp;
    uint256 public nextLevelUpTime = 15 days;

    event BeowoofMinted(address Beowoof, uint tokenId);
    event Withdraw(address);
    event SetBaseURI(string);

    /**
    @dev 5 special and 16 * 43 688 beowoofs
    @dev special NFTs will be minted in between the normal NFT's
    @dev a premint of 10 NFT's for the whitelist
     */
    constructor() ERC721("Beowoofs", "BWF") {        
        beowoofsWithColor[0].supply = 5;
        for(uint i=1;i<17;i++){
            beowoofsWithColor[i].supply = 43;
        }
    }

    ///@dev Mint a beowoof
    function safeMintBeowoof(uint8 _colorCode) payable nonReentrant external {
        require(msg.value >= price, "Not enough fees");
        require(balanceOf(msg.sender) <= 10, "Max mint exceeded!");
        require(_colorCode > 0, "Invalid color code");
        require(!isContract(msg.sender), "Contracts are not allowed to mint Beowoofs");
        uint8 colorCode = _colorCode;
        if(_isSpecial()){
            colorCode = 0; 
        }

        BeowoofPack storage beowoofClass = beowoofsWithColor[colorCode];
        require(beowoofClass.counter < beowoofClass.supply, "Try another puppy!");
        beowoofClass.counter++;

        safeMint(msg.sender, colorCode);

        //refund the user any excess
        uint changes = msg.value - price;
        if(changes > 0 ){
            payable(msg.sender).transfer(changes);
        }
    }
    
    /**
    @dev Premint beowoofs that are not specials
     */
    function preMintBeowoof(uint8 _colorCode) onlyOwner external {
        require(!_isSpecial() && _colorCode >= 1, "Owner cannot mint a special");
        BeowoofPack storage beowoofClass = beowoofsWithColor[_colorCode];
        require(beowoofClass.counter < beowoofClass.supply, "Try another puppy!");
        beowoofClass.counter++;
        safeMint(msg.sender, _colorCode);
    }

    function safeMint(address to, uint8 _colorCode) internal {
        //mint a token setting the _colorCode as the additional URI parameter
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId < 693, "Total cap reached");
        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
        BeowoofDetails memory beowoofDetail = _getDetails(_colorCode);
        _setBeowoof(tokenId, beowoofDetail);
        _setTokenURI(tokenId, initialURI);
        emit BeowoofMinted(to, tokenId);
    } 

    function levelUpMyBeowoof(uint256 tokenId) external returns(bool leveledUp){
        require(msg.sender == ownerOf(tokenId), "You need to be the owner!");
        require(isLeveledUpTime(), "Not yet time!");
        _setTokenURI(tokenId, levelUpUri);
        return true;
    }

    function setLeveledUpTime(uint256 _nextLevelUpTime) external onlyOwner{
        nextLevelUpTime =  _nextLevelUpTime;
    }

    function setInitialUri(string memory _initialURI) external onlyOwner {
        initialURI =  _initialURI;
    }

    function setLeveledUpUri(string memory _levelUpUri) external onlyOwner {
        levelUpUri =  _levelUpUri;
    }

    function setTokenURI(uint tokenId, string memory _uri) external onlyOwner {
        _setTokenURI(tokenId, _uri);
    }
    
    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
        emit SetBaseURI(__baseURI);
    }

    /**
    @dev Withdraw the collected funds by the owner
     */
    function withdraw(address payable _to, uint256 amount) external onlyOwner {
        require(_to != address(0), "receiver cant be empty address");
        emit Withdraw(_to);

        _to.transfer(amount);
    }

    /**
    @dev attributes is used to set experience and other hidden attributes, onchain values are used to derive the json metadata offchain
     */
    function setAttributes(uint16 _attributes, uint _tokenId) public onlyOwner {
        BeowoofDetails storage beowoofDetail = beowoofs[_tokenId];
        beowoofDetail.attributes = _attributes;
    }
    
    function isLeveledUpTime() public view returns(bool levelUp){
        return (block.timestamp > beowoofLaunchTime + nextLevelUpTime);
    }

    function getCurrentBeowoof() public view returns(uint) {
        return _tokenIdCounter.current();
    }

    function _setBeowoof(uint tokenId, BeowoofDetails memory beowoofDetail) internal {
        beowoofs[tokenId] = beowoofDetail;
    }
    
    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // view functions
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if(_isSpecial(_tokenId)){
           return string(abi.encodePacked(super.tokenURI(_tokenId), uint2str(_tokenId)));
        }
        else{
            BeowoofDetails memory beowoofDetail = beowoofs[_tokenId];
            return string(abi.encodePacked(super.tokenURI(_tokenId), _getWoofAttributePattern(beowoofDetail)));
        }

    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _getWoofAttributePattern(BeowoofDetails memory beowoofDetail) internal view returns (bytes memory)  {
       if(isLeveledUpTime()){
            return (abi.encodePacked(
                        uint2str(beowoofDetail.colorCode),"_",
                        uint2str(beowoofDetail.gender),"_",
                        uint2str(beowoofDetail.background),"_",
                        uint2str(beowoofDetail.body),"_",
                        uint2str(beowoofDetail.collar),"_",
                        uint2str(beowoofDetail.face),"_",
                        uint2str(beowoofDetail.mouth),"_",
                        uint2str(beowoofDetail.attributes)
                    ));
       }
       else{
            return (abi.encodePacked(
                        uint2str(beowoofDetail.colorCode),"_",
                        uint2str(beowoofDetail.gender),"_",
                        uint2str(beowoofDetail.background),"_",
                        uint2str(beowoofDetail.attributes)
                    ));
       }
       
    }

    function _getDetails(uint8 colorCode) internal view returns (BeowoofDetails memory beowoofDetail){
       beowoofDetail.colorCode = colorCode;
       beowoofDetail.gender = uint8(block.number % 2); 
       beowoofDetail.background = uint8(block.number % 18);
       beowoofDetail.body = uint8(block.number % 22);
       beowoofDetail.collar = uint8(block.number - 2 % 21);
       beowoofDetail.face = uint8(block.number - 1 % 22);
       beowoofDetail.mouth = uint8(block.number + 1 % 22);
       beowoofDetail.attributes = 0;// because its a puppy
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _isSpecial() internal view returns(bool) {
        uint256 tokenId = _tokenIdCounter.current(); 
        return _isSpecial(tokenId);
    }

    function _isSpecial(uint256 tokenId) internal view returns(bool specialFlag) {
    if(tokenId == 4
        || tokenId == 8 
        || tokenId == 13 
        || tokenId == 420 
        || tokenId == 666 
        )
        {
            return true;
        }
    }

    //https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function isContract(address account) internal view returns (bool) {
      return account.code.length > 0;
    }
}