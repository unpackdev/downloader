//SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract GoblinBbys is ERC721A, Ownable {
    using Strings for uint256;

    //@notice bbys mint deets
    uint256 constant public maxSupply = 5000;
    uint256 constant public maxBbysPerTx = 5;
    bool public isSaleEnabled;

    //@notice metadata
    bool public revealed;
    string private _baseTokenURI;

    //@notice royalties
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address private _royaltyAddress;
    uint256 private _royaltyPercentage;

    constructor(string memory baseTokenURI, address royaltyAddress, uint256 royaltyPercentage) ERC721A("GoblinBbys", "GOBBYS") {
        _mint(msg.sender, 100);
        _baseTokenURI = baseTokenURI;
        _royaltyAddress = royaltyAddress;
        _royaltyPercentage = royaltyPercentage;
    }

    function makeGoblinBbys(uint256 bbys) external {
        require(isSaleEnabled, "sale_not_bbys");
        require(totalSupply() + bbys <= maxSupply, "max_bbys");
        require(bbys <= maxBbysPerTx, "make_less_bbys");
        _mint(msg.sender, bbys);
    }

    function revealBbys(bool _reveal, string memory newURI) external onlyOwner {
        revealed = _reveal;
        _baseTokenURI = newURI;
    }

    function setSaleState(bool stateSale) external onlyOwner {
        isSaleEnabled = stateSale;
    }

    function editRoyaltyFee(address royaltyAddress, uint256 royaltyPercentage) external onlyOwner {
        _royaltyPercentage = royaltyPercentage;
        _royaltyAddress = royaltyAddress;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        if(revealed) {
            return string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"));
        } else {
            return currentBaseURI;
        }
    }
    
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}