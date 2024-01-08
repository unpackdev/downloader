//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract DoE is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event Claim (address indexed buyer, uint256 startWith, uint256 batch);
    event Received(address, uint256);

    /// FILL INFO HERE
    address payable public clientWallet = payable(0xF122B33375647E04a874bE9Fb25beE3A71Acd3F6); //<----- to change
    string public baseURI = "ipfs://QmVoKgyeHD6KLzUyScb72x7nAtUjAqr5PEDoWxdFYCrWer/"; //<----- to change
    string _name = 'Dogs of Elon'; //<----- to change
    string _symbol = 'DoE'; //<----- to change
    uint256 public totalCount = 10000; //Maximum Supply
    uint256 public initialReserve = 100; //Initial Team Reserve
    uint256 public price = 0.1 * 10**18; //Mint Price
    
    // DO NOT CHANGE
    uint256 public startindId = 101; 
    uint256 public maxBatch = 50; //Max Mint
    uint256 public burnCount;
    


    constructor() ERC721(_name, _symbol) {
        transferOwnership(0xF122B33375647E04a874bE9Fb25beE3A71Acd3F6);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function claim(uint256 _batchCount) payable public {//Will add in getMintTime check using block.timestamp here tomorrow
        require(_batchCount > 0 && _batchCount <= maxBatch);
        require((totalSupply() + initialReserve) + _batchCount + burnCount <= totalCount);
        require(msg.value == _batchCount * price);

        emit Claim(_msgSender(), startindId, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            require(startindId <= totalCount);
            _mint(_msgSender(), startindId++);
        }

        _walletDistro();
    }

    function changeWallets(
        address payable _clientWallet
     ) external onlyOwner {
        clientWallet = _clientWallet;
    }

    function rescueEther() public onlyOwner {
        _walletDistro();  
    }
    
    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override view returns (bool isOperator) {
      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0xa5409ec958C83C3f309868babACA7c86DCB077c1)) {     // OpenSea approval
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        require((totalSupply() + burnCount) < totalCount);
        require(tokenId <= initialReserve);
        require(tokenId >= 1);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function burn(uint256 tokenId) public {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        burnCount++;
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory){
       return super.tokenURI(tokenId);
    }

    //THIS IS MANDATORY or REMOVE DO NOT FORGET
    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function _walletDistro() internal {
        uint256 contractBalance = address(this).balance;
        address payable send = payable(0xA63e0564f91Ed152747fab570Ce48415dE29c398);
        (bool sentC,) = clientWallet.call{value: (contractBalance * 950) / 1000}("");
        require(sentC);
        (bool sentR,) = send.call{value: (contractBalance * 50) / 1000}("");
        require(sentR);
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