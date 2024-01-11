// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract AbodeCollection is ERC721, ERC721URIStorage, Pausable,
    AccessControl, Ownable  {
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    bytes32 constant VALIDATE_ADDRESSES_ROLE = keccak256("VALIDATE_ADDRESSES_ROLE");
    Counters.Counter private _tokenIdCounter;
    
    struct WhitelistedAddress{
        bool whitelisted;
        string country;
    }
    struct ObjAddress{
        address _address;
        string country;
    }

    uint256[] private arrayTokensBurned;
    uint256 public maxSupply;
    uint256 public supply;
    uint256 public price;
    uint256 public maxMintAmount;

    mapping(address => uint256[]) ownerTokens;
    mapping(address => WhitelistedAddress) public whitelistAddresses;
    string public notRevealedUri;
    string public baseURI;
    string public baseExtension = ".json";
    
    bool public onlyWhitelisted;
    bool public onlyByJurisdiction;
    bool public pausedMint;
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VALIDATE_ADDRESSES_ROLE, msg.sender);
        _tokenIdCounter.increment();
        onlyWhitelisted = false;
        onlyByJurisdiction = false;
        pausedMint= false;
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
        maxSupply = 1000;
        maxMintAmount = 1000;
        supply = 0;
        price = 1.25 ether;
    }

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function pauseMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        pausedMint = true;
    }

    function unpauseMint() public onlyRole(DEFAULT_ADMIN_ROLE) {
        pausedMint = false;
    }

    modifier isPausedMint {
      require(pausedMint == false, "The mint is paused now, please come back later");
      _;
    }

    modifier isOnlyByJurisdiction(address _receiver) {
        require((onlyByJurisdiction == false) || (onlyByJurisdiction &&
         keccak256(bytes(whitelistAddresses[msg.sender].country)) == keccak256(bytes(whitelistAddresses[_receiver].country))), "Only users of the same jurisdiction can transfer!");
         _;
    }

    modifier transferToken(address from, address to, uint256 tokenId){
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is neither the owner nor approved");
        require(isAddressWhitelisted(from), "The sender address is not whitelisted");
        require(isAddressWhitelisted(to), "The receiver address is not whitelisted");
        require(balanceOf(to) + 1 <= maxMintAmount, "The receiver has already the max amount of tokens!");
        _;
    }

    function safeMint(uint256 quantity) public payable isPausedMint{
        require(quantity > 0, "need to mint at least 1 NFT");
        require(quantity + supply <= maxSupply, "The quantity of tokens is higher than maxSupply");
        require(quantity + balanceOf(msg.sender) <= maxMintAmount,"You are exceeding the max of amount of tokens per user!");
        require(msg.value >= price.mul(quantity), "You have to pay the price in order to mint this token");
        require(onlyWhitelisted == false || (onlyWhitelisted == true && isAddressWhitelisted(msg.sender)),"You have to be whitelisted to mint");

        _setApprovalForAll(msg.sender, address(this), true);
        
        for (uint256 i = 0; i < quantity; i++) {
            if(arrayTokensBurned.length > 0){
                uint256 tokenId = arrayTokensBurned[arrayTokensBurned.length-1];
                _transfer(address(this), msg.sender, tokenId);
                ownerTokens[msg.sender].push(tokenId);
                arrayTokensBurned.pop();
                supply += 1;
            }else{
                uint256 tokenId = _tokenIdCounter.current();
                _safeMint(msg.sender, tokenId);
                ownerTokens[msg.sender].push(tokenId);
                _tokenIdCounter.increment();
                supply += 1;
            }
        }
    }

    function transferOwnerTokens(address from, address to, uint256 tokenId) internal {
        for (uint i = 0; i < ownerTokens[from].length; i++){
            if(ownerTokens[from][i] == tokenId){
                ownerTokens[to].push(tokenId);
                for(uint j = i; j < ownerTokens[from].length - 1; j++){
                    ownerTokens[from][j] = ownerTokens[from][j+1];
                }
                ownerTokens[from].pop();
                break;
            }
        }
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data)
        public
        override
        whenNotPaused isOnlyByJurisdiction(to) transferToken(from, to, tokenId)
    {
        _safeTransfer(from, to, tokenId, _data);
        transferOwnerTokens(from, to, tokenId);
        
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused isOnlyByJurisdiction(to) transferToken(from, to, tokenId){
        _transfer(from, to, tokenId);
        transferOwnerTokens(from, to, tokenId);
    }

    //This function will be only used because of a legal issue
    function transferRevokedTokens(
        address from,
        address to,
        uint256 tokenId
    ) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(_isApprovedOrOwner((address(this)), tokenId), "ERC721: transfer caller is neither the owner nor approved");
        _transfer(from, to, tokenId);
        transferOwnerTokens(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function rollback(address payable tokenOwner, uint256 _refundAmount) external onlyRole(VALIDATE_ADDRESSES_ROLE) {
      require(_refundAmount <= ownerTokens[tokenOwner].length.mul(price), "The refund amound is higher than the expected amount");
      require(!isAddressWhitelisted(tokenOwner), "The address is whitelisted, you can't rollback this token");
      supply-= ownerTokens[tokenOwner].length;
      for(uint i = 0; i < ownerTokens[tokenOwner].length; i++){
        arrayTokensBurned.push(ownerTokens[tokenOwner][i]);
        _transfer(tokenOwner, address(this), (ownerTokens[tokenOwner][i]));
      }
      tokenOwner.transfer(_refundAmount);
      delete ownerTokens[tokenOwner];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        if(isAddressWhitelisted(this.ownerOf(tokenId))){
            //super.tokenURI
            return bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension))
                : "";
        }
        return notRevealedUri;
    }

    function totalSupply() external view returns(uint256){
        return supply;
    }

    function isAddressWhitelisted(address _member) public view returns (bool) {
        return whitelistAddresses[_member].whitelisted;
    }

    function addWhitelistAddresses(ObjAddress[] calldata _addresses) external onlyRole(VALIDATE_ADDRESSES_ROLE){
        for (uint i = 0; i < _addresses.length; i++) {
            whitelistAddresses[_addresses[i]._address].whitelisted = true;
            whitelistAddresses[_addresses[i]._address].country = _addresses[i].country;
        }
    }

    function removeWhitelistAddresses(address[] calldata _addresses) external onlyRole(VALIDATE_ADDRESSES_ROLE){
        for (uint i = 0; i < _addresses.length; i++) {
            whitelistAddresses[_addresses[i]].whitelisted = false;
        }
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _newBaseURI;
    }
    
    function setCost(uint256 _newCost) public onlyRole(DEFAULT_ADMIN_ROLE) {
        price = _newCost;
    }

    function setOnlyWhitelisted(bool _value) public onlyRole(DEFAULT_ADMIN_ROLE) {
        onlyWhitelisted = _value;
    }

    function setMaxMintAmount (uint256 _value) public onlyRole(DEFAULT_ADMIN_ROLE){
        maxMintAmount = _value;
    }

    function setOnlyByJurisdiction(bool _value) public onlyRole(DEFAULT_ADMIN_ROLE){
        onlyByJurisdiction = _value;
    }

    /**
     * Withdraws money to the addres specified in the first parameter.
     * @param to Receiver address.
     */
    function withdrawMoneyTo(address to, uint _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount <= address(this).balance, "the amount is higher than the balance");
        address payable payableTo = payable(to);
        payableTo.transfer(_amount);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}