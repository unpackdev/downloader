// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";

/*LOVExoXXXXXXXXLOVEXXXXXNNNXXKKOkdollldxxxxxxxocoOOkkOOOOOkkOOOOOOkxolc::;;;;;;;;;;;;;;;;;;;;;;;;;;
XXXXXXXXXXK0OkkkkkO0KXXXXXXXXXNNNXKKOxolllodxxxdclxkkkOOOOOOOkkkkkOOOkxdoc:;;;;;;;;;;;;;;;;;;;;;;;;;
XXXXXXXXX0kdc:;;;;:lxOKXXXXXXXXXXNNNNXK0kdlllodxlcoxOOOOkkxddoooodkOOOOkkdlc:;;;;;;;;;;;;;;;;;;;;;;;
XXXXXXXX0xl,.......';lxOOOkkOO0KXXXXXNNNXK0kollooc:lk00kdocc::::cokOOOOOOkkdl::;;;;;;;;;;;;;;;;;;;;;
KXXXXXXKkl,..........,cl:;;;:coxOKXXXXXXNNNXKOxolccccldkxdlc:;;:ldkOOkkOkOOkxoc:;;;;;;;;;;;;;;;;;;;;
OXXXXXXOd:'...........''......';lx0XXXXXXXXNNXK0kdolcccldkxolc:cokOOOkkOOkkOOkdlc:;;;;;;;;;;;;;;;;;;
kKLOVEXOd:......................;lkKXXXXXXXXXXNNXK0OdlcccldkxdooxOOkOOkOOkkOkOkxoc:;;;;;;;;;;;;;;;;;
x0XXXXX0dc'.....................,lk0XXXXXXXXXXXXNNNXKOxlcccldkOOOOOkkOOOkkkOkkOOkdl::;;;;;;;;;;;;;;;
dkKXXXXKkl,....................':oOKXXXXLOVEXXXXXXXXNNXKOxlccclx00OOOkkOOkOkkOOOOOkxoc:;;;;;;;;;;;;;
dx0XXXXX0xc,..................':okKXXXXXXXXXXXKKXXXXXNNXKOdlcccodddxxkkkOOOOOkkOOOOxoc:;;;;;;;;;;;;;
ddOXXXXXKOxc,...............';ldOKXXXXXXXXXK0OOKXXXXXXXNNX0koccllllllloooooooddxxkkOkdl:;;;;;;;;;;;;
ddkKXXXXXK0xl,...........',:ldOKXXXXXXXXXKOkxkKXXXXXXXXXXNNX0xlcoxxxxxxdddoolllllclxOkdl:;;;;;;;;;;;
ddx0XXXXXXX0ko:'...'',;:cldk0KXXXXXXXXK0kxddOKXXXXXXXXXXXXXNXKOdcldxxxxxxxxxxxxxdclkOOkdl:;;;;;;;;;;
dddOKXXXXXXXKOdl:ccloxkOO0KXXXXXXXXK0OxdddxOKXXXXXXXXXXXXXXXNNX0xlcdxxxxxxxxxxxdlcxOOOOkdl:;;;;;;;;;
dddx0XXXXXXXXX0OOO00KKXXXXXXXXXXKKOkdddddx0LOVEXXXXXXXXXXXXXXXNX0kocoxxxxxxxxxxlcdOOOOOOkdl:;;;;;;;;
ddddOXXXXLOVEXXXXXXXXXXXXXXXXXK0kxddddddk0XXXXXXXXXXXXXXXXXXXXXNNKOdcoxxxxxxxxocokOkOkOOOkdc:;;;;;;;
ddddxkOO0KKXXXXXXXXXXXXXXXXK0OxddddddddkKXXXXXXXXXXXXKKKKXXXXXXXNNKOdcldxxxxxdclkOOOOkkOOOkoc:;;;;;;
ddodddddddxkOO0KXLOVEXXXKKOkddddddddddOKXXXXXXXXK0OOkxxxxkOKXXXXXNNKOdcldxxxdlcxOOOOOOOOOOOxoc:;;;;;
:llooooooodddddxkO0KXXK0kxddddddddddxOKXXXXXXKOkdl::;,,,;:ldOKXXXXNNKOdclxxxlcdOOOOOOOOOOkOkxl:;;;;;
.,cllllllllooooodddxOkxddddddddddddx0XXXXXXKOxo:,'........':okKXXXXNNKOdclxocokOOOOOOOOOkkOOkdl:;;;;
...:llolllc:;,,;coddddddddddddddddx0XXXXXXKko:'............'cd0XXXXXNNKOococck0OOOOOOOOOkOkkOxoc:;;;
...'colc;'......,loooddddddddddddk0XXXXXX0ko;..............':dOXXXXXXNNKkocccx0OkxxxkkkOOOOOkkdl:;;;
....:l;..........:llloodddddddddkKXXXXXXKko;...............,lx0XXXXXXXNX0klcclkkdlccllodxkkOOkxlc:;;
....;,...........:llllloodddddxOKXXXXXXKOd:'..............';coxOKXXXXXNNKOdcccokdl:::::cldkOOkkdl:;;
...,,...........'colllllloddddkKXXXXXXX0xc'..................':ox0XXXXXNNKkocccxkoc:;:cldkkOOOkkoc:;
..,,'...','.....:olcc:::cclodddkKXXXXXKko;.....................,lx0XXXXXNX0xccclkxlccldxkOOOOOOkxl:;
',,,'.',,'....',;,........',ldddkKXXXXKko:'.....................:dOXXXXXNNKOocccxkxddxkOOkkOOOOOkoc:
;;,,,,,,,...',,.............:odddkKXXXX0Odl:,'.................'cdOXXXXXNNXOxcccoO0OOOOOOOOOOOOOkdc:
;;;;;,;,,,,,,'.............,clodddOKXXXXXK0kdl:,'.............,:dkKXXXXXXNN0klccck0OOOkOOOOOkOOOOxl:
;;;;;;;;;,;,'..'','.......,cllooddx0XXXXXXXXK0kxoc::;;,,,,,;:cok0KXXXXXXXNNKOocllldkkOOOOkOOOOkkOxoc
:::;;:;;;;;,,,,,'........;lllllodddkKXXLOVEXXXXKK0OOkkkxxxxkO0KKXXXXXXXXXNNX0xclxolloxkOOkkOOOOOOkoc
::::::;;;;;,;,,'......,:lloolllloddxOKXXXXXXXXXXXXXXXXXXKKXXXXXXXXXXXXXXXXNX0klcxxxdllldkOOOOkkOOkdc
lllc::::;;;;;,,,,,,,'''',,;:clllodddxxkkOOO00KKKXXXXXXXXXXXXXLOVEXXXXXXXXXNN0klcdxxxxdolloxkkkOOOkdl
ooolc::::;;;;;,,'............,:loodddddddddddxxxkkkOOO00KKKXXXXXXXXXXXXXXXNNKOocdxxxxxxxdllldkOOOkxl
oooolc:::;;;;;,,'''............':odddddddddddddddddddddddxxkkOOO00KKKXXXXXNNKOocdxxxxxxxxxdolloxOkxl
hwxolc::;;;,,,;;,,,,,,'.........,oddddddddddddddddddddddddddddddddxkO0KXXXNNKOocoxxxxxxxxxxxxoLOVE*/

