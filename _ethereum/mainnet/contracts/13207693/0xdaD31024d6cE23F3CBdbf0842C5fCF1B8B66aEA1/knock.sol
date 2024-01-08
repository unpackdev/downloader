// SPDX-License-Identifier: MIT
// File contracts/RocketKnockersNFT.sol

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract RocketKnockers is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable{

    event GrabKnockers (address indexed minter, uint256 startWith, uint256 times);
    event PermanentURI(string _value, uint256 indexed _id);

    address payable public treasury;
    IERC20 public bunny = IERC20(0x3Ea50B7Ef6a7eaf7E966E2cb72b519C16557497c);
    uint256 bunnyPass = 10 * 10**21;        // 10 trillion bunny
    uint256 bunnyPassVIP = 100 * 10**21;    // 100 trillion bunny

    uint public startTime = 1631404800;  // 9-11-21 @ 8 PM Eastern (UTC-4)
    uint public startTimeVIP = 1631412000;     // 9-11-21 @ 10 PM Eastern (UTC-4)
    

    uint256 public totalCount = 10014;
    uint256 public totalMinted;
    
    uint256 public maxBatch = 20;
    uint256 public maxBatchVIP = 30;
    uint256 public price = 85000000000000000; // 0.08 eth
    uint256 public priceDiscount = 75000000000000000; // 0.08 eth
    
    string name_ = 'RocketKnockers';
    string symbol_ = 'KNOCKERS';
    
    string public baseURI = "ipfs://QmU4EqjCSMuc5uwNQgTbHam5nHWZ24ssvBu4yFMWcrUYZa/";
    string public contractURI_ = "https://www.rocketknockers.com/rknftmeta.json";

    constructor() ERC721(name_, symbol_) {
        //baseURI = baseURI_;
        treasury = payable(address(msg.sender));
        
        emit GrabKnockers(_msgSender(), totalMinted+1, 110);

        for(uint256 i=0; i< 10; i++){
            _mint(_msgSender(), i + 1);
            totalMinted++;
        }
        for(uint256 i=10003; i< 10014; i++){
            _mint(_msgSender(), i + 1);
            totalMinted++;
        }
        
        
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
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

    function _baseURI() internal view virtual override returns (string memory){
        return baseURI;
    }
 

    function setBaseURI(string memory _newURI) public onlyOwner {
        baseURI = _newURI;
    }

    function setBaseContractURI(string memory _contractURI) public onlyOwner {
        contractURI_ = _contractURI;
    }
    
    function changePrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }
    
    function changeBunnyPassAmount(uint256 _bunnyPass, uint256 _bunnyPassVIP) public onlyOwner {
        bunnyPass = _bunnyPass;
        bunnyPassVIP = _bunnyPassVIP;
    }

     function changeBunny(IERC20 _newAddress) public onlyOwner {
        bunny = _newAddress;
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI) public onlyOwner {
        _setTokenURI(_tokenId, _tokenURI);
    }

    function setStart(uint256 _startTimeVIP, uint256 _startTime) public onlyOwner {
        startTimeVIP = _startTimeVIP;
        startTime = _startTime;
    }
    
     function currentBlockTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function grabKnockers(uint256 _batchCount) payable public {
        require(totalMinted + _batchCount <= totalCount, "Not enough inventory");

        uint256 bunnyHoldings = bunny.balanceOf(msg.sender);

        if (bunnyHoldings >= bunnyPass) {
            require(block.timestamp >= startTimeVIP, "BUNNY Pass sale has not started");
            require(_batchCount > 0 && _batchCount <= maxBatchVIP, "VIP Batch purchase limit exceeded");
        } else {
            require(block.timestamp >= startTime, "Public Sale has not started");
            require(_batchCount > 0 && _batchCount <= maxBatch, "Batch purchase limit exceeded");
        }

        if (bunnyHoldings >= bunnyPassVIP) {
            require(msg.value == _batchCount * priceDiscount, "Invalid discount value sent");
        } else {
            require(msg.value == _batchCount * price, "Invalid value sent");
        }
        
        emit GrabKnockers(_msgSender(), totalMinted+1, _batchCount);
        for(uint256 i=0; i< _batchCount; i++){
            _mint(_msgSender(), 1 + totalMinted++);
        }
    }

    function withdrawAll() public payable onlyOwner {
        uint256 contract_balance = address(this).balance;
        require(payable(treasury).send(contract_balance));
    }

    function changeTreasury(address payable _newWallet) external onlyOwner {
        treasury = payable(address(_newWallet));
    }

    function walletInventory(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }

    function contractURI() public view returns (string memory) {
        return contractURI_;
    }


    //TODO: test and fix
    function freezeURI(string memory _value, uint256 _id) public onlyOwner {
        
        emit PermanentURI(_value, _id);

    }
  

}