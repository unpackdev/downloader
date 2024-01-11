// SPDX-License-Identifier: MIT
// www.nftchan.xyz - the ultimate "mint what you want" art project
// initial mint ONLY via our website! If you mint directly, you have to add 0.2 ETH for manual fixing!

pragma solidity 0.8.12;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract chanXYZContract is ERC721Enumerable, Ownable {
    using Strings for uint256;
    // ------------------------------------------------------------------------------
    address public contractCreator;
    mapping(address => uint256) public addressMintedBalance;
    // ------------------------------------------------------------------------------
    uint256 public constant MAXCHANS = 8888;
    // ------------------------------------------------------------------------------
    uint256 public nowPrice = 0.02 ether;
    // ------------------------------------------------------------------------------
    string public baseTokenURI;
    string public baseExtension = ".json";
    bool public isActive = true;
    // ------------------------------------------------------------------------------
    address nftchanWallet = 0x9cf2eb2151afdE498B7bc6bAEA05D4e91bcD0Ece;   // founders wallet,

    event mintedChan(uint256 indexed id, string localId);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        contractCreator = msg.sender;
        setBaseURI(_initBaseURI);
    }

    // internal return the base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // ------------------------------------------------------------------------------------------------
    // public mint function - mints only to sender!
    function mint(address _to, uint256 _mintAmount, string calldata _localId) public payable {
        uint256 supply = totalSupply();

        if(msg.sender != contractCreator) {
            require(isActive, "Contract paused!");
        }
        require(_mintAmount > 0, "We can not mint zero...");
        require(supply + _mintAmount <= MAXCHANS, "Supply exhausted, sorry we are sold out!");

        if(msg.sender != contractCreator) {
            require(msg.value >= nowPrice * _mintAmount, "You have not sent enough currency.");
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
            emit mintedChan(supply + i, _localId);
        }
    }
    // ------------------------------------------------------------------------------------------------
    // - useful needed tools
    function showPrice() public view returns (uint256) {
        return nowPrice;
    }
    // -
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    function flipActive(bool newValue) public onlyOwner {
        isActive = newValue;
    }

    // give complete tokenURI back, if base is set
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, "/chan", tokenId.toString(), baseExtension)) : "";
    }
    //---------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------------
    // config functions, if needed for updating the settings by creator
    function setPrice(uint256 newPrice) public onlyOwner {
        nowPrice = newPrice;
    }
    // ----------------------------------------------------------------- WITHDRAW
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
    function withdrawAllToAddress(address addr) public onlyOwner {
        require(payable(addr).send(address(this).balance));
    }
}