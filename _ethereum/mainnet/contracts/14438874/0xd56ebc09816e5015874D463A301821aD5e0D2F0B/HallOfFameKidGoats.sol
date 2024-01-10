// SPDX-License-Identifier: MIT

/** 
_______ _            _    _       _ _          __   ______                   
|__   __| |          | |  | |     | | |        / _| |  ____|                  
   | |  | |__   ___  | |__| | __ _| | |   ___ | |_  | |__ __ _ _ __ ___   ___ 
   | |  | '_ \ / _ \ |  __  |/ _` | | |  / _ \|  _| |  __/ _` | '_ ` _ \ / _ \
   | |  | | | |  __/ | |  | | (_| | | | | (_) | |   | | | (_| | | | | | |  __/
   |_|  |_| |_|\___| |_|  |_|\__,_|_|_|  \___/|_|   |_|  \__,_|_| |_| |_|\___|
                                                                              
                                                                              
  _____             _     _               _           
 / ____|           | |   | |             | |           
| |  __  ___   __ _| |_  | |     ___   __| | __ _  ___ 
| | |_ |/ _ \ / _` | __| | |    / _ \ / _` |/ _` |/ _ \
| |__| | (_) | (_| | |_  | |___| (_) | (_| | (_| |  __/
 \_____|\___/ \__,_|\__| |______\___/ \__,_|\__, |\___|
                                             __/ |     
                                            |___/      

*/

pragma solidity 0.8.12;


import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title HallOfFameKidGoats contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract HallOfFameKidGoats is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    string public PROVENANCE = "";

    uint256 public constant tokenPrice = 0;
    uint public constant maxTokenPurchase = 10;
    uint256 public MAX_TOKENS = 3100;

    bool public mintIsActive = false;
    bool public revealed = false;

    mapping(address => bool) private presaleList;
    mapping(address => uint256) private presalePurchases;

    string baseURI;
    string private notRevealedUri;
    string public baseExtension = ".json";
    

    constructor(
        string memory _initNotRevealedUri
        ) ERC721("Hall Of Fame Kid Goats", "HOFKG") {
          setNotRevealedURI(_initNotRevealedUri);
    }


    mapping (address => uint8) public availableMints;

    function setAmountForAddress(address _Addy, uint8 _Qty) public onlyOwner{
        availableMints[_Addy] = _Qty;
    }
    
    function setAmountForAddresses(address[] memory _mintAddress, uint8[] memory _mintQty) public onlyOwner {
        require(_mintAddress.length == _mintQty.length);
        uint i;
        for (i = 0; _mintAddress.length > i; i++) {
            setAmountForAddress(_mintAddress[i], _mintQty[i]);
       
        }

    }

    // CHANGED: needed to resolve conflicting fns in ERC721 and ERC721Enumerable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // CHANGED: needed to resolve conflicting fns in ERC721 and ERC721Enumerable
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function canMint(address _addr) public view returns (bool){
        if (availableMints[_addr] > 0) {
            return true;
        } else {
            return false;
        }
    }

    function actualMintFunction(uint8 _mintAmt) public payable {
        uint256 supply = totalSupply();
        require(mintIsActive, "Mint must be active to mint Tokens");
        require(supply + _mintAmt <= MAX_TOKENS, "Mint must not surpass maxSupply");
        require(canMint(msg.sender), "Address cannot mint");
        require(_mintAmt > 0, "_mintAmt must not be at 0");
        require(msg.value >= tokenPrice * _mintAmt, "Not enough money");
        require(availableMints[msg.sender] >= _mintAmt, "Not enough mints left");
        availableMints[msg.sender] = availableMints[msg.sender] - _mintAmt;
        for (uint256 i = 1; i <= _mintAmt; i++) {
            _safeMint(msg.sender, supply + i);
        }
       
    }
    

    // CHANGED: added to account for changes in openzeppelin versions
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
    
    function reveal() public onlyOwner() {
        revealed = true;
    }
    
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function flipMintState() public onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}