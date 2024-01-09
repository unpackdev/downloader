// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";

contract EliteChessClub is
    ERC721Enumerable,
    Ownable,
    ERC721Burnable,
    ERC721Pausable
{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    address public _royaltiesReceiver = 0x03415648E2e38311640a6C49A8843A69504CFE30;
    uint public royaltiesPercentage = 10;

    uint256 public constant MAX_ELEMENTS_PRESALE = 1000;
    uint256 public constant MAX_ELEMENTS_PUBLIC = 10000;
    uint256 public presale_price = 5 * 10**16;
    uint256 public public_price = 8 * 10**16;
    
    address private _ownerOfContract;
    bool public isPresale = true;
    address[] public whitelistedAddresses;
    string public baseTokenURI;
    mapping(address => uint256) public addressMintedBalance;
    uint256 public nftPerAddressLimit = 5;
    uint256 public nftLimitPresale = 30;
    
    event CreateElite(uint256 indexed id);

    constructor() ERC721("Elite Chess Club", "ECC") {
        _ownerOfContract = msg.sender;
    }
    function royaltiesReceiver() public view returns(address) {
        return _royaltiesReceiver;
    }

    function setRoyaltiesReceiver(address newRoyaltiesReceiver)
    external onlyOwner {
        require(newRoyaltiesReceiver != _royaltiesReceiver); // dev: Same address
        _royaltiesReceiver = newRoyaltiesReceiver;
    }
    function royaltyInfo(uint256 _salePrice) external view
    returns (address receiver, uint256 royaltyAmount) {
        uint256 _royalties = (_salePrice * royaltiesPercentage) / 100;
        return (_royaltiesReceiver, _royalties);
    }
    // function set

    modifier saleIsOpen() {
        if (msg.sender != _ownerOfContract) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }

    function _totalSupply() internal view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }

    function mint(address _to, uint256 _count) public payable saleIsOpen {
        uint256 total = _totalSupply();
        require(total <= (MAX_ELEMENTS_PRESALE + MAX_ELEMENTS_PUBLIC), "Sale end");
        uint256 ownerMintedCount = addressMintedBalance[msg.sender];

        if (msg.sender != _ownerOfContract) {
            if (isPresale) {
                require(total + _count <= MAX_ELEMENTS_PRESALE, "Max limit for presale");
                require(msg.value >= priceOfPresale(_count), "Value below price");
                if ( isWhitelisted(msg.sender)){
                    require(ownerMintedCount + _count <= nftLimitPresale, "max NFT per address exceeded for whitelist");
                }
                else{
                    require(ownerMintedCount + _count <= nftPerAddressLimit, "Max NFT per address exceeded for Presale");
                }
            }
            else{
                require(total + _count <= MAX_ELEMENTS_PUBLIC, "Max limit for public");
                require(msg.value >= priceOfPublic(_count), "Value below price");
            }
        }

        for (uint256 i = 1; i <= _count; i++) {
            addressMintedBalance[msg.sender]++;
            _mintAnElement(_to);
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function _mintAnElement(address _to) private {
        uint256 id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateElite(id);(id);
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function addWhitelist(address _user) public onlyOwner {
        require(address(_user) != address(0), "Address can not be zero address.");
        whitelistedAddresses.push( _user );
    }

    function priceOfPresale(uint256 _count) public view returns (uint256) {
        return presale_price.mul(_count);
    }

    function priceOfPublic(uint256 _count) public view returns (uint256) {
        return public_price.mul(_count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(msg.sender, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setPresale(bool _presale) public onlyOwner{
        isPresale = _presale;
    }
}
