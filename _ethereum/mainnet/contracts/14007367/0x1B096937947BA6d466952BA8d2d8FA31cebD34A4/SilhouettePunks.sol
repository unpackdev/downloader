//    _____ _ _ _                      _   _         _____             _        
//   / ____(_) | |                    | | | |       |  __ \           | |       
//  | (___  _| | |__   ___  _   _  ___| |_| |_ ___  | |__) |   _ _ __ | | _____ 
//   \___ \| | | '_ \ / _ \| | | |/ _ \ __| __/ _ \ |  ___/ | | | '_ \| |/ / __|
//   ____) | | | | | | (_) | |_| |  __/ |_| ||  __/ | |   | |_| | | | |   <\__ \
//  |_____/|_|_|_| |_|\___/ \__,_|\___|\__|\__\___| |_|    \__,_|_| |_|_|\_\___/
// 
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//////////////////////////////@@@@///@@@////@@@/////////////////////////////////
///////////////////////////@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////////
///////////////////////////@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////////
///////////////////////////@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////////
////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////
////////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
/////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
/////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
/////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
/////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@///////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////////
////////////////////@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//////////////////////////////
////////////////////@@@@@@@@@@@@@@@@@///////////////////////////////////////////
////////////////////@@@@@@@@@@@@@@@@@///////////////////////////////////////////

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract SilhouettePunks is ERC721, Ownable {

    using Strings for uint256;
    using Counters for Counters.Counter;

    string private _baseTokenURI;
    Counters.Counter private _tokenSupply;
    uint public constant MAX_SUPPLY = 10000;
    uint256 public constant PRICE = 0.01 ether;

    constructor(string memory baseURI) ERC721('Silhouette Punks', 'SP') {
    _baseTokenURI = baseURI;

    _safeMint(0xA7EE780B4136E70e3AC1590CAdCaAd05764563fE, 0);
    _tokenSupply.increment();
    _safeMint(0x7Eb696df980734DD592EBDd9dfC39F189aDc5456, 1);
    _tokenSupply.increment();
    _safeMint(0xc7E7747fa605633817C706377559e5f340A5276e, 2);
    _tokenSupply.increment();
    _safeMint(0x5c6204674bE94C377BbEd9A42367611759dADd90, 3);
    _tokenSupply.increment();
    _safeMint(0xb774aBDd0739EBC89d0EfEca1D38B8c274D518CE, 4);
    _tokenSupply.increment();

    uint mintIndex = _tokenSupply.current();
    for (uint i; i < 40; i++) {
    _safeMint(0xA7EE780B4136E70e3AC1590CAdCaAd05764563fE, mintIndex + i);
    _tokenSupply.increment();
    }
    }

    function mint(uint256 quantity) external payable {
        require(msg.value == PRICE * quantity, 'incorrect ether amount supplied');
        uint mintIndex = _tokenSupply.current();
        require(mintIndex + quantity < MAX_SUPPLY, 'exceeds token supply');
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, mintIndex + i);
            _tokenSupply.increment();
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory json = ".json";
        string memory baseURI = _baseTokenURI;
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), json)) : "";
    }

    function isApprovedForAll( address owner, address operator) public view override returns (bool) {
    return (operator == 0x7Be8076f4EA4A4AD08075C2508e481d6C946D12b) ? 
    true 
    : 
    super.isApprovedForAll(owner, operator);
    }

    function withdraw () public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        (bool status1, ) = 0xA7EE780B4136E70e3AC1590CAdCaAd05764563fE.call{value: (balance * 2) / 10}("");
        (bool status2, ) = 0x7Eb696df980734DD592EBDd9dfC39F189aDc5456.call{value: (balance * 2) / 10}("");
        (bool status3, ) = 0xc7E7747fa605633817C706377559e5f340A5276e.call{value: (balance * 5) / 100}("");
        (bool status4, ) = 0x5c6204674bE94C377BbEd9A42367611759dADd90.call{value: (balance * 5) / 100}("");
        require(status1 == true && status2 == true && status3 == true && status4 == true, 'withdraw failed');
    }

}