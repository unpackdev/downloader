// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Metadata.sol";
import "./ERC721Queryable.sol";
import "./ERC721Royalty.sol";
import "./Mintable.sol";
import "./Withdrawable.sol";

error FreeMintAlreadyClaimed();

contract ContractMinter is ERC721, ERC721Burnable, ERC721Metadata, ERC721Queryable, ERC721Royalty, Mintable, Withdrawable {

    uint256 public constant MAX_SUPPLY = 10000;


    struct MintConfig {
        uint64 allowlistMaxMint;
        uint64 allowlistPrice;
        uint64 publicMaxMint;
        uint64 publicPrice;
    }


    MintConfig public _config;


    bytes32 public _allowlistMerkleRoot;
    bytes32 public _giveawayMerkleRoot;
    bytes32 public _publicMerkleRoot;


    constructor() ERC721('Contract Minter', 'minter') ERC721Royalty(_msgSenderERC721A(), 1000) {
        setBaseURI('https://niftyvs.com/metadata/contract-minter/json/');
        _setMintState(STATE_MINT_ALLOWLIST);

        _allowlistMerkleRoot = 0xa9758466ebc51b4c11c2f26b7ec964a3d3cf7b7b3e86fbe4d5001587c1a503a7;
        _giveawayMerkleRoot = 0xa9758466ebc51b4c11c2f26b7ec964a3d3cf7b7b3e86fbe4d5001587c1a503a7;
        _publicMerkleRoot = 0xa9758466ebc51b4c11c2f26b7ec964a3d3cf7b7b3e86fbe4d5001587c1a503a7;

        _config = MintConfig({
            allowlistMaxMint: 3,
            allowlistPrice: 0.04 ether,
            publicMaxMint: 8,
            publicPrice: 0.05 ether
        });
    }


    function _baseURI() internal override(ERC721, ERC721Metadata, ERC721Queryable) view virtual returns (string memory) {
        return super._baseURI();
    }

    function _startTokenId() internal override(ERC721, ERC721Queryable) view virtual returns(uint256) {
        return super._startTokenId();
    }

    function mintAllowlist(bytes32[] calldata proof, uint256 quantity) external payable {
        uint256 available = MAX_SUPPLY - _totalMinted();
        address buyer = _msgSenderERC721A();

        _merkleProofGate(buyer, proof, _allowlistMerkleRoot);
        _mintGate(isMintAllowlist());
        _priceGate(buyer, _config.allowlistPrice, quantity, msg.value);
        _supplyGate(available, _config.allowlistMaxMint, _numberMinted(buyer), quantity);

        _safeMint(buyer, quantity);
    }

    function mintGiveaway(bytes32[] calldata proof) external payable {
        uint256 available = MAX_SUPPLY - _totalMinted();
        address buyer = _msgSenderERC721A();
        uint256 quantity = 1;

        _merkleProofGate(buyer, proof, _giveawayMerkleRoot);
        _mintGate(isMintOpen());
        _supplyGate(available, quantity);

        if (_getAux(buyer) > 0) {
            revert FreeMintAlreadyClaimed();
        }

        _setAux(buyer, 1);

        _safeMint(buyer, quantity);
    }

    function mintPublic(uint256 quantity) external payable {
        uint256 available = MAX_SUPPLY - _totalMinted();
        address buyer = _msgSenderERC721A();

        _mintGate(isMintPublic());
        _priceGate(buyer, _config.publicPrice, quantity, msg.value);
        _supplyGate(available, _config.publicMaxMint, _numberMinted(buyer), quantity);

        _safeMint(buyer, quantity);
    }

    function setAllowlistMerkleRoot(bytes32 root) external onlyOwner {
        _allowlistMerkleRoot = root;
    }

    function setAllowlistPrice(uint64 price) external onlyOwner {
        _config.allowlistPrice = price;
    }

    function setGiveawayMerkleRoot(bytes32 root) external onlyOwner {
        _giveawayMerkleRoot = root;
    }

    function setMintState(uint32 state) external onlyOwner {
        _setMintState(state);
    }

    function setPublicPrice(uint64 price) external onlyOwner {
        _config.publicPrice = price;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC721Royalty, IERC721A) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) override(ERC721A, ERC721Metadata, IERC721A) public view virtual returns(string memory) {
        return super.tokenURI(tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 split = (address(this).balance * 3300) / 10000;

        _withdraw(0x1D33Db15e1A8e85Ffc5b3a6983c2E1C45349a98B, split);
        _withdraw(0x266c3dF72B45F963192BcE641Eb4d56476D296D2, split);
        _withdraw(owner(), address(this).balance);
    }
}
