////////////////////////////////////////////////////////////////////////////////
//                                                                            //
//                                                                            //
//                        ▓▓                                                  //
//                      ▓▓╬╬▓▓  ▓▓                                            //
//                      ██▓▓╬╬██╬╬██                                          //
//                  ████╬╬▓▓▓▓╬╬▓▓╬╬████                                      //
//                ██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██  ██████████                        //
//         ,██████▓▓░░▓▓▓▓▓▓░░░░░░▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓██                      //
//      ,,██▓▓▓▓▀▀====░░╝╝░░======░░╝╝▓▓▓▓▓▓╝╝░░░░░░╝╝▓▓██,,                  //
//    ▄▄██▓▓▀▀▀▀▄▄▄▄  ⁿⁿ░░ⁿⁿ▄▄▄▄  ⁿⁿ░░▓▓▓▓▀▀░░░░░░░░░░▀▀▓▓██                  //
//    ██▓▓▀▀░░  ▀▀██    ░░  ▀▀██    ░░▓▓▓▓░░░░░░░░░░░░░░▓▓██                  //
//    ██▓▓░░░░  ▄▄██    ░░  ▄▄██    ░░▓▓▓▓░░░░░░░░░░░░░░▓▓██                  //
//    ██▓▓░░░░▓▓╙╙╙╙  ≥≥░░≥≥╙╙╙╙  ≥≥░░▓▓▓▓▓▓░░░░░░░░░░▓▓▓▓██                  //
//    ██▓▓▓▓░░██φφφφφφ░░░░░░φφφφφφ░░░░▓▓▓▓▓▓▓▓░░░░░░▓▓▓▓██└└                  //
//    ─¬██▓▓▓▓██░░░░███▓░░████░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██──                    //
//        ████││░░░░││││░░││││░░░░░░░░│░▓▓▓▓▓▓████████        ████            //
//          ██░░                      ░░▓▓▓▓▓▓██            ██▓▓▓▓██          //
//          ██░░                      ░░▓▓▓▓██              ██╬╬▓▓▓▓██        //
//          ██░░                      ░░▓▓▓▓██                ██▓▓▓▓██        //
//          ▀▀▄▄░░,,,,,,,,,,,,,,,,,,░░▄▄▓▓▓▓██▄▄▄▄▄▄▄▄        ██▓▓▓▓██        //
//            ▀▀▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▓▓▓▓▓▓██████████▄▄▄▄    ██▓▓▓▓██        //
//              ▀▀▀▀▀▀████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓████▄▄▄▄██▓▓▓▓██        //
//                  ▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████████        //
//                ▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓╠╠╠╠╠╠╠░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██████▓▓      //
//              ██╬╬▓▓██▓▓╚╚╚╚╚╚╚╚╚╚░░░░░░░░╚╚╚░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬▓██    //
//              ██▓▓▓▓██▓▓░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╬    //
//              ██▓▓▓▓██▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//            ██▓▓▓▓▓▓██▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//            ██▓▓▓▓▓▓██▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓    //
//            ██▓▓▓▓▓▓▓▓██▓▓▄▄░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓████▓▓▓▓▓▓▓▓▓▓    //
//          ▄▄██▓▓▓▓▓▓▓▓██▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▀▀▓▓▓▓████▓▓▓▓▓▓▓▓    //
//          ██▓▓▓▓▓▓▓▓▓▓████▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░▀▀▓▓▓▓████▓▓▓▓▓▓    //
//                                                                            //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./ERC721A.sol";
import "./Ownable.sol";

contract Chimphers is ERC721A, Ownable {
    using Strings for uint256;
    uint256 private price = 0.039 ether;
    uint16 constant MAX = 5555;
    string private baseuri;
    string public preui = 'ipfs://QmSXud6UgTqWYk9wMsCXLwBfvCLdPNMgpNpARWxWRKPU8K';

    constructor() ERC721A("Chimphers", "CHIMPH") Ownable() { }

    function mint(uint16 _quantity) public payable {

        require(_totalMinted() + _quantity <= MAX, "Max reached");
        require(_quantity * price <= msg.value, "Ether value wrong");

        _safeMint(_msgSender(), _quantity);
    }

    function ownermint(uint16 _quantity) public onlyOwner {

        require(_totalMinted() + _quantity <= MAX, "Max reached");
        _safeMint(_msgSender(), _quantity);
    }

    
    function setBaseURI(string calldata _uri) external onlyOwner {
        baseuri = _uri;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseuri;
    }


	function _startTokenId() internal pure override returns (uint) {
		return 1;
	}

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
    function getPrice() external view returns (uint256) {
        return price;
    }
	function mintTo(address _to, uint16 _quantity) external onlyOwner {
        require(_totalMinted() + _quantity <= MAX, "Maximum reached");
		_safeMint(_to, _quantity);
	}

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

	function tokenURI(uint256 _tokenId) public override view returns (string memory)
	{

        require(_exists(_tokenId), "Nonexistent token");
        return bytes(_baseURI()).length == 0 ? preui : string(abi.encodePacked(_baseURI(), _tokenId.toString()));
	}
}