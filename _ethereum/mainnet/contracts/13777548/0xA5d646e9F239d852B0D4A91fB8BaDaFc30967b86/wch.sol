// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

contract LegionOfWitches is EIP712, ERC721Enumerable, Ownable {

    using Strings for uint256;

    bytes32 public constant PRESALE_TYPEHASH = keccak256("Presale(address buyer)");

    uint256 public constant PUBLIC_SALE_PRICE = 0.05 ether;
    uint256 public  PRE_SALE_PRICE = 0.03 ether;
    uint256 public constant TOTAL_NUMBER_OF_LEGION_OF_WITCHES = 10000;
    uint256 public giveaway_reserved = 200;
    uint256 public constant MAX_PRE_SALE = 20;
    uint256 public constant MAX_PUBLIC_SALE = 20;
    uint256 public constant MAX_GIVEAWAY_RESERVERD = 200;
    address constant pete_address = 0x9953e66a68261d033d75AC8A07BC6f58c7D6B317;
    address constant dre_address = 0x773D00b0532b979c11924633a8fe33d31fd7f91E;

    mapping(address => uint256) public presalerListPurchases;

    bool public presaleLive = false;
    bool public publicsaleLive = false;
    string private _baseTokenURI = "";
    address public whitelistSigner;

    constructor(
        address _whitelistSigner
    )
        ERC721("LegionOfWitches", "LOW")
        EIP712("LegionOfWitches", "1.0.0")
    {
        whitelistSigner = _whitelistSigner;
    }

    function _hash(address _buyer) internal view returns(bytes32 hash) {
        hash = _hashTypedDataV4(keccak256(abi.encode(
            PRESALE_TYPEHASH,
            _buyer
        )));
    }

    function _verify(bytes32 digest, bytes memory signature) internal view returns(bool) {
        return ECDSA.recover(digest, signature) == whitelistSigner;
    }

    function presaleBuy(uint256 tokenQuantity, bytes memory signature) external payable{
        uint256 supply = totalSupply();
        require(presaleLive, "Legion of Witches: pre sale is paused");
        require(whitelistSigner != address(0), "Signer is default address!");
        require(_verify(_hash(msg.sender), signature), "The Signature is invalid!");
        require( supply + tokenQuantity <= TOTAL_NUMBER_OF_LEGION_OF_WITCHES - MAX_GIVEAWAY_RESERVERD, "You can not mint exceeds maximum NFT" );
        require(presalerListPurchases[msg.sender] + tokenQuantity <= MAX_PRE_SALE, "You can not mint exceeds maximum NFT");
        require(PRE_SALE_PRICE * tokenQuantity <= msg.value, "Insufficient ETH sent");

        presalerListPurchases[msg.sender] += tokenQuantity;
        for(uint256 i; i < tokenQuantity; i++){
            _safeMint( msg.sender,  giveaway_reserved + supply + i );
        }
    }

    function mint(uint256 num) public payable{
        uint256 supply = totalSupply();
        require(publicsaleLive, "Legion of Witches: mint is paused");
        require( num <= MAX_PUBLIC_SALE, "Legion of Witches You can mint a maximum of 20 NFT" );
        require( balanceOf(msg.sender) + num <= MAX_PUBLIC_SALE + presalerListPurchases[msg.sender] , "You can not mint exceeds maximum NFT");
        require( supply + num <= TOTAL_NUMBER_OF_LEGION_OF_WITCHES - MAX_GIVEAWAY_RESERVERD, "You can not mint exceeds maximum NFT" );
        require( msg.value >= PUBLIC_SALE_PRICE * num, "Insufficient ETH sent" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, giveaway_reserved + supply + i );
        }
    }

    function giveAway(address _to, uint256 _reserveAmount) external onlyOwner {
        require(giveaway_reserved > 0 && _reserveAmount <= giveaway_reserved, "Exceeds giveaway reserved supply" );
        uint256 giveaway_suply = MAX_GIVEAWAY_RESERVERD - giveaway_reserved;
        for (uint i = 0; i < _reserveAmount; i++) {
          _safeMint( _to, giveaway_suply + i);
        }
        giveaway_reserved -= _reserveAmount;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "Legion of Witches: withdraw all call without balance");
        uint owner = balance * 8500 / 10000; // 85%
        uint pete = balance * 750 / 10000; // 7.5%
        uint dre = balance * 750 / 10000; // 7.5%
        require(payable(msg.sender).send(owner), "Legion of Withces: Failed withdraw to owner");
        require(payable(dre_address).send(dre), "Legion of Withces: Failed withdraw to Dre");
        require(payable(pete_address).send(pete), "Legion of Withces: Failed withdraw to Pete");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Legion of Witches URI query for nonexistent token");

        string memory baseURI = getBaseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function changePreSalePrice(uint256 amount) external onlyOwner {
       PRE_SALE_PRICE = amount;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function togglePublicsaleStatus() external onlyOwner {
        publicsaleLive = !publicsaleLive;
    }

    function getBaseURI() public view returns (string memory) {
        return _baseTokenURI;
    }
}