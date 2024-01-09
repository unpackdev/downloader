// Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";
import "./IERC2981.sol";

contract MetaverseCatCharms is IERC2981, ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    modifier saleIsOpen {
        require(totalSupply() <= maxSupply, "Soldout!");
        require(!paused, "Sales not open");
        _;
    }

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;

    uint256 public maxSupply = 10000;
    uint256 public maxMintAmount = 10;
    uint256 public nftPerAddressLimit = 100;

    uint256 private stage3Price = 0.09 ether;
    uint256 private stage2Price = 0.069 ether;
    uint256 private stage1Price = 0.05 ether;

    bool public paused = true;
    bool public revealed = false;
    bool public onlyWhitelisted = true;

    address[] public whitelistedAddresses;
    address[] public winnersAddress;

    mapping(address => uint256) private _claimedFreeTokens;

    address public constant member1Address = payable(0x0b5b19eDFE0fB31fdf266E3686B584fd61A6240d);
    address public constant member2Address = payable(0xA66F6Cc282c5fd380802484bEB68C140a13fBc2A);
    address public constant member3Address = payable(0xB23b56a50251CD6c0b0f5B685FE3168Cb3994D6F);

    event PauseEvent(bool pause);

    constructor(
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721("MetaverseCatCharms", "MCC") {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function contractURI() public pure returns (string memory) {
        return "ipfs://QmcbFcSyrrgK6Fkx74djtr6zJS1nBMaBWSNACu5GLZPawe/contract.json";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(uint256 _mintAmount) public payable saleIsOpen {
        uint256 total = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
        require(total + _mintAmount <= maxSupply, "max NFT limit exceeded");

        address wallet = _msgSender();

        if (wallet != owner()) {
            if (onlyWhitelisted == true) {
                require(isWhitelisted(wallet), "user is not whitelisted");
            }
            uint256 ownerMintedCount = balanceOf(wallet);
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
            require(msg.value >= price(_mintAmount), "insufficient funds");
        }

        for (uint8 i = 0; i < _mintAmount; i++){
            _safeMint(wallet, total + i);
        }
    }

    function claim() public payable saleIsOpen {
        uint256 total = totalSupply();
        require(total + 1 <= maxSupply, "max NFT limit exceeded");

        address wallet = _msgSender();
        
        uint256 freeMintAmount = 1;
        if ((wallet == member1Address) 
            || (wallet == member2Address)
            || (wallet == member3Address)) 
        {
            require(_claimedFreeTokens[wallet] == 0, "user has already claim his free token");
            freeMintAmount = 30;
        } else {
            require(_claimedFreeTokens[wallet] == 0, "user has already claim his free token");
            require(isWinner(wallet), "user is not winner");
        }

        uint256 ownerMintedCount = balanceOf(wallet);
        require(ownerMintedCount + 1 <= nftPerAddressLimit, "max NFT per address exceeded");

        _claimedFreeTokens[wallet] = freeMintAmount;
        for (uint8 i = 0; i < freeMintAmount; i++){
            _safeMint(msg.sender, total + i);
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function isWinner(address _user) public view returns (bool) {
        for (uint i = 0; i < winnersAddress.length; i++) {
            if (winnersAddress[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function price(uint256 _count) public view returns (uint256) {
        uint256 total = totalSupply();
        if (total <= 500) {
            return stage1Price.mul(_count);
        }

        if (total <= 2500) {
            return stage2Price.mul(_count);            
        }

        return stage3Price.mul(_count);
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
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
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function pause(bool _pause) public onlyOwner{
        paused = _pause;
        emit PauseEvent(paused);
    }

    function reveal() public onlyOwner() {
      revealed = true;
    }

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view override(IERC2981) returns (
        address receiver,
        uint256 royaltyAmount
    ) {
        // This sets percentages by price * percentage / 100
        receiver = owner();
        royaltyAmount = _salePrice.mul(5).div(100);
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(member1Address, balance.mul(5).div(100));
        _widthdraw(member3Address, balance.mul(5).div(100));
        _widthdraw(member2Address, balance.mul(20).div(100));
        _widthdraw(owner(), address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function setStage1Price (uint256 _stage1Price)  public onlyOwner {
        stage1Price = _stage1Price;
    }

    function setStage2Price (uint256 _stage2Price)  public onlyOwner {
        stage2Price = _stage2Price;
    }

    function setStage3Price (uint256 _stage3Price)  public onlyOwner {
        stage3Price = _stage3Price;
    }

    function setBaseURI(string memory _initBaseURI) public onlyOwner {
        baseURI = _initBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }
  
    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function setWinners(address[] calldata _users) public onlyOwner {
        delete winnersAddress;
        winnersAddress = _users;
    }

    function setWhitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }
}