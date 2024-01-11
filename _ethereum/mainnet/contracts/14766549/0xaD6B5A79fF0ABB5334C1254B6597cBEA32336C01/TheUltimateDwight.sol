//SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";

contract TheUltimateDwights is 
    Ownable,
    ERC721A,
    ReentrancyGuard
     {
    constructor() ERC721A("TheUltimateDwights", "THUG", 10, 7500 ) {}

    using SafeMath for uint256;

    string private _baseTokenURI = "https://ipfs.io/ipfs/QmZm5yxGCpbtbst9gf16yD8ATpwC4X8kc4aXa2s1DnDFZG/";

    bool public mintingOpen = false;
    uint256 private mintPrice = 0.1 ether; 
    uint256 private wlPrice = 0.08 ether; 
    address[] public Whitelisted;
    string private _baseExtension = ".json";
    enum SaleType{
        WL,
        PUBLIC
    }

    SaleType _sale = SaleType.WL;
    
    function setSale(SaleType sale) external onlyOwner{
        _sale = sale;
    }

    function setMintPrice(uint256 _amount, SaleType _s) external onlyOwner{
        if(_s == SaleType.WL){
            wlPrice = _amount;
        }else{
            mintPrice = _amount;
        }
    }

    function setBaseExtension(string memory _ext) external onlyOwner{
        _baseExtension = _ext;
    }

    function whitelist(address addr) public onlyOwner{
        Whitelisted.push(addr);
    }

    function isWhite() internal view returns(bool){
        for (uint i=0; i<Whitelisted.length; i++){
            if(msg.sender == Whitelisted[i]){
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Mints a token to an address with a tokenURI.
    * owner only and allows fee-free drop
    * @param _to address of the future owner of the token
    */
    function mintToAdmin(address _to) public onlyOwner {
        require(getNextTokenId() <= collectionSize, "Cannot mint over supply cap of 7500");
        _safeMint(_to, 1, true);
    }

    function mintManyAdmin(address[] memory _addresses, uint256 _addressCount) public onlyOwner {
        for(uint i=0; i < _addressCount; i++ ) {
            mintToAdmin(_addresses[i]);
        }
    }
    
    /**
    * @dev Mints tokens to an address with a tokenURI.
    * @param _amount number of tokens to mint
    */
    function mint(uint256 _amount) public payable nonReentrant{
        if(_sale == SaleType.WL){
            require(isWhite() == true, "Not whitelisted");
            require(msg.value >= _amount * wlPrice, "Amount less than mint price");
        }else{
            require(msg.value >= _amount * mintPrice, "Amount less than mint price");
        }
        require(_amount >= 1, "Must mint at least 1 token");
        require(_amount <= maxBatchSize, "Cannot mint more than max mint per transaction");
        require(mintingOpen == true, "Public minting is not open right now!");
        require(currentTokenId() + _amount <= collectionSize, "Cannot mint over supply cap of 7500");
        _safeMint(msg.sender, _amount, false);
    }

    function getMintPrice() external view returns (uint256){
        if(_sale == SaleType.WL){
            return wlPrice;
        }
        return mintPrice;
    }

    function isContractActive() external view returns(bool) {
        return mintingOpen;
    }

    function getMintedTokensForUser(address _user) external view returns(uint256 [] memory){
        uint balance = numberMinted(_user);
        uint256[] memory response = new uint256[](balance);
        for(uint i=1; i<=balance; i++){
            response[i-1]=tokenOfOwnerByIndex(_user, i);
        }
        return response;
    }

    function getTotalMintSupply() external view returns(uint){
        return currentTokenId();
    }

    function getSale() external view returns(SaleType){
        return _sale;
    }

    function openMinting() public onlyOwner {
        mintingOpen = true;
    }

    function stopMinting() public onlyOwner {
        mintingOpen = false;
    }
    
    /**
     * @dev Allows owner to set Max mints per tx
     * @param _newMaxMint maximum amount of tokens allowed to mint per tx. Must be >= 1
     */
    function setMaxMint(uint256 _newMaxMint) public onlyOwner {
        require(_newMaxMint >= 1, "Max mint must be at least 1");
        maxBatchSize = _newMaxMint;
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
        return ownershipOf(tokenId);
    }

    function withdraw(address _address, uint256 _amount) external onlyOwner {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

  /**
    * @dev Allow contract owner to withdraw ERC-20 balance from contract
    * in the event ERC-20 tokens are paid to the contract.
    * @param _tokenContract contract of ERC-20 token to withdraw
    * @param _amount balance to withdraw according to balanceOf of ERC-20 token
    * @param _owner address to withdraw the token balance to
    */
  function withdrawAllERC20(address _tokenContract, uint256 _amount, address _owner) public onlyOwner {
    require(_amount > 0);
    IERC20 tokenContract = IERC20(_tokenContract);
    require(tokenContract.balanceOf(address(this)) >= _amount, 'Contract does not own enough tokens');
    tokenContract.transfer(_owner, _amount);
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
        return string(abi.encodePacked(super.tokenURI(tokenId), _baseExtension));
    }

}
