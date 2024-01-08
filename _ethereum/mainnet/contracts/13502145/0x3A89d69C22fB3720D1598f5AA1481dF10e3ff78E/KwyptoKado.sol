// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Enumerable.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Pausable.sol";
import "./Ownable.sol";



contract KwyptoKado is ERC721Enumerable, Pausable, Ownable  {
    using SafeMath for uint256;

    uint256 private _currentTokenId = 200;
    uint256 public maxSupply = 9999;
    uint256 public maxMintAmount = 10;
    uint256 public maxPerWallet = 99;
    uint256 public cost = 0.077 ether;
    uint8 public boostValue = 1;
    string public boostedStat = "Power";
    string baseURI;

    constructor() ERC721("KwyptoKados", "KwyptoKado") {
        baseURI = "ipfs://Qma6kNDutfab5A4bSjnaKf75madVMEGmE3x2w3mYRzepFW/";
    }
    
    function _baseTokenURI() internal view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI(), Strings.toString(_tokenId), ".json"));
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    

    function createKado(uint8 _amount) public payable whenNotPaused {
        require(_currentTokenId.add(_amount) > 200, "Not allowed first 200");
        require(_amount <= maxMintAmount, "Don't be greedy! Only 10 at a time.");
        require(msg.value >= cost * _amount, "Need to send monies!");
        require(balanceOf(msg.sender).add(_amount) <= maxPerWallet, "Only 99 per wallet!");
        require(_currentTokenId.add(_amount) <= maxSupply, "Not enough left, sorry!");
        

        for (uint i = 1; i <= _amount; i++){
            uint256 newTokenId = _getNextTokenId();
            _safeMint(msg.sender, newTokenId);
            _incrementTokenId();
        } 
    }

    function ownerKados(uint8 _start, uint8 _amount, address _to) public onlyOwner {
        require(_start + _amount <= 200, "Only allowed first 200");
        for (uint i = _start; i < _start+_amount; i++){
            _safeMint(_to, i);
        } 
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
      {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
          tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
     }


    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


}