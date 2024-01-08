//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract xObjectsERC721_p1 is ERC721Pausable, Ownable, RoyaltiesV2Impl {

    constructor() ERC721("xObject", "XOBJ1") {
        mint("3429334646556");
    }

    struct Metadata {
        string hashed_content;
    }

    mapping(uint256 => Metadata) content;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    receive() external payable {
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://xobj.com/p1/meta/";
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function mint(string memory hashed_content) internal {
        content[_tokenIdTracker.current()] = Metadata(hashed_content);
        _safeMint(msg.sender, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function claim(string calldata hashed_content) external payable {
        require(_tokenIdTracker.current() < 6900, "Max tokens minted");
        require(bytes(hashed_content).length != 0 , "string cannot be empty");
        require(bytes(hashed_content).length < 32 , "string too long");
        require(msg.value == 0.036 ether, "claiming costs 0.036 eth");
        mint(hashed_content);
        payable(owner()).transfer(0.036 ether);
    }

    function get(uint256 tokenId) external view returns (string memory hashed_content) {
        require(_exists(tokenId), "token not minted");
        Metadata memory xobj = content[tokenId];
        hashed_content = xobj.hashed_content;
    }

    function setRoyalties(uint _tokenId, address payable _royaltiesReceipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesReceipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if(_royalties.length > 0) {
            return (_royalties[0].account, (_salePrice * _royalties[0].value)/10000);
        }
        return (address(0), 0);

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

}
