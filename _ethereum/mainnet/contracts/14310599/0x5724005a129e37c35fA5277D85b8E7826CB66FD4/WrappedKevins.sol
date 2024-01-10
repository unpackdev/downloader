// SPDX-License-Identifier: GPL-3.0

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Holder.sol";

pragma solidity ^0.8.0;

interface IPixelmon is IERC721 {
    function tokenURI(uint256 id) external view returns (string memory);
}

contract WrappedKevins is ERC721, ERC721Holder, Ownable {
    using Strings for uint256;

    address public constant pixelmonContract =
        0x32973908FaeE0Bf825A343000fE412ebE56F802A;

    string public constant kevinImage =
        "https://tbi2twxegkxhiaetkxigpewdmtxulieagrqawc3tya3zmylk.arweave.net/mFGp2uQyrnQAk1XQZ5LDZO9FoIA0YAsLc8A_3l_mFqE";

    mapping(uint256 => bool) public kevinTokenIds;

    uint256 private _currSupply;

    constructor() ERC721("Wrapped Kevins", "WKEVINS") {}

    // to add more kevin Ids when new ones hatch
    function addKevinTokenIds(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            kevinTokenIds[tokenIds[i]] = true;
        }
    }

    // receive pixelmon, mint wrapped pixelmon back
    function wrap(uint256 tokenId) external {
        require(kevinTokenIds[tokenId], "not a valid kevin token Id");
        unchecked {
            _currSupply++;
        }
        IPixelmon(pixelmonContract).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        _mint(msg.sender, tokenId);
    }

    // receive wrapped pixelmon, burn, then return pixelmon back
    function unwrap(uint256 tokenId) external {
        require(kevinTokenIds[tokenId], "not a valid kevin token Id");
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "not approved or owner"
        );
        unchecked {
            _currSupply--;
        }
        _burn(tokenId);
        IPixelmon(pixelmonContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        );
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

        return
            string(
                abi.encodePacked(
                    '{"name": "Kevin #',
                    tokenId.toString(),
                    '", "description": "Wrapped Kevins are original Kevins preserved on a new contract. The underlying image is fully on-chain and no royalties are collected. Kevin has been set free.", "image":"',
                    kevinImage,
                    '","attributes": [{"trait_type": "Species", "value": "Kevin"}]}'
                )
            );
    }

    function totalSupply() public view returns (uint256) {
        return _currSupply;
    }
}
