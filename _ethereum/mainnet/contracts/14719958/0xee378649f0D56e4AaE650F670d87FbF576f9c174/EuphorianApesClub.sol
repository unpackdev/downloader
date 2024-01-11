// SPDX-License-Identifier: MIT
// Author: Pagzi Tech Inc. | 2022
// Euphorian Apes Club-EAC | 2022
pragma solidity >=0.8.0 <0.9.0;
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract EuphorianApesClub is ERC721Enumerable, Ownable {
    //sale settings
    uint256 public cost = 0.06 ether;
    uint256 public maxSupply = 2220;
    uint256 public maxMint = 10;
    //backend settings
    string public baseURI;
    address internal founders = 0xC421eAA6874FCEA0D839e19A10b974f7163B75F4;
    address internal bomb = 0x092DE785D1892B1556346F33aB44A203205B0816;
    address internal artists = 0xf8bA6339968Ae10Fe0f27d4718cb690ceC734D0D;
    address internal immutable pagzidev = 0x2d0F4bcD4D2f08FAbD5a9e6Ed7c7eE86aFC3B73f;
    mapping(address => bool) public projectProxy;
    //date variables
    uint256 public publicDate = 1651795200;//5 May 2022 // 20.00 EST
    //mint passes/claims
    address public proxyAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    //royalty settings
    uint256 public royaltyFee = 500;
    modifier checkLimit(uint256 _mintAmount) {
        require(_mintAmount > 0 && _mintAmount <= maxMint, "Invalid mint amount!");
        _;
    }
    modifier checkDate() {
        require((publicDate < block.timestamp),"Public sale is not yet!");
        _;
    }
    modifier checkPrice(uint256 _mintAmount) {
        require(msg.value == cost * _mintAmount, "Insufficient funds!");
        _;
    }
    constructor() ERC721("Euphorian Apes Club", "EAC") {
        baseURI = "https://euphorianapesclub.nftapi.art/meta/";
    }
    // external
    function mint(uint256 count) external payable checkLimit(count) checkPrice(count) checkDate{
        uint256 totalSupply = _owners.length;
        require(totalSupply + count <= maxSupply  , "Max supply reached!");
        for(uint256 i = 1; i <= count; i++) { 
            _mint(msg.sender, totalSupply + i);
        }
    }
    //only owner
    function gift(uint256[] calldata quantity, address[] calldata recipient) external onlyOwner{
    require(quantity.length == recipient.length, "Invalid data" );
    uint256 totalQuantity;
    uint256 totalSupply = _owners.length;
    for(uint256 i = 0; i < quantity.length; ++i){
        totalQuantity += quantity[i];
    }
    require(totalSupply + totalQuantity + 1 <= maxSupply, "No supply!" );
        for(uint256 i = 0; i < recipient.length; ++i){
        for(uint256 j = 1; j <= quantity[i]; ++j){
            _mint(recipient[i], totalSupply + j);
        }
            totalSupply = totalSupply + quantity[i];
        }
        delete totalSupply;
        delete totalQuantity;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        maxSupply = _supply;
    }
    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }
    function setPublicDate(uint256 _publicDate) external onlyOwner {
        publicDate = _publicDate;
    }
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }
    function switchProxy(address _proxyAddress) public onlyOwner {
        projectProxy[_proxyAddress] = !projectProxy[_proxyAddress];
    }
    function setProxy(address _proxyAddress) external onlyOwner {
        proxyAddress = _proxyAddress;
    }
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }
    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }
    function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);
        uint256[] memory tokensId = new uint256[](tokenCount);
        uint256 j = 0;
        for(uint256 i; i < _owners.length; i++ ){
          if(_owner == _owners[i]){
            tokensId[j] = i + 1; 
            j++;
            }
            if(j == tokenCount) return tokensId;
        }
        return tokensId;
    }
    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }
    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }
    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }
        return true;
    }
    function isApprovedForAll(address _owner, address operator) public view override(IERC721,ERC721) returns (bool) {
        //Free listing on OpenSea by granting access to their proxy wallet. This can be removed in case of a breach on OS.
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }
    //ERC-2981 Royalty Implementation
    function setRoyalty(address _royaltyAddr, uint256 _royaltyFee) public onlyOwner {
        require(_royaltyFee < 10001, "ERC-2981: Royalty too high!");
        founders = _royaltyAddr;
        royaltyFee = _royaltyFee;
    }
    function royaltyInfo(uint256, uint256 value) external view 
    returns (address receiver, uint256 royaltyAmount){
    require(royaltyFee > 0, "ERC-2981: Royalty not set!");
    return (founders, (value * royaltyFee) / 10000);
    }
    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(founders).transfer((balance * 620) / 1000);
        payable(pagzidev).transfer((balance * 200) / 1000);
        payable(artists).transfer((balance * 150) / 1000);
        payable(bomb).transfer((balance * 30) / 1000);
    }
}
contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}