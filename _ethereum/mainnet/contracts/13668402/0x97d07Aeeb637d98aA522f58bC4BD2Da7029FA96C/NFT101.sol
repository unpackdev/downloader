//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./IERC2981.sol";
import "./ERC165Storage.sol";

contract NFT101 is ERC721, IERC2981, ERC165Storage {
    address public creator;
    address private royaltyAddress;
    uint256 private royaltyPercent;
    string public uri;

    // bytes4 constants for ERC165
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_IERC2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_IERC721Metadata = 0x5b5e139f;

    event UpdatedRoyalties(address newRoyaltyAddress, uint256 newPercentage);

    constructor(
        string memory $name,
        string memory $symbol,
        address $creator,
        address $minter,
        uint256 $tokenId,
        string memory $uri
    ) ERC721($name, $symbol) {
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_IERC2981);
        _registerInterface(_INTERFACE_ID_IERC721Metadata);
        creator = $creator;
        uri = $uri;
        _setRoyalties($creator, 1000); // 10% royalty
        _safeMint($minter, $tokenId);
    }

    function supportsInterface(bytes4 $interfaceId)
        public
        view
        override(ERC165Storage, ERC721, IERC165)
        returns (bool)
    {
        return super.supportsInterface($interfaceId);
    }

    function tokenURI(uint256 $tokenId) public view virtual override returns (string memory) {
        require(_exists($tokenId), "ERC721Metadata: URI query for nonexistent token");
        return uri;
    }

    function setRoyaltyInfo(address $royaltyAddress, uint256 $percentage) public onlyCreator {
        _setRoyalties($royaltyAddress, $percentage);
        emit UpdatedRoyalties($royaltyAddress, $percentage);
    }

    function royaltyInfo(uint256, uint256 $salePrice)
        external
        view
        override(IERC2981)
        returns (address _receiver, uint256 _royaltyAmount)
    {
        _receiver = royaltyAddress;

        // This sets percentages by price * percentage / 10000
        _royaltyAmount = ($salePrice * royaltyPercent) / 10000;
    }

    function _setRoyalties(address $receiver, uint256 $percentage) internal {
        royaltyAddress = $receiver;
        royaltyPercent = $percentage;
    }

    modifier onlyCreator() {
        require(msg.sender == creator,"!owner");
        _;
    }
}
