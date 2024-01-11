//SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// .......................................................................
// .......................................................................
// .................................%%////(((@/...........................
// ............................////////////(((@((.....@...................
// ........................#////////////////(((((@...,*(..................
// .....................@///////////////////(((((%#.**/@..................
// ...................(/////////////////////((/(((@&(/....................
// .................@///////////(@/////////((///((@@@.....................
// ...............%//////(%//(/((///////(@#/////(((@(.....................
// ............*.&//////////&(%///////////&/////(((@,.....................
// ............,@//////////%&////////(#*@*&////(((((@.....................
// ............@/////////@#,,*///////%&*@&////(/(((@......................
// ...........,(///////#*,,*,,&//(//%/%&///////(((@.......................
// ....@*@,.,&(////////(,,//,*@//@///#((&///@/((((........................
// ....#**/**&#/////////@**@(//(///&/#&/#/&/((((&.........................
// .......#&(/@////////%/%////@(&#&%/&&@(///(((&..........................
// ...........@////////////////#/@@@#(/////(%@............................
// ...........@//////////(&//(//////////(##%..............................
// ........@@@@@/////////////////////((@&,/...............................
// .........@@%@@@&(%/////////////((##/,.....................@@@..........
// ..........%@@@@@@.(#(((((((((#@@%%@@@@@@@.....(@&.......@#//(@,/%&@@@@@
// ............@@@@@@....#%#/((@@@@@@@@@@@%@@@@@@@@@@@@@@@@@##//#@@@#,....
// .............@@@@@@.......@@%%%%%%%%%@@@@@@@&%%&@@@#&@..%@@@@(.......#@
// ..............@@@@@@......@@%%%%%%&@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@%,
// ...............@@&@@@.......*##@@@@@@@@@%%%%%%%%%%%%@@@................
// ................,@@@@@#..........,@@@@@@@@@@@@@@@@@@@@@................
// ..................&@@@@@............@@@%%%%%%&&@%@@&&@@&...............
// ....................@@@@@#............%@@%%%%%%%@@@%%%%%@@@@#%*........
// .......................................................................
// ...Delevop and Adut by RrrrGUAaaAAAAAA.................................
// .......................................................................


import "./Strings.sol";
import "./Ownable.sol";
import "./ERC721A.sol";

contract Gobmfers is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_GOBMFR_SUPPLY = 3333;
    uint256 public FREE_GBMFRS = 1500;
    uint256 public RESIRVD_GOBMFRS = 333;

    bool public salOpen;
    string public baseURI;
    string public contractURI;
    uint256 public price;

    constructor()
        ERC721A("Goblin Mfers", "GOBMFERS")
    {
        salOpen = false;
        baseURI = "ipfs://bafybeibqz4o5fyz6qdw7awviqsqc6rigaspfkzpoyjuj7ym47of5maeehe/";
        contractURI = "ipfs://bafybeibdqnlhlbmt457rcnk4zvsny3mupj6dmyf73psplbcr4kc4ak73mu/";
        price = 1000000000000000 wei;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function toagleSal() external onlyOwner() {
      salOpen = !salOpen;
    }

    function updatePrice(uint256 _price) external onlyOwner() {
      price = _price;
    }

    function getContractURI() public view returns (string memory) {
      return string(abi.encodePacked(contractURI, "contractURI.json"));
    }

    function updatecontractURI(string memory _newURI) public onlyOwner {
      contractURI = _newURI;
    }

    function updateBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function colectGold() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function devMint(uint _gobmfers, address _wallet) external onlyOwner {
        require(totalSupply() + _gobmfers <= MAX_GOBMFR_SUPPLY, "UR CODE SUCKS");
        _mint(_wallet, _gobmfers);
    }

    function mint(uint _gobmfers) external payable {
        require(salOpen, "try again later");
        require(_gobmfers <= 20, "2 Degen for mfgobs");
        if(totalSupply() <= FREE_GBMFRS) {
          _mint(msg.sender, _gobmfers);
        } else {
          uint cost;
          uint supply;
          unchecked {
              cost = _gobmfers * price;
              supply = totalSupply() + RESIRVD_GOBMFRS + _gobmfers;
          }
          require(msg.value >= cost, "Senmore");
          require(supply <= MAX_GOBMFR_SUPPLY, "NO MOER");
          _mint(msg.sender, _gobmfers);
        }
    }
}