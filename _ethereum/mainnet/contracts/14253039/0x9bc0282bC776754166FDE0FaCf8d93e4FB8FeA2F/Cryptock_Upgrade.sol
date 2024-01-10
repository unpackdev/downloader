pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./IERC721.sol";
import "./SafeMath.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./EnumerableSet.sol";

contract CryptockUpgrade is ERC721, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    Counters.Counter private _tokenIdCounter;

    EnumerableSet.AddressSet private _supportedNFTs;

    string public baseURI;

    constructor() ERC721("Cryptock Upgrade", "Cryptock Upgrade") {}

    function canUpgrade(address upgradeableNFT, uint256 tokenIDToUpgrade) public view returns (bool) {
        require(_supportedNFTs.contains((upgradeableNFT)), "Cannot upgrade an unsupported NFT");
        
        IERC721 upgradeable = IERC721(upgradeableNFT);
        require(upgradeable.ownerOf(tokenIDToUpgrade) == _msgSender(), "Message Sender doesn't meet the requirements");


        uint256 holding = IERC721(upgradeableNFT).balanceOf(_msgSender());
        uint256 upgrading = balanceOf(_msgSender());

        return (holding >= 1 && upgrading >= 1);
    }

    function toUpgrade(address upgradeableNFT, uint256 upgradeToBurnIndex, uint256 tokenIDToUpgrade) public {
        require(canUpgrade(upgradeableNFT, tokenIDToUpgrade), "Message Sender doesn't meet the requirements");
        require(ownerOf(upgradeToBurnIndex) == _msgSender(), "Message Sender doesn't meet the requirements");

        _burn(upgradeToBurnIndex);

        emit Upgraded(_msgSender(), upgradeableNFT, tokenIDToUpgrade);
    }

    // ------------------------------------------------- getters and setters
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _tokenBaseURI) external onlyOwner {
        baseURI = _tokenBaseURI;
        emit ChangeBaseURI(_tokenBaseURI);
    }


    function addSupportedNFT(address toSupport) public onlyOwner {
        _supportedNFTs.add(toSupport);
        emit SupportedNFTAdded(toSupport);

    }

    function removeSupportedNFT(address toRemove) public onlyOwner {
        _supportedNFTs.remove(toRemove); 
        emit SupportedNFTRemoved(toRemove);
    }

    
    // ------------------------------------------------- events
    event Upgraded(address holder, address upgradeableNFT, uint256 tokenIDToUpgrade);
    event ChangeBaseURI(string _baseURI);
    event SupportedNFTAdded(address added);
    event SupportedNFTRemoved(address removed);


    // ------------------------------------------------- ERC-721
    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}