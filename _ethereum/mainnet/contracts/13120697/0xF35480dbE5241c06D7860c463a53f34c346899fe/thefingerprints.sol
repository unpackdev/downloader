// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";

contract TheFingerprints is ERC721, Ownable {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    
    address public payoutAddress;

    constructor() ERC721("The Fingerprints", "FNGPTS") {
        payoutAddress = msg.sender;
    }

    function mint(uint256 tokenId) external returns (uint256) {
        require(tokenId >= 1 && tokenId <= 10, "Invalid token id");
        _safeMint(msg.sender, tokenId);
        return tokenId;
    }

    function updatePayoutAddress(address newPayoutAddress) public onlyOwner {
        payoutAddress = newPayoutAddress;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 amount) {
        uint256 fivePercent = SafeMath.div(SafeMath.mul(salePrice, 500), 10000);
        return (payoutAddress, fivePercent);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://swark.art/api/thefingerprints/";
    }
}
