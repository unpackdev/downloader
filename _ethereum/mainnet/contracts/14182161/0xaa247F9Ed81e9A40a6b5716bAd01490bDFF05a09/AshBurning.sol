// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC721CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";
import "./IAshCC.sol";

import "./IERC721.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./ERC165.sol";
import "./EnumerableSet.sol";

/**
 * Burn baby burn
 */
contract AshBurning is AdminControl, ICreatorExtensionTokenURI {

    using Strings for uint256;
    using Strings for uint16;

    address private _creator;
    string private _baseURI;
    string private _previewImage;

    uint _listingId;
    address _marketplace;
    IAshCC _ashCC;
    address _ashCCCore;
    address _ashForestCore;

    IERC20 _ashContract;
    uint _ashRate;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setAshForest(address ashF) public adminRequired {
      _ashForestCore = ashF;
    }

    function setAshContract(address ashContract, uint ashRate) public adminRequired {
      _ashContract = IERC20(ashContract);
      _ashRate = ashRate;
    }

    // Creator is creator core for ash cc
    function setRewardsCard(address ashCC, address ashCCCore) public adminRequired {
      _ashCC = IAshCC(ashCC);
      _ashCCCore = ashCCCore;
    }

    function mint(uint256[] calldata tokenIds, uint ashCCToken) public {
      // If you hold ashCC you only need to burn 1
      if (IERC721(_ashCCCore).balanceOf(msg.sender) > 0) {
        require(tokenIds.length == 1, "Have card, only need 1");
        require(IERC721(_ashForestCore).ownerOf(tokenIds[0]) == msg.sender, "Must own NFT");

        try IERC721(_ashForestCore).getApproved(tokenIds[0]) returns (address approvedAddress) {
            require(approvedAddress == address(this), "BurnRedeem: Contract must be given approval to burn NFT");
        } catch (bytes memory) {
            revert("BurnRedeem: Bad token contract");
        }

        try IERC721(_ashForestCore).transferFrom(msg.sender, address(0xdEaD), tokenIds[0]) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        IERC721CreatorCore(_creator).mintExtension(msg.sender);
        require(_ashContract.balanceOf(address(this)) >= _ashRate, "Can't pay out. Not funded");
        _ashContract.transfer(msg.sender, _ashRate);
        require(IERC721(_ashCCCore).ownerOf(ashCCToken) == msg.sender, "Must own card to get points");
        _ashCC.addPoints(ashCCToken, 11);
      }      
      
      // Else, you can burn 2
      else {
        require(tokenIds.length == 2, "Must burn 2");
        require(IERC721(_ashForestCore).ownerOf(tokenIds[0]) == msg.sender, "Must own NFT");
        require(IERC721(_ashForestCore).ownerOf(tokenIds[1]) == msg.sender, "Must own NFT");

        try IERC721(_ashForestCore).getApproved(tokenIds[0]) returns (address approvedAddress) {
            require(approvedAddress == address(this), "BurnRedeem: Contract must be given approval to burn NFT");
        } catch (bytes memory) {
            revert("BurnRedeem: Bad token contract");
        }
        try IERC721(_ashForestCore).getApproved(tokenIds[1]) returns (address approvedAddress) {
            require(approvedAddress == address(this), "BurnRedeem: Contract must be given approval to burn NFT");
        } catch (bytes memory) {
            revert("BurnRedeem: Bad token contract");
        }

        try IERC721(_ashForestCore).transferFrom(msg.sender, address(0xdEaD), tokenIds[0]) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        try IERC721(_ashForestCore).transferFrom(msg.sender, address(0xdEaD), tokenIds[1]) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        IERC721CreatorCore(_creator).mintExtension(msg.sender);
      }
    }

    function setBaseURI(string memory baseURI) public adminRequired {
      _baseURI = baseURI;
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }
}
