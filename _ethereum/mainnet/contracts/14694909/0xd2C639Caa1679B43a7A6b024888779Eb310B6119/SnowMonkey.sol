// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

//the rarible dependency files are needed to setup sales royalties on Rarible
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

import "./UgokiCOA.sol";
import "./IUgokiCOA.sol";

contract SnowMonkey is ERC721Enumerable, Ownable, RoyaltiesV2Impl {
    using Counters for Counters.Counter;

    bool isMintStarted;

    string baseURI;
    string redeemedBaseURI;

    uint MAX_SUPPLY = 1000;
    uint PRESALE_THRESHOLD = 350;

    uint PRESALE_PRICE = 300000000000000000;
    uint SALE_PRICE = 450000000000000000;

    Counters.Counter private _tokenIds;

    IUgokiCOA public immutable COAContract;

    uint256 public vault;

    mapping(address => bool) mintedByAddress;
    mapping(uint256 => bool) private _isWatchesRedeemed;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    constructor(address _COAContract) ERC721("Expeditious Snow Monkeys on the Block", "ESMB") {
        COAContract = IUgokiCOA(_COAContract);
    }

    function setIsMintStarted(bool _status) public onlyOwner {
        isMintStarted = _status;
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function setRedeemedBaseURI(string memory redeemedBaseURI_) public onlyOwner {
        redeemedBaseURI = redeemedBaseURI_;
    }

    function setPresalePrice(uint256 _newPresalePrice) public payable onlyOwner {
        PRESALE_PRICE = _newPresalePrice;
    }

    function setSalePrice(uint256 _newSalePrice) public payable onlyOwner {
        SALE_PRICE = _newSalePrice;
    }

    function transferFromVault() public onlyOwner payable {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
        vault = 0;
    }

    function _baseURI() override internal view returns (string memory) {
        return baseURI;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseURI();
    }

    function _redeemedBaseURI() internal view returns (string memory) {
        return redeemedBaseURI;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory path = _baseURI();
        if (isRedeemed(tokenId)) path = _redeemedBaseURI();
        return bytes(path).length > 0 ? string(abi.encodePacked(path, Strings.toString(tokenId))) : "";
    }

    function getMintPrice(uint count) public view returns (uint256) {
        require(count < 6, "Amount should be in a range between 1 to 5");
        uint256 currentId = _tokenIds.current();
        uint256 price = 0;
        for (uint8 i = 0; i <= count-1; i++) {
            price += (currentId + i) < PRESALE_THRESHOLD ? PRESALE_PRICE : SALE_PRICE;
        }
        return price;
    }

    function mint(uint count) public payable returns (uint) {
        require(isMintStarted, "Mint is not started yet");
        require(count < 6, "User can mint from 1 to 5 Snow Monkeys");
        require(!mintedByAddress[msg.sender], "User can mint monkeys only once");
        uint256 currentId = _tokenIds.current();
        uint256 totalPrice = (currentId < PRESALE_THRESHOLD ? PRESALE_PRICE * count : SALE_PRICE * count);
        require(msg.value >= totalPrice, "Not enough funds to mint the NFT");
        vault = vault + msg.value;
        for (uint8 i = 1; i <= count; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(msg.sender, newTokenId);
            setRoyalties(newTokenId, payable(owner()), 1000);
        }
        mintedByAddress[msg.sender] = true;
        return count;
    }

    function ownerMint(uint count) public payable onlyOwner returns (uint) {
        for (uint8 i = 1; i <= count; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(msg.sender, newTokenId);
            setRoyalties(newTokenId, payable(owner()), 1000);
        }
        return count;
    }

    function mintedCount() public view returns (uint256) {
        return _tokenIds.current();
    }

    function redeem(uint256 _tokenId, string memory _tokenURI) public {
        require(ownerOf(_tokenId) == msg.sender, "There no NFT assosiated with this address");
        require(!_isWatchesRedeemed[_tokenId], "NFT is already was redeemed");
        _isWatchesRedeemed[_tokenId] = true;
        COAContract.mint(msg.sender, _tokenURI); // Mint new COA on NFT lock
    }

    function isRedeemed(uint256 _tokenId) public view returns (bool) {
        return _isWatchesRedeemed[_tokenId];
    }

    //configure royalties for Rariable
    function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    //configure royalties for Mintable using the ERC2981 standard
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      //use the same royalties that were saved for Rariable
      LibPart.Part[] memory _royalties = royalties[_tokenId];
      if(_royalties.length > 0) {
        return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
      }
      return (address(0), 0);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if(interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}