// CryptoHexes - Genesis of VS
contract CryptoHexes is ERC721Enumerable, Ownable, Pausable {
  using Strings for uint256;

    // Token Management
    uint256 public reserved = 27;
    uint256 constant MAX_SUPPLY = 9999;
    uint256 public price = 0.04 ether;
   
    // Metadata Management
    string public baseURI = "";
    string public extension = ".json";

    // Reveal Management
    bool public revealed = false;
    string public notRevealedUri = "ipfs://QmNsXafCSc9gLcQ9ZcCiJWLtWLpnWMyVev5iGdcUcU6DvP/preview.json";

    constructor() ERC721("CryptoHexes", "HEXES") {
        _pause();
    }

    // Public Functionality
    function mint(uint256 count) public payable whenNotPaused {
        uint256 totalSupply = totalSupply();
        require( count > 0, "Invalid mint amount");
        require( msg.value >= price * count, "Invalid ETH amount");
        require( totalSupply + count <= MAX_SUPPLY, "Max supply exceeded");
        for(uint256 i = 1; i <= count; i++){
            _safeMint( msg.sender, totalSupply + i );
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), extension))
            : "";
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    // onlyOwner Functionality
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function setBaseURI(string memory newBaseUri) external onlyOwner {
        baseURI = newBaseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseExtension(string memory newExtension) public onlyOwner {
        extension = newExtension;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setReveal(bool revealStatus) public onlyOwner {
        revealed = revealStatus;
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function mintReserved(uint256 count) public onlyOwner {
        // Limited to a publicly set amount
        require( count <= reserved, "Can't reserve more than set amount" );
        reserved -= count;
        uint256 supply = totalSupply();
        for(uint256 i = 1; i <= count; i++){
            _safeMint( msg.sender, supply + i );
        }
    }
    // Good luck. We love you.
}