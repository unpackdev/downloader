/*                                                  
                L.                                      
            t   EW:        ,ft                      i   
            Ej  E##;       t#E f.     ;WE.         LE   
 t      .DD.E#, E###t      t#E E#,   i#G          L#E   
 EK:   ,WK. E#t E#fE#f     t#E E#t  f#f          G#W.   
 E#t  i#D   E#t E#t D#G    t#E E#t G#i          D#K.    
 E#t j#f    E#t E#t  f#E.  t#E E#jEW,          E#K.     
 E#tL#i     E#t E#t   t#K: t#E E##E.         .E#E.      
 E#WW,      E#t E#t    ;#W,t#E E#G          .K#E        
 E#K:       E#t E#t     :K#D#E E#t         .K#D         
 ED.        E#t E#t      .E##E E#t        .W#G          
 t          E#t ..         G#E EE.       :W##########Wt 
            ,;.             fE t         :,,,,,,,,,,,,,.
                             ,                          


VINYL ON-CHAIN GENERATIVE AUDIO-VISUAL ART COLLECTION
by Wannabes Music Club

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

interface IVinylsMetadata { 
    function tokenURI(uint256 tokenId) external view returns (string memory); 
}

interface IVIBE20 {
    function burnBurner(address from, uint256 amount) external;
}

interface IWBMC {
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
}

interface IWBMCEnum {
    function tokensOfOwner(address _owner, uint256 _totalSupply) external view returns (uint256[] memory);
}

contract WBMCVinylsND is ERC721, ReentrancyGuard, Ownable {

    uint256 public maxVinyls;
    uint private vinylPrice = 100000000000000000; //0.1 ETH
    uint private vinylVibePrice = 5000 * (10 ** 18); // 5000 $VIBE
    
    bool private publicSale = false;
    bool private privateSale = false;
    uint private _totalSupply = 0;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => bool) private idsClaimed;
    mapping (address => uint256) private whitelisted;

    uint256 public curGen = 1;
    mapping (uint256 => uint256) private tokenIdtoGen;

    bool private metadataSwitch = false;
    string private baseURI;
    string public provenanceHash;

    //interfaces
    IVinylsMetadata private vinylsMeta;
    IVIBE20 private vibeToken;
    IWBMC private WBMC;
    IWBMCEnum private WBMCEnum;

    function setMetaContr(address _vinylsMetaContr) public onlyOwner {
        vinylsMeta = IVinylsMetadata(_vinylsMetaContr);
    }

    function setVibeContr(address _vibeContr) public onlyOwner {
        vibeToken = IVIBE20(_vibeContr);
    }

    function setWBMCContr(address _wbmcContr) public onlyOwner {
        WBMC = IWBMC(_wbmcContr);
    }

    function setWBMCEnumContr(address _wbmcEnumContr) public onlyOwner {
        WBMCEnum = IWBMCEnum(_wbmcEnumContr);
    }

    /*
    ********************
    Claiming
    ********************
    */

    // claim with ethereum on public sale
    function claimEthTo(address _to, uint256 _vinQty) public payable nonReentrant {  
        require(_vinQty<=3 && _vinQty>0, "wrong qty");
        require(publicSale, "Sale not started");
        require(totalSupply() + _vinQty <= maxVinyls, "MaxSupply");
        require(msg.value >= vinylPrice*_vinQty, "low eth");
        for (uint256 i = 0; i < _vinQty; i++) {
            _tokenIds.increment(); 
            uint256 newItemId = _tokenIds.current();
            _safeMint(_to, newItemId);
            tokenIdtoGen[newItemId] = curGen;
            _totalSupply++;
        }
    }

    // claim with ethereum on public sale
    function claimEthWL() public payable nonReentrant {  
        require(privateSale, "Sale not started");
        require(msg.value >= vinylPrice, "low eth");
        require(whitelisted[msg.sender] > 0, "not WLed"); 
        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current();
        _safeMint(_msgSender(), newItemId);
        tokenIdtoGen[newItemId] = curGen;
        whitelisted[msg.sender]--;
        _totalSupply++;
    }

    function claimVibe() public nonReentrant {  
        require(privateSale, "Sale not started or ended");
        
        //burn vibe
        vibeToken.burnBurner(msg.sender, vinylVibePrice);

        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current();
        _safeMint(_msgSender(), newItemId);
        tokenIdtoGen[newItemId] = curGen;
        _totalSupply++;
    }

    function claimByWannabeId(uint256 wannabeId) public nonReentrant {  
        require(privateSale, "Sale not started");
        require(WBMC.ownerOf(wannabeId) == _msgSender(), "must own");
        require (!idsClaimed[wannabeId], "already claimed");

        _tokenIds.increment(); 
        uint256 newItemId = _tokenIds.current();
        _safeMint(_msgSender(), newItemId);
        tokenIdtoGen[newItemId] = curGen;
        _totalSupply++;
        idsClaimed[wannabeId] = true;
    }

    // claim vinyls for all wannabes on that wallet
    function claimAll() public nonReentrant {  
        require(privateSale, "Sale not started");

        uint[] memory tokens = WBMCEnum.tokensOfOwner(_msgSender(), WBMC.totalSupply());

        for (uint256 i=0; i<tokens.length; i++) {
            uint256 wannabeId = tokens[i];
            if (!idsClaimed[wannabeId]) {
                //if was not claimed yet;
                require(WBMC.ownerOf(wannabeId) == _msgSender(), "must own");
                _tokenIds.increment(); 
                uint256 newItemId = _tokenIds.current();
                _safeMint(_msgSender(), newItemId);
                tokenIdtoGen[newItemId] = curGen;
                _totalSupply++;
                idsClaimed[wannabeId] = true;
            }
        }
    }

    // check if that Wannabe was used to claim Vinyl
    function isClaimed (uint256 wannabeId) public view returns (bool) {  
        return idsClaimed[wannabeId];
    }

    // returns WL quota for this address
    function getWLQuota (address addr) public view returns (uint256) {  
        return whitelisted[addr];
    }

    // returns gen for this tokenId
    function genByTokenId (uint256 _tokenId) public view returns (uint256) {  
        return tokenIdtoGen[_tokenId];
    }

    // returns array with tokenIds of eth wallet
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalNFTs = totalSupply();
            uint256 resultIndex = 0;

            uint256 NFTId;

            for (NFTId = 1; NFTId <= totalNFTs; NFTId++) {
                if (ownerOf(NFTId) == _owner) {
                    result[resultIndex] = NFTId;
                    resultIndex++;
                }
            }
            return result;
        }
    }

    // Public Sale on/off
    function switchPublicSale(uint256 _newMaxVinyls) external onlyOwner {
        publicSale = !publicSale;
        maxVinyls = _newMaxVinyls;
    }

    // Private Sale on/off
    function switchPrivateSale() external onlyOwner {
        privateSale = !privateSale;
    }

    // increases WL quota for _wlAddress
    function increaseWLQuota(address _wlAddress, uint256 _quota) public onlyOwner {
        whitelisted[_wlAddress] = whitelisted[_wlAddress] + _quota;
    }

    // Get total Supply
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    } 

    // Set generation
    function setGen(uint _newGen) public onlyOwner {
        curGen = _newGen;
    }

    // Get current price
    function getPrice() public view returns (uint) {
        return vinylPrice;
    }

     // Get current price in Vibe
    function getVibePrice() public view returns (uint) {
        return vinylVibePrice;
    }

    // Set price
    function setPrice(uint _newPrice) public onlyOwner {
        vinylPrice = _newPrice;
    }

    // Set price in $VIBE
    function setVibePrice(uint _newPrice) public onlyOwner {
        vinylVibePrice = _newPrice * (10 ** 18);
    }

    // check if such token exists
    function tokenExists(uint256 _tokenId) public view returns (bool) {
        if (tokenIdtoGen[_tokenId] > 0) {
            return true;
        }
        else { 
            return false;
        }
    }

    function switchMetadata() public onlyOwner {
        metadataSwitch = !metadataSwitch;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setProvenance(string memory _newProv) public onlyOwner {
        provenanceHash = _newProv;
    }

    //withdraw
    function withdraw(uint256 amt) public onlyOwner {
        payable(msg.sender).transfer(amt);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        if (!metadataSwitch) {
            return string (abi.encodePacked(baseURI, toString(tokenId)));
        } else {
            return vinylsMeta.tokenURI(tokenId);
        }
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    constructor() ERC721("WBMC Vinyls", "WBMCVNLS") Ownable() {}
}

/*
May the force be with you! 
*/