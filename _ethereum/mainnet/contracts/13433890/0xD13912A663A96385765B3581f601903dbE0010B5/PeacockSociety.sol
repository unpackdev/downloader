// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./draft-EIP712.sol";
import "./ECDSA.sol";

contract PeacockSociety is Ownable, EIP712, ERC721Enumerable {
    using Strings for uint256;

    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address buyer,uint256 signedQty)");
    address whitelistSigner;
    uint256 public constant TOTAL_MAX_QTY = 10000;
    uint256 public constant GIFT_MAX_QTY = 200;
    uint256 public constant PRESALES_MAX_QTY = 6000;
    uint256 public constant PRESALES_MAX_QTY_PER_MINTER = 5;
    uint256 public constant PUBLIC_SALE_MAX_QTY_PER_TRANSACTION = 5;

    // Remaining presale quantity can be purchase through public sale
    uint256 public constant PUBLIC_SALE_MAX_QTY = TOTAL_MAX_QTY - GIFT_MAX_QTY;
    uint256 public constant PRICE = 0.05 ether;

    string private _contractURI;
    string private _tokenBaseURI;
    mapping(address => uint256) public presaleMinterToTokenQty;
    uint256 public presalesMintedQty = 0;
    uint256 public publicSalesMintedQty = 0;
    uint256 public giftedQty = 0;
    bool public isPresalesActivated;
    bool public isPublicSalesActivated;

    constructor()
        ERC721("Peacock Society", "PEACOCK")
        EIP712("Peacock Society", "1")
    {}

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function getSigner(
        address _buyer,
        uint256 _signedQty,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, _buyer, _signedQty))
        );
        return ECDSA.recover(digest, _signature);
    }

    function presalesMint(
        uint256 _mintQty,
        uint256 _signedQty,
        bytes memory _signature
    ) external payable {
        require(
            getSigner(msg.sender, _signedQty, _signature) == whitelistSigner,
            "Invalid signture"
        );
        require(isPresalesActivated, "Presales is closed");
        require(
            totalSupply() + _mintQty <= TOTAL_MAX_QTY,
            "Exceed total max limit"
        );
        require(
            presalesMintedQty + _mintQty <= PRESALES_MAX_QTY,
            "Exceed presales max limit"
        );
        require(
            presaleMinterToTokenQty[msg.sender] + _mintQty <=
                PRESALES_MAX_QTY_PER_MINTER,
            "Exceed presales max quantity per minter"
        );
        require(msg.value >= PRICE * _mintQty, "Insufficient ETH");

        presaleMinterToTokenQty[msg.sender] += _mintQty;

        for (uint256 i = 0; i < _mintQty; i++) {
            presalesMintedQty++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function publicSalesMint(uint256 _mintQty) external payable {
        require(isPublicSalesActivated, "Public sale is closed");
        require(
            totalSupply() + _mintQty <= TOTAL_MAX_QTY,
            "Exceed total max limit"
        );
        require(
            presalesMintedQty + publicSalesMintedQty + _mintQty <= PUBLIC_SALE_MAX_QTY,
            "Exceed public sale max limit"
        );
        require(
            _mintQty <= PUBLIC_SALE_MAX_QTY_PER_TRANSACTION,
            "Exceed public sales max quantity per transaction"
        );
        require(msg.value >= PRICE * _mintQty, "Insufficient ETH");

        for (uint256 i = 0; i < _mintQty; i++) {
            publicSalesMintedQty++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(
            totalSupply() + receivers.length <= TOTAL_MAX_QTY,
            "Exceed total max limit"
        );
        require(
            giftedQty + receivers.length <= GIFT_MAX_QTY,
            "Exceed gift max limit"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedQty++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "No amount to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    function togglePresalesStatus() external onlyOwner {
        isPresalesActivated = !isPresalesActivated;
    }

    function togglePublicSalesStatus() external onlyOwner {
        isPublicSalesActivated = !isPublicSalesActivated;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    // To support Opensea contract-level metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // To support Opensea token metadata
    // https://docs.opensea.io/docs/metadata-standards
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(_tokenId), "Token not exist");

        return string(abi.encodePacked(_tokenBaseURI, _tokenId.toString()));
    }
}
