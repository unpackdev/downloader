// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
// import "./console.sol";

/**
 * @title: Muraqqa - Data Miniature
 * @creator: @orkhan_art - orkhan mammadov
 * @author: @devbhang - devbhang.eth
 * @author: @0xhazelrah - hazelrah.eth
 */

import "./ERC721AQueryable.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

/////////////////////////////////////////////////////////////////
//                                                             //
//                                                             //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+                               //
//   |M| |U| |R| |A| |Q| |Q| |A|                               //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+                               //
//                                                             //
//                                                             //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   //
//   |D| |A| |T| |A| | | |M| |I| |N| |I| |A| |T| |U| |R| |E|   //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+   //
//                                                             //
//                                                             //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+                       //
//   |B| |Y| |:| |O| |R| |K| |H| |A| |N|                       //
//   +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+ +-+                       //
//                                                             //
//                                                             //
/////////////////////////////////////////////////////////////////

contract Muraqqa is ERC721AQueryable, Ownable, ERC2981 {
    enum SaleStatus {
        NoSale,
        EarlyBirdSale,
        CollectorsSale,
        PublicSale,
        SaleFinished
    }

    SaleStatus saleStatus = SaleStatus.NoSale;

    string public baseURI;

    uint256 public constant MAX_SUPPLY = 111;
    uint256 public constant MAX_SUPPLY_PRE = 90;

    uint256 public maxMint = 1;
    uint256 public pricePre = 0.5 ether;
    uint256 public pricePublic = 0.65 ether;

    address public treasuryAddress;

    bytes32 private _merkleRoot;

    constructor(
        address _address,
        uint96 _royalty,
        string memory _newBaseURI,
        uint256 _amount
    ) ERC721A("Muraqqa", "MRQQ") Ownable(_address) {
        treasuryAddress = _address;
        baseURI = _newBaseURI;

        _setDefaultRoyalty(_address, _royalty);
        _mint(_address, _amount);
    }

    function setRoyalty(address _address, uint96 _royalty) external onlyOwner {
        treasuryAddress = _address;
        _setDefaultRoyalty(_address, _royalty);
    }

    function setMaxMint(uint256 _maxMint) external onlyOwner {
        maxMint = _maxMint;
    }

    function setPrice(
        uint256 _pricePre,
        uint256 _pricePublic
    ) external onlyOwner {
        pricePre = _pricePre;
        pricePublic = _pricePublic;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function getSaleStatus() public view returns (SaleStatus) {
        return saleStatus;
    }

    function setSaleStatus(
        uint256 _saleStatus,
        bytes32 _root
    ) external onlyOwner {
        saleStatus = SaleStatus(_saleStatus);
        _merkleRoot = _root;
    }

    function _mintToken(uint256 _price, uint256 _maxSupply) internal virtual {
        require(
            _numberMinted(msg.sender) < maxMint,
            "MAX MINT PER WALLET IS EXCEEDED"
        );
        require(totalSupply() + 1 <= _maxSupply, "MAX SUPPLY IS EXCEEDED");
        require(msg.value >= _price, "NOT ENOUGH ETHERS SEND");

        _mint(msg.sender, 1);
    }

    function mintTokenPre(bytes32[] calldata _merkleProof) external payable {
        require(
            saleStatus == SaleStatus.EarlyBirdSale ||
                saleStatus == SaleStatus.CollectorsSale,
            "SALE IS NOT OPEN"
        );
        require(
            MerkleProof.verify(
                _merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "ADDRESS NOT WHITELISTED"
        );

        _mintToken(pricePre, MAX_SUPPLY_PRE);
    }

    function mintTokenPublic() external payable {
        require(saleStatus == SaleStatus.PublicSale, "SALE IS NOT OPEN");

        _mintToken(pricePublic, MAX_SUPPLY);
    }

    function mintAdmin(
        address[] calldata _to,
        uint256 _amount
    ) external onlyOwner {
        require(
            totalSupply() + (_amount * _to.length) <= MAX_SUPPLY,
            "MAX SUPPLY IS EXCEEDED"
        );

        for (uint i; i < _to.length; i++) {
            _mint(_to[i], _amount);
        }
    }

    function withdraw() external onlyOwner {
        require(
            saleStatus == SaleStatus.SaleFinished,
            "CAN'T WITHDRAW DURING SALE"
        );
        require(address(this).balance > 0, "INSUFFICIENT FUNDS");

        (bool success, ) = payable(treasuryAddress).call{
            value: address(this).balance
        }("");
        require(success, "TRANSFER FAILED");
    }
}
