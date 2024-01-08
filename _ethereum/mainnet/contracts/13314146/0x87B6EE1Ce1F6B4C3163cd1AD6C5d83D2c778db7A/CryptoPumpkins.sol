// SPDX-License-Identifier: MIT
/*..................................................................................................
...................................................................................................
  _____                  _          _____                       _    _
 / ____|                | |        |  __ \                     | |  (_)
| |     _ __ _   _ _ __ | |_ ___   | |__) |   _ _ __ ___  _ __ | | ___ _ __  ___
| |    | '__| | | | '_ \| __/ _ \  |  ___/ | | | '_ ` _ \| '_ \| |/ / | '_ \/ __|
| |____| |  | |_| | |_) | || (_) | | |   | |_| | | | | | | |_) |   <| | | | \__ \
 \_____|_|   \__, | .__/ \__\___/  |_|    \__,_|_| |_| |_| .__/|_|\_\_|_| |_|___/
              __/ | |                                    | |
             |___/|_|                                    |_|
----------------------------------------------------------------------------------
/  __\\  \//  / \   /  _ \/  __//  _ \/ \  /|  /   _\/  __\/  _ \/    //__ __\
| | // \  /   | |   | / \|| |  _| / \|| |\ ||  |  /  |  \/|| / \||  __\  / \
| |_\\ / /    | |_/\| \_/|| |_//| |-||| | \||  |  \__|    /| |-||| |     | |
\____//_/     \____/\____/\____\\_/ \|\_/  \|  \____/\_/\_\\_/ \|\_/     \_/
------------------------------------------------------------------------------2021
On twitter at @realCodeCraft & @CryptoPumpkins................................................*/

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";


contract CryptoPumpkins is ERC721, ERC721Enumerable, Ownable {
    uint256 public _pumpkinPrice;
    uint256 public _pumpkinPatchPrice;
    uint256 public _pumpkinFarmPrice;

    uint public constant maxPumpkinPurchase = 10;
    uint256 public constant MAX_PUMPKINS = 5923;
    uint public pumpkinReserve = 350;

    bool public saleIsActive = false;
    bool public preSaleIsActive = false;

    // Base URI
    string private _baseURIextended;

    // Mapping for presale whitelist address
    mapping(address => bool) private _presaleWhitelist;
    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    constructor() ERC721("CryptoPumpkins", "CPUM") { }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setPumpkinPrice(uint256 pumpkinPrice) public onlyOwner {
        _pumpkinPrice = pumpkinPrice;
    }

    function setPumpkinPatchPrice(uint256 pumpkinPatchPrice) public onlyOwner {
        _pumpkinPatchPrice = pumpkinPatchPrice;
    }

    function setPumpkinFarmPrice(uint256 pumpkinFarmPrice) public onlyOwner {
        _pumpkinFarmPrice = pumpkinFarmPrice;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function reservePumpkins(address _to, uint256 _reserveAmount) public onlyOwner {
        uint supply = totalSupply();
        require(_reserveAmount > 0 && _reserveAmount <= pumpkinReserve, "Not enough reserve left for team");
        for (uint i = 1; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }
        pumpkinReserve = pumpkinReserve - _reserveAmount;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

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
        return string(abi.encodePacked(base, uint2str(tokenId)));
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() public onlyOwner {
        preSaleIsActive = !preSaleIsActive;
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    modifier onlyPresaleWhitelist {
        require(_presaleWhitelist[msg.sender], "Not on presale whitelist");
        _;
    }

    function addToWhitelist(address[] memory wallets) public onlyOwner {
        for(uint i = 0; i < wallets.length; i++) {
            _presaleWhitelist[wallets[i]] = true;
        }
    }

    function removeFromWhitelist(address[] memory wallets) public onlyOwner {
        for(uint i = 0; i < wallets.length; i++) {
            _presaleWhitelist[wallets[i]] = false;
        }
    }

    function isOnWhitelist(address wallet) public view returns (bool) {
        return _presaleWhitelist[wallet];
    }

    function mintPresalePumpkin(uint numberOfTokens) public onlyPresaleWhitelist payable returns(uint256[] memory ) {
        require(preSaleIsActive, "PreSale must be active to mint Pumpkin");
        require(numberOfTokens <= 10, "Can only mint 10 tokens at a time");
        require(totalSupply() + numberOfTokens <= MAX_PUMPKINS, "Purchase would exceed max supply of Pumpkins");
        require(_pumpkinPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        return _mintPumpkin(numberOfTokens, msg.sender);
    }

    function mintPresalePumpkinPatch() public onlyPresaleWhitelist payable returns(uint256[] memory ) {
        require(preSaleIsActive, "PreSale must be active to mint Pumpkin");
        require(totalSupply() + 3 <= MAX_PUMPKINS, "Purchase would exceed max supply of Pumpkins");
        require(_pumpkinPatchPrice <= msg.value, "Ether value sent is not correct");

        return _mintPumpkin(3, msg.sender);
    }

    function mintPresalePumpkinFarm() public onlyPresaleWhitelist payable returns(uint256[] memory ) {
        require(preSaleIsActive, "PreSale must be active to mint Pumpkin");
        require(totalSupply() + 10 <= MAX_PUMPKINS, "Purchase would exceed max supply of Pumpkins");
        require(_pumpkinFarmPrice <= msg.value, "Ether value sent is not correct");

        return _mintPumpkin(10, msg.sender);
    }

    function mintPumpkin(uint numberOfTokens) public payable returns(uint256[] memory ) {
        require(saleIsActive, "Sale must be active to mint Pumpkin");
        require(numberOfTokens <= 10, "Can only mint 10 tokens at a time");
        require(totalSupply() + numberOfTokens <= MAX_PUMPKINS, "Purchase would exceed max supply of Pumpkins");
        require(_pumpkinPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");

        return _mintPumpkin(numberOfTokens, msg.sender);
    }

    function mintPumpkinPatch() public payable returns(uint256[] memory ) {
        require(saleIsActive, "Sale must be active to mint Pumpkin");
        require(totalSupply() + 3 <= MAX_PUMPKINS, "Purchase would exceed max supply of Pumpkins");
        require(_pumpkinPatchPrice <= msg.value, "Ether value sent is not correct");

        return _mintPumpkin(3, msg.sender);
    }

    function mintPumpkinFarm() public payable returns(uint256[] memory ) {
        require(saleIsActive, "Sale must be active to mint Pumpkin");
        require(totalSupply() + 10 <= MAX_PUMPKINS, "Purchase would exceed max supply of Pumpkins");
        require(_pumpkinFarmPrice <= msg.value, "Ether value sent is not correct");

        return _mintPumpkin(10, msg.sender);
    }

    function _mintPumpkin(uint numberOfTokens, address sender) internal returns(uint256[] memory ){
        require(numberOfTokens <= maxPumpkinPurchase, "Only 10 pumpkins at a time can be minted");
        uint256[] memory ids = new uint256[](numberOfTokens);
        for(uint i = 1; i <= numberOfTokens; i++) {
            uint mintIndex = totalSupply();
            ids[i-1] = mintIndex;
            if (totalSupply() <= MAX_PUMPKINS) {
                _safeMint(sender, mintIndex+1);
            }
        }

        return ids;
    }

    function pumpkinsOwnedByAddress(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function uint2str(
    uint256 _i
    )
    internal
    pure
    returns (string memory str)
    {
        if (_i == 0)
        {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        str = string(bstr);
    }
}
