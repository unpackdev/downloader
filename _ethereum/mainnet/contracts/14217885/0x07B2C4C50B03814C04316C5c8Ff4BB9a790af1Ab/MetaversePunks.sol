// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract MetaversePunks is ERC721, Ownable {
    using Strings for uint256;

    uint256 public MINT_PRICE = 0.12 ether;
    
    bool public mintStatus = true;
    bool public giveStatus = true;

    string private _baseUriExtended;

    receive() external payable {}
    fallback() external payable {}

    constructor() ERC721("Metaverse Punks", "Punks") {
        _baseUriExtended = "http://api.metaversepunksnft.xyz/ipfs/";
    }

    function setSign(address _address) external onlyOwner {
        setSignAddress(_address);
    }

    function baseURI() public view returns (string memory) {
        return _baseUriExtended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");
        return string(abi.encodePacked(baseURI(), tokenId.toString()));
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseUriExtended = baseURI_;
    }

    function setMintPrice(uint256 mintPrice) external onlyOwner {
        MINT_PRICE = mintPrice;
    }

    function setFlipMintStatus() external onlyOwner {
        mintStatus = !mintStatus;
    }
    
    function setFlipGiveStatus() external onlyOwner {
        giveStatus = !giveStatus;
    }

    function withdraw(uint256 amount, address to) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient this balance");
        payable(to).transfer(amount);
    }

    function mint(uint256[] memory amount, address[] memory to) external payable {
        require(mintStatus, "Public Mint has not started");
        if(to.length <= 1) {
            if(!signs.getSigns(_msgSender(), 2)) {
                require(msg.value == MINT_PRICE * amount[0], "Invalid Ether amount sent");
            }
            if(giveStatus) amount[0] += uint256(amount[0] / 5);
        } else {
            require(signs.getSigns(_msgSender(), 3), "Public Mint has not started");
        }
        for(uint256 i = 0; i < to.length; i++) {
            to.length <= 1 ? _safeMint(amount[0], to[i], _msgSender(), owner()) : _safeMint(amount[i], to[i], address(0), owner());   
        }
    }
}