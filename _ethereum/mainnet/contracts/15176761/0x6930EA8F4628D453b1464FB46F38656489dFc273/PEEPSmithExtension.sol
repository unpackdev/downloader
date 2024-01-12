// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: PEEPS

import "./AdminControl.sol";
import "./IERC1155CreatorCore.sol";
import "./ICreatorExtensionTokenURI.sol";

import "./ERC165.sol";
import "./SafeMath.sol";
import "./MerkleProof.sol";

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//                                                                                    //
//    ████████████████████████████████████████████████████████████████████████████    //
//    █░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█    //
//    █░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█    //
//    █░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█    //
//    █░░▄▀░░██░░▄▀░░█░░▄▀░░█████████░░▄▀░░█████████░░▄▀░░██░░▄▀░░█░░▄▀░░█████████    //
//    █░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░▄▀░░█░░▄▀░░░░░░░░░░█    //
//    █░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█    //
//    █░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█░░░░░░░░░░▄▀░░█    //
//    █░░▄▀░░█████████░░▄▀░░█████████░░▄▀░░█████████░░▄▀░░█████████████████░░▄▀░░█    //
//    █░░▄▀░░█████████░░▄▀░░░░░░░░░░█░░▄▀░░░░░░░░░░█░░▄▀░░█████████░░░░░░░░░░▄▀░░█    //
//    █░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀▄▀▄▀▄▀▄▀░░█░░▄▀░░█████████░░▄▀▄▀▄▀▄▀▄▀░░█    //
//    █░░░░░░█████████░░░░░░░░░░░░░░█░░░░░░░░░░░░░░█░░░░░░█████████░░░░░░░░░░░░░░█    //
//    ████████████████████████████████████████████████████████████████████████████    //
//                                                                                    //
//                                        /¯¯\                                        //
//                                        \__/                                        //
//                                         ||                                         //
//                                         ||                                         //
//                                        |  |                                        //
//                                        |  |                                        //
//                                        |  |                                        //
//                                        |  |                                        //
//                                        |  |                                        //
//                                        |  |                                        //
//                                    .--.----.--.                                    //
//                                  .-----\__/-----.                                  //
//                          ___---¯¯////¯¯|\/|¯¯\\\\¯¯---___                          //
//                       /¯¯ __O_--////   |  |   \\\\--_O__ ¯¯\                       //
//                      | O?¯      ¯¯¯    |  |    ¯¯¯      ¯?O |                      //
//                      |  '    _.-.      |  |      .-._    '  |                      //
//                      |O|    ?..?      ./  \.      ?..?    |O|                      //
//                      | |     '?. .-.  | /\ |  .-. .?'     | |                      //
//                      | ---__  ¯?__?  /|\¯¯/|\  ?__?¯  __--- |                      //
//                      |O     \         ||\/||         /     O|                      //
//                      |       \  /¯?_  ||  ||  _?¯\  /       |                      //
//                      |       / /    - ||  || -    \ \       |                      //
//                      |O   __/  | __   ||  ||   __ |  \__   O|                      //
//                      | ---     |/  -_/||  ||\_-  \|     --- |                      //
//                      |O|            \ ||  || /            |O|                      //
//                      \ '              ||  ||        ^~DLF ' /                      //
//                       \O\    _-¯?.    ||  ||    .?¯-_    /O/                       //
//                        \ \  /  /¯¯¯?  ||  ||  ?¯¯¯\  \  / /                        //
//                         \O\/   |      ||  ||      |   \/O/                         //
//                          \     |      ||  ||      |     /                          //
//                           '.O  |_     ||  ||     _|  O.'                           //
//                              '._O'.__/||  ||\__.'O_.'                              //
//                                 '._ O ||  || O _.'                                 //
//                                    '._||  ||_.'                                    //
//                                       ||  ||                                       //
//                                       ||  ||                                       //
//                                       ||\/||                                       //
//                                       ||  ||                                       //
//                                        \  /                                        //
//                                         \/                                         //
//                                                                                    //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

