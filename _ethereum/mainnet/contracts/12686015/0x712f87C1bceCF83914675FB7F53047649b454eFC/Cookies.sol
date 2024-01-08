pragma solidity ^0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract Cookies is ERC721, Ownable {
    using SafeMath for uint256;
    bool public hasSaleStarted = false;
    uint256 public constant COOKIE_PRICE = 0.005 * 10 ** 18;

    string public METADATA_PROVENANCE_HASH = "";

    string public constant R = "The first daily dynamic Non-Fungible Token. Everyday new lucky numbers to you.";

    constructor(string memory baseURI) ERC721("Cookies","COOKIES") public {
        setBaseURI(baseURI);
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function getCookie(uint256 numCookies) public payable {
        require(hasSaleStarted, "Sale hasn't started");
        require(msg.value >= COOKIE_PRICE.mul(numCookies), "Ether value sent is below the price");

        for (uint i = 0; i < numCookies; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }
    
    function giftCookie(uint256 numCookies, address receiver) public payable {
        require(hasSaleStarted, "Sale hasn't started");
        require(msg.value >= COOKIE_PRICE.mul(numCookies) || msg.sender == owner(), "Ether value sent is below the price");

        for (uint i = 0; i < numCookies; i++) {
            uint mintIndex = totalSupply();
            _safeMint(receiver, mintIndex);
        }
    }
    
    function setProvenanceHash(string memory _hash) public onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function startSale() public onlyOwner {
        hasSaleStarted = true;
    }

    function pauseSale() public onlyOwner {
        hasSaleStarted = false;
    }
    
    function withdrawAll() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}