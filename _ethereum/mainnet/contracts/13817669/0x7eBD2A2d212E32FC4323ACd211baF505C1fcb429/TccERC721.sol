// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./AccessControl.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./ITccERC721.sol";
//import "./ProxyOwnable.sol";

contract TccERC721 is ERC721Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, ITccERC721 {

    using Strings for uint256;
    using SafeMath for uint256;

    // EVENTS
    event WithdrawnToOwner(address indexed _operator, uint256 _ethWei);
    event WithdrawnToEntities(address indexed _operator, uint256 _ethWei);
    event NftMinted(address _whoDone, address _airdropAddress, uint256 _number);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public revealed;
    address public auctionAddress;
    uint256 private _totalSupply;

    string public baseURI;
    string public notRevealedURI;
    Counters.Counter private _tokenId;


    function initialize(
        string memory _name,
        string memory _symbol,
        address _creator
    ) public initializer {
        __ERC721_init(_name, _symbol);
        _totalSupply = 556;
        _transferOwnership(_creator);
        _grantRole(DEFAULT_ADMIN_ROLE, _creator);
        _grantRole(MINTER_ROLE, _creator);

        notRevealedURI = "https://ipfs.io/ipfs/QmXq6BAbLGki6XLrAa8tBpao3Br9wbZJfWWoDzYXRGua6u";
        auctionAddress = 0x807882D2a9C4DeA3f7F29eA496fcc02775361771;
        // mint the Diamond to auction wallet
        mintCollectible(auctionAddress, 1);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    modifier canMint(uint256 _number){
            require(Counters.current(_tokenId) + _number <= _totalSupply, "exceed the max supply limit");
            _;
    }


    ///////////////////////////////////////////////   PUBLIC  ///////////////////////////////////////////////
    function createCollectible(uint256 _number, address to) external override
    canMint(_number)
    onlyRole(MINTER_ROLE)
    {
        mintCollectible(to, _number);
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(!revealed) {
            return notRevealedURI;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
    }
    /*
      Mint to the special address, only the owner can do,
      Airdrop the nft to the given address
      minting number cannot exceed 255
    */
    function mintByOwner(address _airDropAddress, uint256 _number) external
    onlyOwner
    canMint(_number)
    {
        require(_number <= 255, "exceed the max minting limit per time");
        mintCollectible(_airDropAddress, _number);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function tokenCount() external view override returns (uint256) {
        return Counters.current(_tokenId);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function reveal() public onlyOwner {
        revealed = true;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _newNotRevealedURI) public onlyOwner {
        notRevealedURI = _newNotRevealedURI;
    }

    function setAuctionAddress(address _newAuctionAddress) public onlyOwner {
        auctionAddress = _newAuctionAddress;
    }

    /*
      minting number cannot exceed 255
    */
    function mintCollectible(address to, uint256 _number) internal canMint(_number)
    {
        require(_number > 0, "You need to indicate a number of nft to mint greater than 0");
        for (uint256 i= 0; i < _number; i++)
        {
            _safeMint(to, Counters.current(_tokenId));
            Counters.increment(_tokenId);
        }
        emit NftMinted(_msgSender(), to, _number);
    }


}
