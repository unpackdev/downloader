/**
* @title Authme.xyz contract
* @dev Extends ERC721Enumerable Non-Fungible Token Standard
*/

/**
*  SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.0;

/*
   _____          __  .__                    _____                                     
  /  _  \  __ ___/  |_|  |__   ___________  /     \   ____      ___  ______.__.________
 /  /_\  \|  |  \   __\  |  \ /  _ \_  __ \/  \ /  \_/ __ \     \  \/  <   |  |\___   /
/    |    \  |  /|  | |   Y  (  <_> )  | \/    Y    \  ___/      >    < \___  | /    / 
\____|__  /____/ |__| |___|  /\____/|__|  \____|__  /\___  > /\ /__/\_ \/ ____|/_____ \
        \/                 \/                     \/     \/  \/       \/\/           \/
*/

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Strings.sol";
import "./Base64.sol";

contract AuthMeERC721 is ERC721Enumerable, ERC721Burnable, Ownable
{
    using Strings for uint256;

    // =======================================================
    // EVENTS
    // =======================================================
    event SaleStateChange(bool isActive);
    event TokenMinted(uint256 tokenIndex, address minter, string seed, string text);
    event MintPriceChanged(uint256 newPrice);

    // =======================================================
    // STATE
    // =======================================================
    bool public saleIsActive = false;

    // contract
    mapping (uint8 => string) public additionalContractInfo;

    // supply and reservation
    uint256 public constant MAX_SUPPLY = 7500;

    // accounting
    uint256 public mintPrice = 0.025 ether;

    // story
    mapping (uint256 => string) public storySeeds;
    mapping (uint256 => string) public storyTexts;
    uint16 public minSeedLength = 30;
    uint16 public minStoryLength = 250;

    // =======================================================
    // CONSTRUCTOR
    // =======================================================
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    // =======================================================
    // INTERNAL & UTILS
    // =======================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // =======================================================
    // ADMIN
    // =======================================================
    function setAdditionalContractInfo(uint8 infoIndex, string memory info)
        public
        onlyOwner
    {
        additionalContractInfo[infoIndex] = info;
    }

    function toggleSaleState()
        public
        onlyOwner
    {
        saleIsActive = !saleIsActive;
        emit SaleStateChange(saleIsActive);
    }

    function changeMinSeedLength(uint16 _newLength)
        public
        onlyOwner
    {
        minSeedLength = _newLength;
    }

    function changeMinStoryLength(uint16 _newLength)
        public
        onlyOwner
    {
        minStoryLength = _newLength;
    }

    function changeMintPrice(uint256 _newPrice)
        public
        onlyOwner
    {
        mintPrice = _newPrice;
        emit MintPriceChanged(_newPrice);
    }

    function ownerMint(string memory _seedText, string memory _storyText)
        public
        onlyOwner
    {
        require(totalSupply() < MAX_SUPPLY, "Internal mint would exceed max supply");
        require(bytes(_seedText).length >= minSeedLength, "Provided seed length to short");
        require(bytes(_storyText).length >= minStoryLength, "Provided story length to short");

        storySeeds[totalSupply()] = _seedText;
        storyTexts[totalSupply()] = _storyText;

        _safeMint(msg.sender, totalSupply());
        
        emit TokenMinted(totalSupply() - 1, msg.sender, _seedText, _storyText);
    }

    function ownerBurn(uint256 tokenId)
        public
        onlyOwner
    {
        _burn(tokenId);
    }

    function withdrawFunds(address payable recipient, uint256 amount)
        public
        onlyOwner
    {
        require(recipient != address(0), "Invalid recipient address");
        recipient.transfer(amount);
    }

    // =======================================================
    // PUBLIC API
    // =======================================================
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string[5] memory svgParts;
        svgParts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 360 360" style="background-color: black;"><style>.textBase { color: white; font-family: serif; font-size: 13.5px; }</style><foreignObject x="5" y="5" width="350" height="350" class="textBase"><div xmlns="http://www.w3.org/1999/xhtml" ><strong>';
        svgParts[1] = storySeeds[tokenId];
        svgParts[2] = '</strong> ';
        svgParts[3] = storyTexts[tokenId];
        svgParts[4] = '</div></foreignObject></svg>';

        string memory output = string(abi.encodePacked(svgParts[0], svgParts[1], svgParts[2], svgParts[3], svgParts[4]));
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Story #', tokenId.toString(), '", "description": "Generated using a state-of-the-art neural network, stored 100% on-chain. Minimum text formatting applied to facilitate re-use across systems - we encourage using this in any way you wish.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function getSupplyData()
        public
        view
        returns(
            uint256 _maxSupply,
            uint256 _totalSupply,
            uint256 _mintPrice,
            bool _saleIsActive,
            uint16 _minSeedLength,
            uint16 _minStoryLength)
    {
        _maxSupply = MAX_SUPPLY;
        _totalSupply = totalSupply();
        _mintPrice = mintPrice;
        _saleIsActive = saleIsActive;
        _minSeedLength = minSeedLength;
        _minStoryLength = minStoryLength;
    }

    function getStory(uint256 tokenId)
        public
        view
        returns(string memory fullStory)
    {
        fullStory = string(abi.encodePacked(storySeeds[tokenId], " ",  storyTexts[tokenId]));
    }

    function mint(string memory _seedText, string memory _storyText)
        public
        payable
    {
        require(saleIsActive, "Sale is not active at the moment");
        require(totalSupply() < MAX_SUPPLY, "Purchase would exceed max supply");
        require(msg.value >= mintPrice, "Insufficient ether sent");
        require(bytes(_seedText).length >= minSeedLength, "Provided seed length to short");
        require(bytes(_storyText).length >= minStoryLength, "Provided story length to short");

        storySeeds[totalSupply()] = _seedText;
        storyTexts[totalSupply()] = _storyText;

        _safeMint(msg.sender, totalSupply());
        
        emit TokenMinted(totalSupply() - 1, msg.sender, _seedText, _storyText);
    }
}