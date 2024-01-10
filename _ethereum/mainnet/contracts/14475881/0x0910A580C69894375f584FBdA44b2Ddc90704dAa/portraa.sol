// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";


/////////////////////////////////////////////////////////////////////////////////////////////////
//                   ......                       ......                                       //
//                  .000000:                     =00000%                                       //
//                  .000000:                     =00000%                                       //
//                  .000000:                     =00000%                                       //
//                  .000000:                     =00000%                                       //
//                  .000000: +%%%%%*     #%%%%%- =00000%  #%%%%%-    :%%%%%%.                  //
//                  .000000: *00000#     000000- =00000%  %00000=    -000000.                  //
//                  .000000: +00000#     000000- =00000%  %00000=    :000000.                  //
//                  .000000: *00000#     000000- =00000%  %00000=    -000000.                  //
//                  .000000: *00000#     000000- =00000%  %00000=    :000000.                  //
//                  .000000: *00000#     000000- =00000%  %00000=    -000000.                  //
//                  .000000: +000000+..:*000000- =00000%  %00000%-..-%000000.                  //
//                  .000000: :00000000000000000- =00000%  =00000000000000000.                  //
//                  .000000:  :%000000000000000- =000000   =0000000000000000.                  //
//                  .******.    -+#%%%#=:+*****: -*****+     -*#%%#*=:******                   //
//               ....         ..   ..                   ..  .  ...          ...                //
//               .#000000-   *000000+ .#000000=   +000000*  *000000+   =000000*.               //
//                 *000000+.#000000-    +000000+.#000000=    =000000*.*000000+                 //
//                  -000000000000#.      -000000000000%:      :%00000000000%:                  //
//                   .%000000000+         .#000000000*          *000000000#.                   //
//                     %0000000=            #0000000*            *0000000#                     //
//                    *000000000=          +000000000=          =000000000+                    //
//                  :%00000000000*       .#00000000000*.      .#00000000000#.                  //
//                 =000000*:%00000%.    -000000#:%00000%:    :%00000%:#000000-                 //
//               .#000000=  .#000000= .*000000+   *000000+  +000000*   *000000*.               //
//               =++++++-     =++++++:-*+++++-     =++++++::*+++++=     -+++++*-               //
//                                                                                             //
//                                         PORTR(AA)                                           //
//      a curated semi-generative , neural-network assisted , automatic portrait generator.    //
//                                                                                             //
//                                       @luluixixix                                           //
//                                                                                             //
/////////////////////////////////////////////////////////////////////////////////////////////////

contract portraa is ReentrancyGuard, ERC721URIStorage, Ownable {

    using Strings for uint256;
    /* price */
    uint256 public mintPrice = 0.2 ether;
    /* royalties */
    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES         = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;
    event ChangeMintPrice(uint256 mintPrice);
    
    constructor() ERC721("portraa", "PORTRAA") {
        _royaltyRecipient = payable(msg.sender);
        _royaltyBps = 2500;
        }

    function changeMintPrice(uint256 _mintPrice) external onlyOwner{
        mintPrice = _mintPrice;
        emit ChangeMintPrice(_mintPrice);
    }
    
    function getMintPrice(uint256) external view returns (uint256 _mintPrice) {
        return mintPrice;
    }
    
    function contractURI() public pure returns (string memory) {
        return "https://arweave.net/viqKWky_V-FMc3edU879tq7gbs6clT4PVUlrBxa9R2M";
    }
    
    function mintportraa(string memory tokenURI,uint collecnum) public payable nonReentrant {
        require(msg.value == mintPrice , "Invalid eth sent");
        require(msg.sender == tx.origin, "NOT EOA"); //no bots
        _safeMint(msg.sender, collecnum);
        _setTokenURI(collecnum, tokenURI);
    }
    
    function mint3portraa(string memory tURI1, uint n1, string memory tURI2, uint n2, string memory tURI3, uint n3) public payable nonReentrant {
        require(msg.value == 3*mintPrice , "Invalid eth sent");
        require(msg.sender == tx.origin, "NOT EOA"); //no bots
        // mint 3 tokens
        _safeMint(msg.sender, n1);
        _setTokenURI(n1, tURI1);
        _safeMint(msg.sender, n2);
        _setTokenURI(n2, tURI2);
        _safeMint(msg.sender, n3);
        _setTokenURI(n3, tURI3);
    }
    
    /*** @dev See {IERC165-supportsInterface}.*/
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || interfaceId == _INTERFACE_ID_ROYALTIES
               || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981 || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    /*** ROYALTIES implem: check EIP-2981 https://eips.ethereum.org/EIPS/eip-2981**/
    function updateRoyalties(address payable recipient, uint256 bps) external onlyOwner {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
            }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
            }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }
    
    function withdraw() external onlyOwner{
        uint balance = address(this).balance;
        require(balance > 0, "Bad Balance");
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "ETH failed");
    }
}
