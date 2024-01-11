// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./AdminControl.sol";
import "./IERC1155CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./IERC1155.sol";
import "./IERC20.sol";
import "./Strings.sol";
import "./ERC165.sol";

contract Burn is AdminControl, ICreatorExtensionTokenURI {

    using Strings for uint256;
    using Strings for uint16;

    address private _creator;
    string private _baseURI;
    string private _previewImage;

    uint _listingId;
    address _marketplace;
    address _entropyContract;

    uint _ashRateLow;
    uint _ashRateHigh;
    IERC20 _ashContract;

    uint _burnableToken;
    uint _redTokenId;
    uint _blueTokenId;

    string _redToken;
    string _blueToken;

    mapping(address => uint) _numBlues;
    mapping(address => uint) _numReds;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || AdminControl.supportsInterface(interfaceId) || super.supportsInterface(interfaceId);
    }

    function setEntropyContract(address entropyContract) public adminRequired {
      _entropyContract = entropyContract;
    }

    function preMint() public adminRequired {
      address[] memory addressToSend = new address[](1);
      addressToSend[0] = msg.sender;
      uint[] memory amount = new uint[](1);
      amount[0] = 1;
      string[] memory uris = new string[](1);
      uris[0] = "";
      IERC1155CreatorCore(_creator).mintExtensionNew(addressToSend, amount, uris);
    }

    function configureTokens(uint burnableToken, uint redToken, uint blueToken) public adminRequired {
      _burnableToken = burnableToken;
      _redTokenId = redToken;
      _blueTokenId = blueToken;
    }

    function setAshContract(address ashContract, uint ashRateLow, uint ashRateHigh) public adminRequired {
      _ashContract = IERC20(ashContract);
      _ashRateLow = ashRateLow;
      _ashRateHigh = ashRateHigh;
    }

    function withdraw(address recipient, address erc20, uint256 amount) external adminRequired {
        IERC20(erc20).transfer(recipient, amount);
    }

    function mint(uint256 desiredToken, uint whichMethod) public {
      require(desiredToken == _redTokenId || desiredToken == _blueTokenId, "Can only mint red or blue");

      if (desiredToken == _redTokenId) {
        require(_numReds[msg.sender] < 2, "Can only mint 2 reds.");
        _numReds[msg.sender]++;
      } else if (desiredToken == _blueTokenId) {
        require(_numBlues[msg.sender] < 2, "Can only mint 2 blues.");
        _numBlues[msg.sender]++;
      }
      if (whichMethod == 0) {
        require(IERC1155(_entropyContract).balanceOf(msg.sender, _burnableToken) > 1, "Must own NFT");
        require(IERC1155(_entropyContract).isApprovedForAll(msg.sender, address(this)), "BurnRedeem: Contract must be given approval to burn NFT");

        uint[] memory tokenIds = new uint[](1);
        tokenIds[0] = _burnableToken;
        uint[] memory burnAmounts = new uint[](1);
        burnAmounts[0] = 2;
        try IERC1155CreatorCore(_entropyContract).burn(msg.sender, tokenIds, burnAmounts) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
        uint[] memory numToSend = new uint[](1);
        numToSend[0] = 1;
        uint[] memory tokenToSend = new uint[](1);
        tokenToSend[0] = desiredToken;

        IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, numToSend);
      } else if (whichMethod == 1) {
        require(_ashContract.allowance(msg.sender, address(this)) >= _ashRateLow, "You have not approved ASH.");
        require(_ashContract.balanceOf(msg.sender) >= _ashRateLow, "You do not have enough ASH.");
        require(IERC1155(_entropyContract).balanceOf(msg.sender, _burnableToken) > 0, "Must own NFT");
        require(IERC1155(_entropyContract).isApprovedForAll(msg.sender, address(this)), "BurnRedeem: Contract must be given approval to burn NFT");


        uint[] memory tokenIds = new uint[](1);
        tokenIds[0] = _burnableToken;
        uint[] memory burnAmounts = new uint[](1);
        burnAmounts[0] = 1;

        try IERC1155CreatorCore(_entropyContract).burn(msg.sender, tokenIds, burnAmounts) {
        } catch (bytes memory) {
            revert("BurnRedeem: Burn failure");
        }

        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
        uint[] memory numToSend = new uint[](1);
        numToSend[0] = 1;
        uint[] memory tokenToSend = new uint[](1);
        tokenToSend[0] = desiredToken;
        require(_ashContract.transferFrom(msg.sender, address(this), _ashRateLow));
        IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, numToSend);
      } else if (whichMethod == 2) {
        require(_ashContract.allowance(msg.sender, address(this)) >= _ashRateHigh, "You have not approved ASH.");
        require(_ashContract.balanceOf(msg.sender) >= _ashRateHigh, "You do not have enough ASH.");
        address[] memory addressToSend = new address[](1);
        addressToSend[0] = msg.sender;
        uint[] memory numToSend = new uint[](1);
        numToSend[0] = 1;
        uint[] memory tokenToSend = new uint[](1);
        tokenToSend[0] = desiredToken;

        require(_ashContract.transferFrom(msg.sender, address(this), _ashRateHigh));
        IERC1155CreatorCore(_creator).mintExtensionExisting(addressToSend, tokenToSend, numToSend);      }
    }

    function setURIs(string memory redToken, string memory blueToken) public adminRequired {
      _redToken = redToken;
      _blueToken = blueToken;
    }

    function tokenURI(address creator, uint256 tokenId) external view override returns (string memory) {
        require(creator == _creator, "Invalid token");
        if (tokenId == _redTokenId) {
          return _redToken;
        } else if (tokenId == _blueTokenId) {
          return _blueToken;
        }
        return "";
    }
}