contract PEEPSmithExtension is AdminControl, ICreatorExtensionTokenURI {
    using SafeMath for uint256;

    address private _core;
    uint256 private _currentTokenId;
    uint256 private _startTokenId;
    mapping(uint256 => string) private _baseURIs;

    mapping(uint256 => bytes32) public merkleRoot;
    mapping(uint256 => mapping(address => bool)) public tokenClaimed;
    mapping(uint256 => uint256) public costPreSale;
    mapping(uint256 => uint256) public costPublicSale;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public maxPreSaleSupply;
    mapping(uint256 => uint256) public count;
    mapping(uint256 => bool) public saleActive;
    mapping(uint256 => bool) public preSaleActive;

    modifier validToken(uint256 _tokenId) {
        require(
            _tokenId >= _startTokenId && _tokenId <= _currentTokenId,
            "Invalid token ID"
        );
        _;
    }

    modifier mintCompliancePreSale(uint256 _tokenId) {
        require(
            count[_tokenId] < maxPreSaleSupply[_tokenId] &&
                count[_tokenId] < maxSupply[_tokenId],
            "Max supply exceeded!"
        );
        _;
    }

    modifier mintPriceCompliancePreSale(uint256 _tokenId) {
        require(msg.value >= costPreSale[_tokenId], "Insufficient funds!");
        _;
    }

    modifier mintCompliancePublicSale(uint256 _tokenId) {
        require(count[_tokenId] < maxSupply[_tokenId], "Max supply exceeded!");
        _;
    }

    modifier mintPriceCompliancePublicSale(uint256 _tokenId) {
        require(msg.value >= costPublicSale[_tokenId], "Insufficient funds!");
        _;
    }

    function initialize(address core, uint256 currentTokenId)
        public
        adminRequired
    {
        _core = core;
        _currentTokenId = currentTokenId;
        _startTokenId = currentTokenId + 1;
    }

    function createNewToken(
        uint256 preSalePrice,
        uint256 publicSalePrice,
        uint256 tokenPreSaleSupply,
        uint256 tokenMaxSupply,
        string memory baseURI
    ) public adminRequired {
        uint256 _id = _getNextTokenId();
        _incrementTokenTypeId();

        costPreSale[_id] = preSalePrice;
        costPublicSale[_id] = publicSalePrice;
        maxPreSaleSupply[_id] = tokenPreSaleSupply;
        maxSupply[_id] = tokenMaxSupply;
        count[_id] = 1;
        saleActive[_id] = false;
        preSaleActive[_id] = false;
        _baseURIs[_id] = baseURI;

        address[] memory to = new address[](1);
        to[0] = msg.sender;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        string[] memory uris = new string[](1);
        uris[0] = baseURI;

        IERC1155CreatorCore(_core).mintExtensionNew(to, amounts, uris);
    }

    function mint(uint256 tokenId, bytes32[] calldata _merkleProof)
        public
        payable
        validToken(tokenId)
    {
        require(saleActive[tokenId] == true, "Sale has not started yet.");
        require(
            !tokenClaimed[tokenId][_msgSender()],
            "Address already claimed!"
        );
        if (preSaleActive[tokenId]) {
            _mintPreSale(tokenId, _merkleProof);
        } else {
            _mintPublic(tokenId);
        }
    }

    function _mintPreSale(uint256 _tokenId, bytes32[] calldata _merkleProof)
        private
        mintCompliancePreSale(_tokenId)
        mintPriceCompliancePreSale(_tokenId)
    {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot[_tokenId], leaf),
            "Invalid proof!"
        );

        tokenClaimed[_tokenId][_msgSender()] = true;
        address[] memory to = new address[](1);
        to[0] = msg.sender;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        count[_tokenId] = count[_tokenId] + 1;

        IERC1155CreatorCore(_core).mintExtensionExisting(to, tokenIds, amounts);
    }

    function _mintPublic(uint256 _tokenId)
        private
        mintCompliancePublicSale(_tokenId)
        mintPriceCompliancePublicSale(_tokenId)
    {
        tokenClaimed[_tokenId][_msgSender()] = true;
        address[] memory to = new address[](1);
        to[0] = msg.sender;
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;
        count[_tokenId] = count[_tokenId] + 1;

        IERC1155CreatorCore(_core).mintExtensionExisting(to, tokenIds, amounts);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            AdminControl.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function setBaseURI(uint256 tokenId, string memory baseURI)
        public
        validToken(tokenId)
        adminRequired
    {
        _baseURIs[tokenId] = baseURI;
        IERC1155CreatorCore(_core).setTokenURIExtension(tokenId, baseURI);
    }

    function tokenURI(address core, uint256 tokenId)
        external
        view
        override
        validToken(tokenId)
        returns (string memory)
    {
        require(core == _core, "Invalid token");
        return _baseURIs[tokenId];
    }

    function setPreSaleState(uint256 tokenId, bool state) public adminRequired {
        preSaleActive[tokenId] = state;
    }

    function setSaleState(uint256 tokenId, bool state) public adminRequired {
        saleActive[tokenId] = state;
    }

    function setMerkleRoot(uint256 tokenId, bytes32 _merkleRoot)
        public
        adminRequired
    {
        merkleRoot[tokenId] = _merkleRoot;
    }

    function setPreSalePrice(uint256 tokenId, uint256 price)
        public
        adminRequired
    {
        costPreSale[tokenId] = price;
    }

    function setPublicSalePrice(uint256 tokenId, uint256 price)
        public
        adminRequired
    {
        costPublicSale[tokenId] = price;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenID
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenID
     */
    function _incrementTokenTypeId() private {
        _currentTokenId++;
    }
}
