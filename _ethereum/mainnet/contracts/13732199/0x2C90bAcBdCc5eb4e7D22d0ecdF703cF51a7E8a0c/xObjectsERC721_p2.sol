//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract xObjectsERC721_p2 is ERC721Pausable, Ownable, RoyaltiesV2Impl {

    constructor() ERC721("xObjects", "XOBJ2") {
        mint();
    }

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
        return "https://xobj.com/p2/meta/";
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function mint() internal {
        _safeMint(msg.sender, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function claim() external payable {
        require(_tokenIdTracker.current() < 888, "Max tokens minted");
        if (_tokenIdTracker.current() > 499) {
            require(msg.value == 0.02 ether, "claiming costs 0.02 eth");
            mint();
            payable(owner()).transfer(0.02 ether);
        } else {
            if (msg.value >= 0.02 ether) {
                payable(owner()).transfer(msg.value);
            }
            mint();
        }
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
