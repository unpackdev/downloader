// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract BlazedCatsThemeSong is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {

    event PurchaseThemeSong (address indexed buyer, uint256 startWith, uint256 batch);

    address payable public wallet;

    uint256 public totalMinted;
    uint256 public burnCount;
    uint256 public totalCount = 10000;
    uint256 public maxBatch = 50;
    uint256 public price = 0.015 * 10**18; // 0.08 eth
    string public baseURI;
    bool private started;

    string name_ = 'BlazedCatsThemeSong';
    string symbol_ = 'BCTS';
    string baseURI_ = 'ipfs://QmdsNKts8sVn3YW5xmmA7FtmpTwBtH57MbnKpcvSPq79Cg/';

    constructor() ERC721(name_, symbol_) {
        baseURI = baseURI_;
        wallet = payable(msg.sender);
        
        for(uint256 i=0; i< 10; i++){
            _mint(_msgSender(), 1 + totalMinted++);
        }
        
        for(uint256 i=9990; i< 10000; i++){
            _mint(_msgSender(), i + 1);
        }
    }

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(bool _start) public onlyOwner {
        started = _start;
    }

    function purchaseThemeSong(uint256 _batchCount) payable public {
        require(started, "Sale has not started");
        require(_batchCount > 0 && _batchCount <= maxBatch, "Batch purchase limit exceeded");
        require(totalMinted + _batchCount <= totalCount, "Not enough inventory");
        require(msg.value == _batchCount * price, "Invalid value sent");
        
        //require(blazedCats.ownerOf(tokenId), ');

        emit PurchaseThemeSong(_msgSender(), totalMinted+1, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            _mint(_msgSender(), 1 + totalMinted++);
        }
        
        //walletDistro();
    }

    function walletDistro() public {
        uint256 contract_balance = address(this).balance;
        //require(payable(wallet).send(contract_balance));
        require(payable(0xCf2820a5b2D9Ec98C0e4456bf6CE778AFd2dFE93).send( (contract_balance * 500) / 1000));
        require(payable(0x60Ab841070f46188E73de2Cc2a8E6418B71C60f1).send( (contract_balance * 110) / 1000));
        require(payable(0xAf61C1C5057fb701CF5F4aACb9cE843bCD349fF4).send( (contract_balance * 100) / 1000));
        require(payable(0xfA8cA8078A1F73BB9AEF7e6fdA6C2b02854b12Ac).send( (contract_balance * 100) / 1000));
        require(payable(0xb817b0137Bb1A838aeBCc63a231d152C6CB03B41).send( (contract_balance * 50)  / 1000));
        require(payable(0x59f77152728A61640C9F0Bf289b5A0b6FA338Db4).send( (contract_balance * 50)  / 1000));
        require(payable(0x046bBe099CfA0b6cc71d59D6E4Cd38c5d0eEF71b).send( (contract_balance * 50)  / 1000));
        require(payable(0x7dF05B684e3E66C30287e0C0C4c8954ed26EDe97).send( (contract_balance * 40)  / 1000));
    }
    
    function distroDust() public {
        walletDistro();
        uint256 contract_balance = address(this).balance;
        require(payable(wallet).send(contract_balance));
    }

    function changeWallet(address payable _newWallet) external onlyOwner {
        wallet = _newWallet;
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
        burnCount++;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
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