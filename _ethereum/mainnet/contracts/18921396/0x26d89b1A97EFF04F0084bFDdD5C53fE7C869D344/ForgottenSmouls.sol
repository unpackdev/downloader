pragma solidity ^0.8.20;

import "./Strings.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";

contract ForgottenSmouls is ERC721, Ownable {
    IERC721 public originalNFT;
    string public baseURI;

    constructor() ERC721("Forgotten Smouls", "FS") Ownable(msg.sender) {
        originalNFT = IERC721(0x251b5F14A825C537ff788604eA1b58e49b70726f);
    }

    function setOriginalNFT(address _originalNFT) public onlyOwner {
        originalNFT = IERC721(_originalNFT);
    }

    function contractURI() public pure returns (string memory) {
        string
            memory json = '{"name": "Forgotten Smouls","description":"Wizards were burned into souls. Souls were smolled into Forgotten Smouls."}';
        return string.concat("data:application/json;utf8,", json);
    }

    function claim(uint256 tokenId) public {
        require(
            originalNFT.ownerOf(tokenId) == msg.sender,
            "You do not own the NFT in the original contract"
        );
        _safeMint(msg.sender, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function uri(uint256 tokenId) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }
}
