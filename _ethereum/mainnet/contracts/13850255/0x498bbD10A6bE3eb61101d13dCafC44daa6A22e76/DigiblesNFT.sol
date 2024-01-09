// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
/**
  ____  _       _ _     _           
 |  _ \(_) __ _(_) |__ | | ___  ___ 
 | | | | |/ _` | | '_ \| |/ _ \/ __|
 | |_| | | (_| | | |_) | |  __/\__ \
 |____/|_|\__, |_|_.__/|_|\___||___/
          |___/ 
 **/

contract DigiblesNFT is ERC721Enumerable, Ownable {
    event Swapped(address _seller, address _buyer, uint256 _price);

    using Strings for uint256;
    using SafeMath for uint256;

    mapping(uint256 => string) public _tokenURIs;
    mapping(uint256 => uint256) public tokenIdToPrice;

    string public _baseURIextended;
    address public feeAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _feeAddress
    ) ERC721(_name, _symbol) {
        feeAddress = _feeAddress;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function mint(
        address _to,
        address _seller,
        uint256 _tokenId,
        string memory tokenURI_
    ) external payable {
        require(msg.value > 0, "Incorrect value");

        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, tokenURI_);

        uint256 fee = msg.value.div(20);
        uint256 amount = msg.value.div(20).mul(19);

        payable(feeAddress).transfer(fee);
        payable(_seller).transfer(amount);
    }

    function atomicSwap(
        uint256 _tokenId,
        address _creator,
        uint256 _royalty
    ) external payable {
        require(msg.value > 0, "Incorrect value");

        address seller = ownerOf(_tokenId);
        uint256 fee = msg.value.div(20);
        uint256 amount = msg.value.div(20).mul(19);

        uint256 sellerAmount = amount.div(100).mul(_royalty);
        uint256 creatorAmount = amount.sub(sellerAmount);

        _transfer(seller, msg.sender, _tokenId);

        payable(feeAddress).transfer(fee);
        payable(seller).transfer(sellerAmount);
        payable(_creator).transfer(creatorAmount);

        emit Swapped(seller, msg.sender, msg.value);
    }

    function getTokenIds(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokensOfOwner = new uint256[](
            ERC721.balanceOf(_owner)
        );
        uint256 i;

        for (i = 0; i < ERC721.balanceOf(_owner); i++) {
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }
}
