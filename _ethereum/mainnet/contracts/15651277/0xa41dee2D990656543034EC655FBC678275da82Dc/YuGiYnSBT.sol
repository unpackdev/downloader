// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract YuGiYnSBT is ERC721A, Ownable {
    using Strings for uint256;
    address public admin;

    uint256 public maxSupply = 500;
    string public baseURI = "https://assets.yu-gi-yn.com/sbt/metadata/";

    constructor() ERC721A("YuGiYn SBT", "YGYS") {
        admin = owner();
    }

    function approve(address, uint256) public payable virtual override {
        require(false, "This token is SBT, so this can not approve.");
    }

    function setApprovalForAll(address, bool) public virtual override {
        require(false, "This token is SBT, so this can not approve.");
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "token does not exist");
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256,
        uint256
    ) internal pure override {
        require(to == address(0) || from == address(0), "this nft is the soulbound");
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(owner() == _msgSenderERC721A() || admin == _msgSenderERC721A(), "caller is not the admin");
        _;
    }

    function airdropMint(address _airdropAddresses, uint256 _mintAmount) public onlyAdmin {
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

        _safeMint(_airdropAddresses, _mintAmount);
    }

    function airdropMint_array(address[] calldata _airdropAddresses, uint256[] memory _UserMintAmount) public onlyAdmin {
        uint256 supply = totalSupply();
        uint256 _mintAmount = 0;
        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _mintAmount += _UserMintAmount[i];
        }
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
        require(_airdropAddresses.length == _UserMintAmount.length, "array length unmuch");

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            _safeMint(_airdropAddresses[i], _UserMintAmount[i]);
        }
    }

    function setMaxSupply(uint256 _value) public onlyAdmin {
        maxSupply = _value;
    }

    function setBaseURI(string memory _newBaseURI) public onlyAdmin {
        baseURI = _newBaseURI;
    }

    function burn(uint256 burnTokenId) public {
        require(_msgSender() == ownerOf(burnTokenId), "Only the owner can burn");
        _burn(burnTokenId);
    }
}
