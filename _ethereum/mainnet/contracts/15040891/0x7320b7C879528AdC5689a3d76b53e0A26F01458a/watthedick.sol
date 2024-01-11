// SPDX-License-Identifier: MIT

        ///////////////////////////////////////////////////////////////////////////
       //                                                                       //
      // //    // ////// ////// ////// //  // ////// /////   // ////// //  //  //
     // //    // //  //   //     //   //  // //     //   // // //     // //   //
    // // // // //////   //     //   ////// ////// //   // // //     ////    //
   // // // // //  //   //     //   //  // //     //   // // //     //  //  //
  // //////// //  //   //     //   //  // ////// //////  // ////// //   // //
 //                                                                       //
///////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721A.sol";

contract WatTheDick is ERC721A, Ownable {
    using Strings for uint256;
    uint256 public constant TOTAL_DICKS = 5555;
    uint256 public constant MAX_DICK_MINT = 4;
    uint256 public constant TEAM_DICKS = 150;
    uint256 public constant DICK_PRICE = 0.003 ether;

    string private _baseTokenURI;

    mapping(address => uint) public addressDicks;
    mapping(address => bool) public addressHaveFreeDick;

    constructor(
        string memory _initBaseURI
    ) ERC721A("WatTheDick", "WTD") {
        _baseTokenURI = _initBaseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function mint(uint256 dicks) public payable {
        require(dicks <= MAX_DICK_MINT, "Only 4 dicks in one hand");
        require(addressDicks[_msgSender()] < MAX_DICK_MINT, "You aldredy get dicks");
        require(totalSupply() + dicks <= TOTAL_DICKS, "Dicks ran out");
        if(!addressHaveFreeDick[_msgSender()]) {
            require(msg.value >= ( dicks - 1 ) * DICK_PRICE, "Not enough ETH");
            addressDicks[_msgSender()] += dicks;
            addressHaveFreeDick[_msgSender()] = true;
            _safeMint(msg.sender, dicks);
        } else {
            require(msg.value >= dicks * DICK_PRICE, "Not enough ETH");
            addressDicks[_msgSender()] += dicks;
            _safeMint(msg.sender, dicks);
        }
    }

    function ownerMint() external onlyOwner {
        require(totalSupply() + TEAM_DICKS <= TOTAL_DICKS, "Dicks ran out");
        _safeMint(msg.sender, TEAM_DICKS);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "NFT does not exist");
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    function withdrawEther() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
