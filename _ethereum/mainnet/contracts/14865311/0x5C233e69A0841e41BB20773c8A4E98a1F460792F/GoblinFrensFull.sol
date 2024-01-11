// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "./Ownable.sol";
import "./ERC721A.sol";

/*
GobliN freNs
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
psst.........
*/
contract GoblinFrens is ERC721A ,Ownable {
    
    string  public              werMeatDataFurBurggurr;        
    
    uint256 public              MAKSI_GOBBO_NUMBE       = 2222;            
    uint256 public              HOWMENEE_FREE_MINNZ     = 222;
    uint256 public              FREE_GARB_PRO_WALLY     = 5;
    uint256 public              GOLBI_PER_TARNSECTIURGH = 20;  
   
    uint256 public constant     TEEM_WESERVDS           = 222;
    uint256 public             teemHfMentid            = 0;

    bool public                 isPauzzd                = true;
/*
 Prrriicee cHangnn pleez cHeck goblinfrens.com or etherscan -> Read Contract -> priceInWei (then use/google wei to Ether converter)
*/  
    uint256 public              priceInWei             = 0.001 ether;
        
    mapping(address => uint) public addressToMinted;
    mapping(address => uint) public addressToMintedFree;

  constructor(string memory _werMeatDataFurBurggurr) 
    ERC721A("GobliN freNs", "GOBLINFREN") {
        werMeatDataFurBurggurr = _werMeatDataFurBurggurr;
    }

  function setPrice (uint256 newPrice) external onlyOwner {
      priceInWei = newPrice;
  }
  function setPauzz (bool newPauzzd) external onlyOwner {
      isPauzzd= newPauzzd;
  }

  function setGolbiPerTarnsectiurgh (uint256 newGolbiPerTarnsectiurghhhhh) external onlyOwner {
      GOLBI_PER_TARNSECTIURGH= newGolbiPerTarnsectiurghhhhh;
  }

  function setFreeGarbProWally (uint256 newFreeGarbProWally) external onlyOwner {
      FREE_GARB_PRO_WALLY= newFreeGarbProWally;
  }

  function setHowmeneeFreeMinnz(uint256 newHowmeneeFreeMinnz) external onlyOwner {
      require(newHowmeneeFreeMinnz<=MAKSI_GOBBO_NUMBE,"sIli hOomenn");
      HOWMENEE_FREE_MINNZ= newHowmeneeFreeMinnz;
  }

  function setMaksiGobboNumbe(uint256 newMaksiGobboNumbe) external onlyOwner {
      MAKSI_GOBBO_NUMBE=newMaksiGobboNumbe;
  }     
  
  function setwerMeatDataFurBurggurr(string memory _werMeatDataFurBurggurr) public onlyOwner {
        werMeatDataFurBurggurr = _werMeatDataFurBurggurr;
    }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "nO goBBo tokkkerghnn xistinghh");
        
        bytes memory strBytes = bytes(werMeatDataFurBurggurr);
        if( strBytes.length>0)
        return string(abi.encodePacked(werMeatDataFurBurggurr, Strings.toString(_tokenId)));
        else
        return "";
    }

    function reserveMint(uint256 count) external onlyOwner {
        require(teemHfMentid+count <= TEEM_WESERVDS , 'morrrr thAnnn weSurrFF?? nnniiioooorghh');
        teemHfMentid += count;
        _safeMint(_msgSender(),count);
    }

    function airGob(uint256 count,address to) external onlyOwner 
    {
        _safeMint(to,count);
    }

    /* OoH what dis? */
    function promoGobbbbDrobb(uint256 startID,address[] memory to) external onlyOwner 
    {        
        unchecked {
        for (uint256 n=startID;n<(startID+to.length);) {
        safeTransferFrom(_msgSender(),to[(n-startID)],n);
            ++n;
            }
        }
    }



    function burn(uint256 tokenId) public { 
      
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
         getApproved(tokenId) == _msgSender() ||
          isApprovedForAll(prevOwnership.addr, _msgSender()));

         require(
          isApprovedOrOwner,
         "ERC721A: transfer caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function withdraw(uint256 amount) external onlyOwner {
    require(amount<=address(this).balance,"To muCHy");
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


 /*
    hIII hoOomAnnn CheCK burGhherr soUrccceee gooooooooood
*/   
   function aaurghMintGoblinFren(uint256 count) external payable {        
        require(! isPauzzd , "iZz PauZZdddsss!");
        require(count <= GOLBI_PER_TARNSECTIURGH, "To mUChy ate OncE!");
        require(msg.sender == tx.origin,"nO duMp coMtaRcT siLLLi uhMEn!");   
        require(totalSupply() + count <= MAKSI_GOBBO_NUMBE, "hAvE NO mOr ggolllBisss!");       

        //iz fri??
        if ( msg.value == 0){
            require ( ((totalSupply()-teemHfMentid) <= HOWMENEE_FREE_MINNZ), "nO mO freeee MiNNzzz!");            
            require(addressToMintedFree[_msgSender()]+count<=FREE_GARB_PRO_WALLY,"tO muCHy forr Frrre dON beuRGH grrreeeDii!");         
            addressToMintedFree[_msgSender()]+=count; 
            }
        else
           require(count * priceInWei <= msg.value, "fUndS numburrghh nOt coRREcT!");
            
        _safeMint(_msgSender(), count);
        addressToMinted[_msgSender()]+=count;            
    }


}

