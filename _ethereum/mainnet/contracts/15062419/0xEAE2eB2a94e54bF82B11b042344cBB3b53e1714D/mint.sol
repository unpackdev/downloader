// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Pausable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./AccessControl.sol";
import "./Strings.sol";
import "./EIP2981.sol";
import "./console.sol";

contract VXNFT is ERC721URIStorage, ERC2981PerTokenRoyalties , AccessControl,  Ownable {

    mapping(address => bool) public usersList;
    mapping(uint256 => address) public _tokenCreators;
    struct NFTVoucher {
        uint256 tokenId;
        string uri;
        address creator;
    }


    uint256 public counter = 0;
    
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC2981Base, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    
    function mint(NFTVoucher calldata voucher, uint256 royaltyValue) external returns (uint) {
        require(royaltyValue > 0 , "Royalty must be greater than 0");
        require(counter < 1000, "Address length sould be less than 1000");
        require(!usersList[voucher.creator], "Minter can mint only 1 NFT");
        _mint(voucher.creator, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);        
        _setTokenRoyalty(voucher.tokenId, voucher.creator, royaltyValue);
        _tokenCreators[voucher.tokenId] = voucher.creator;
        usersList[voucher.creator] = true;
        counter++;
        return voucher.tokenId;
    }


    function getCreator(uint256 tokenId) external view returns (address) {
        return _tokenCreators[tokenId];
    }

    function getTokenRoyalty(uint256 tokenId) external view returns (RoyaltyInfo memory _royaltyInfo) {
        return _getTokenRoyalty(tokenId);
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     * openzeppelin/contracts/token/ERC721/ERC721Burnable.sol
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        _burn(tokenId);
    }

    function _baseURI() internal override pure returns (string memory) {
        return "";
    }


    function approveBulk(address to, uint256[] memory tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            approve(to, tokenIds[i]);
        }
    }

    function getApprovedBulk(uint256[] memory tokenIds) external view returns (address[] memory) {
        address[] memory tokenApprovals = new address[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            tokenApprovals[i] = getApproved(tokenIds[i]);
        }
        return tokenApprovals;
    }
    
}
