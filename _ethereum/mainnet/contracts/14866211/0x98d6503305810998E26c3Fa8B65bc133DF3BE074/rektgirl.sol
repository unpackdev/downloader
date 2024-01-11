// SPDX-License-Identifier: CC0
pragma solidity ^0.8.11;
import "./Ownable.sol";
import "./ERC721A.sol";


contract rektgirl is ERC721A ,Ownable {
    
    string  public              rektGirlTokenURI;        
    
    uint256 private constant     MAX_SUPPLY   = 5555;         
  
    uint256 public constant     MAX_PER_TX = 20;   
    uint256 public constant     RESERVEDTEAM           = 555;
    uint256 public              teamMinted            = 0;
    bool public                 isPaused                = true;

    uint256 public              priceInWei             = 0.001 ether;
        
    mapping(address => uint) public addressToMinted;

  constructor(string memory _tokenURI) 
    ERC721A("rektgirl", "REKTGIRL") {
        rektGirlTokenURI = _tokenURI;
    }


      function mintRektgirl(uint256 count) external payable {        
        require(! isPaused , "Paused!");
        require(count <= MAX_PER_TX, "Exceeds max mint per transaction!");
        require(msg.sender == tx.origin,"No smart contracts allowed!");   
        require(totalSupply() + count <= MAX_SUPPLY, "Not enough supply left!");  
        require(count * priceInWei <= msg.value, "fUndS numburrghh nOt coRREcT!");
            
        _safeMint(_msgSender(), count);
        addressToMinted[_msgSender()]+=count;            
    }


  function setPrice (uint256 newPrice) external onlyOwner {
      priceInWei = newPrice;
  }
  function setPaused (bool newIsPaused) external onlyOwner {
      isPaused= newIsPaused;
  }
  
  function setTokenURI(string memory _tokenURI) public onlyOwner {
        rektGirlTokenURI = _tokenURI;
    }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "nO goBBo tokkkerghnn xistinghh");
        
        bytes memory strBytes = bytes(rektGirlTokenURI);
        if( strBytes.length>0)
        return string(abi.encodePacked(rektGirlTokenURI, Strings.toString(_tokenId)));
        else
        return "";
    }

    function reserveMint(uint256 count) external onlyOwner {
        require(teamMinted+count <= RESERVEDTEAM );
        teamMinted += count;
        _safeMint(_msgSender(),count);
    }
  

    function withdraw(uint256 amount) external onlyOwner {
    require(amount<=address(this).balance);
    payable(_msgSender()).transfer(amount);     
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
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
  
 

}

