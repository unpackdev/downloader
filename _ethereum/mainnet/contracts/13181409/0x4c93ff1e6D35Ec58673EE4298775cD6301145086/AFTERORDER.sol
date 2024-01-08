// SPDX-License-Identifier: MIT

/*

MMMMMMMMMMMMMMMMMMMMMMMMWXOxoc;'...          ...';coxOXWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMN0xc,.                            .cKMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMWXkl,.                                .oNMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNkc.                                   .oNMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWMMKd,                                      lNMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMWKl.                                       cXMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMXd.                                        :XMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMWk,                                         :XMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMXl.                                         ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMK;                                          ;KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMM0,                                          ,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMK,                                          ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MX:                                          'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
Wo                      'clllllc.  'lllllllll0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
O.                     :KMMMMMMWk. 'OMMMMMMMMMWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMM
l                     ;KMMMNNWMMWk. ,0MMMMMMMMKc''''''''',xWMMMMMMMMMMMMMMMMMMMM
'                    ,0MMMWd,kWMMWx. ,0MMMMMWNWx.         .xWMMMMMMMMMMMMMMMMMMM
.                   '0MMMWd. 'OWMMWd. ;KMMMNllXWd.....     .xWMMMMMMMMMMMMMMMMMM
                   'OMMMWx.   ,0MMMWd..kMMNl  cXWK0K00O:    .kWMMMMMMMMMMMMMMMMM
                  .OWMMWx.     ;KMMMNxdNMWo    lNMMMMMMK:    .OWMMMMMMMMMMMMMMMM
                 .kWMMWk.       ;KMMMWWMMWd.    lNMMMMMMK;    'OMMMMMMMMMMMMMMMM
                .xWMMWO. .......'dNMMMNKKNNo.   .oNMMMMMMK,    ,0MMMMMMMMMMMMMMM
.              .xWMMWO' 'kXXNXXXXNWMMWd..lNNo    .dWMMMMMM0,    ,KMMMMMMMMMMMMMM
;             .dWMMM0, .kWWMMMMMMMMMWx.  .oNNl    .:ooooooo;     ;KMMMMMMMMMMMMM
d.            ,xkkkx,  :xkkkkkkkOXMWx.    .dWXc                   :XMMMMMMMMMMMM
X;                              ;KWk.      .xWX:                   :XMMMMMMMMMMM
Mk.                            ,0WWkooooooookNMXxoooooooooooooooooodKMMMMMMMMMMM
MWd.                          '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMNo.                        'OMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMNo.                      .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMWx.                    .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMW0;                  .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMNd.               .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMKl.            .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMWKl.         .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMXd,       lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMNOo,.  lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMW0dxXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

*/

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC165.sol";
import "./Strings.sol";

import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

contract AFTERORDER is Ownable, ERC165, ICreatorExtensionTokenURI {

    using Strings for uint256;
    using Strings for uint;

    string public PROVENANCE = "";
    uint256 public constant MAX_SUPPLY = 3000;
    uint256 public constant TOKEN_PRICE = 0.06 ether;
    uint256 public constant NUM_RESERVED_TOKENS = 170;
    uint public constant MAX_PURCHASE = 5;
    bool public saleIsActive = false;

    string private _baseURIextended;
    address private _creator;
    uint private _numMinted;
    mapping(uint256 => uint) _tokenEdition;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator && _tokenEdition[tokenId] != 0, "Invalid token");
        return string(abi.encodePacked(_baseURIextended, (_tokenEdition[tokenId] - 1).toString()));
    }

    function totalSupply() external view returns (uint) {
        return _numMinted;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function mintThroughCreator(address to) private {
        _numMinted += 1;
        _tokenEdition[IERC721CreatorCore(_creator).mintExtension(to)] = _numMinted;
    }

    function reserve() public onlyOwner {        
        for (uint i = 0; i < NUM_RESERVED_TOKENS; i++) {
            mintThroughCreator(msg.sender);
        }
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint token");
        require(numberOfTokens <= MAX_PURCHASE, "Exceeded max purchase amount");
        require(_numMinted + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed max supply of tokens");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            if (_numMinted < MAX_SUPPLY) {
                mintThroughCreator(msg.sender);
            }
        }
   }
}
