// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title Degen Legion
/// @author MK/DEV
import "./ERC721A.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./Ownable.sol";

error DoesNotExist();
error NoTokensLeft();
error NotEnoughETH();
error MintLimitPerWallet();
error NotInTheWL();
error PreSaleIsNotActive();
error PublicSaleIsNotActive();


contract DEGEN is ERC721A, Ownable {
    using Strings for uint256;

    bytes32 public merkleRoot;
    uint16 public MAX_SUPPLY = 800;
    uint8 public maxMintFroWl = 2;
    uint8 public maxMintForPublic = 8;
    uint256 public pricePresale = 0.29 ether;
    uint256 public priceSale = 0.49 ether;

    string public baseURI;
    string public notRevealedURI;
    string public baseExtension = ".json";

    bool public preSaleActive;
    bool public publicSaleActive;
    bool public revealed = false;

    constructor(string memory _theBaseURI,string memory _notRevealedURI , bytes32 _merkleRoot) ERC721A("Degen Legion", "DL") {
        baseURI = _theBaseURI;
        notRevealedURI = _notRevealedURI;
        merkleRoot = _merkleRoot;
       
    }


    // Whitelist
    function setMerkleRoot(bytes32 _newMerkleRoot) external onlyOwner {
        merkleRoot = _newMerkleRoot;
    }

    function isWhiteListed(address account, bytes32[] calldata proof) internal view returns(bool) {
        return _verify(_leaf(account), proof);
    }

    function _leaf(address account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function changeSupply(uint16 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function changeMaxMintAllowedForWl(uint8 _maxMintAllowed) external onlyOwner {
        maxMintFroWl = _maxMintAllowed;
    }

    function changeMaxMintAllowedForPublic(uint8 _maxMintAllowed) external onlyOwner {
        maxMintForPublic = _maxMintAllowed;
    }

    function changePricePresale(uint _pricePresale) external onlyOwner {
        pricePresale = _pricePresale;
    }

    function changePriceSale(uint _priceSale) external onlyOwner {
        priceSale = _priceSale;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    //Metadata
    function setBaseUri(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function SetNotRevealURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedURI = _notRevealedURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    function Reveal() external onlyOwner{
        revealed = true; 
    }

    function setBaseExtension(string memory _baseExtension) external onlyOwner {
        baseExtension = _baseExtension;
    }

    // toggles
    function togglePreSaleActive() external onlyOwner {
        preSaleActive = !preSaleActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        publicSaleActive = !publicSaleActive;
    }

    function preSaleMint(bytes32[] calldata _proof, uint8 _quantity) external payable callerIsUser {
        if (!preSaleActive) revert PreSaleIsNotActive();
        if (_numberMinted(msg.sender) + _quantity > maxMintFroWl) revert MintLimitPerWallet();
        if (!isWhiteListed(_msgSender(), _proof)) revert NotInTheWL();
        if (msg.value < pricePresale * _quantity) revert NotEnoughETH();
        if (totalSupply() + _quantity > MAX_SUPPLY) revert NoTokensLeft();

        _mint(msg.sender, _quantity);
    }

    function mint(uint8 _quantity) external payable callerIsUser{
        if (!publicSaleActive) revert PublicSaleIsNotActive();
        if (msg.value < priceSale * _quantity) revert NotEnoughETH();
        if (_numberMinted(msg.sender) + _quantity > maxMintForPublic) revert MintLimitPerWallet();
        if (totalSupply() + _quantity > MAX_SUPPLY) revert NoTokensLeft();

        _mint(msg.sender, _quantity);
    }


   function airDropOnePerTarget(address[] calldata targets) external onlyOwner {
        if (totalSupply() + targets.length > MAX_SUPPLY)
            revert NoTokensLeft();

        for (uint256 i = 0; i < targets.length; i++) {

            _mint(targets[i], 1);
        }
    }

    function airdropNFTsForTargets(
        address[] calldata targets,
        uint256[] calldata quantities
    ) external onlyOwner {
        require(targets.length == quantities.length, "List of targets needs to be of the same length as the list of quantities");

        uint256 count;
        for (uint256 i = 0; i < quantities.length; i++) {
            count += quantities[i];
        }
        if (count + totalSupply() > MAX_SUPPLY)
            revert NoTokensLeft();
        for (uint256 i = 0; i < targets.length; i++) {
            _mint(targets[i], quantities[i]);
        }
    }

   function tokenURI(uint _nftId) public view override(ERC721A) returns (string memory) {
        if (!_exists(_nftId)) revert  DoesNotExist();
        if(revealed == false) {
            return notRevealedURI;
        }
        
        string memory currentBaseURI = _baseURI();
        return 
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, _nftId.toString(), baseExtension))
            : "";
    }
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}

