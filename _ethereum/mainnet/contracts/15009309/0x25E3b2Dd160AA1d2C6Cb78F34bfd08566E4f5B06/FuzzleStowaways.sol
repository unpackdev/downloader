// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract FuzzleStowaways is
    ERC721Enumerable,
    ERC721Burnable,
    Ownable
{
    using Address for address payable;
    using Strings for uint256;

    string public constant PROVENANCE = "QmR8XZwKMW4m6fr1Yaf5TnVd9y4zb5uFBMk3RCzZ2HvPzs";    
    uint256 public constant maxSupply = 100;

    event onAirdrop(
        address[] receivers, 
        uint256[] tokenIds,
        uint256 timestamp
    );

    constructor() ERC721("FuzzleStowaways", "FSTWY") {}

    function airdrop(address[] memory receivers) external onlyOwner {
      require(receivers.length != 0, "receivers empty");
      require(totalSupply() < maxSupply, "reached max supply");

      uint256[] memory tokenIds = new uint256[](receivers.length);

      for (uint256 i = 0; i < receivers.length; i++) {
        uint256 tokenId = totalSupply();
        tokenIds[i] = tokenId;
        _safeMint(receivers[i], tokenId);
      }

      emit onAirdrop(
        receivers,
        tokenIds, 
        block.timestamp
      );
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return string(abi.encodePacked("ipfs://", PROVENANCE, "/"));
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(),".json"))
                : "";
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return
          interfaceId == type(IERC721).interfaceId ||
          interfaceId == type(IERC721Metadata).interfaceId ||
          super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) 
      internal 
      override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}