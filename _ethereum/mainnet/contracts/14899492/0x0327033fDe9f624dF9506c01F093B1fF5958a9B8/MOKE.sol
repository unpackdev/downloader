//
//   ███╗   ███╗ ██████╗ ██╗  ██╗███████╗
//   ████╗ ████║██╔═══██╗██║ ██╔╝██╔════╝
//   ██╔████╔██║██║   ██║█████╔╝ █████╗
//   ██║╚██╔╝██║██║   ██║██╔═██╗ ██╔══╝
//   ██║ ╚═╝ ██║╚██████╔╝██║  ██╗███████╗
//   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
//
//   Collection     : MOKE NFT
//   Year           : 2022
//   Owner          : Moke America (https://mokeamerica.com)
//   Author         : Ben Hakim (bh@wirepulse.com)
//

pragma solidity 0.8.14;

import "./ERC721.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

// Royalties: Rarible
import "./RoyaltiesV2Impl.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";

contract MOKENFT is Ownable, ERC721, PaymentSplitter, ReentrancyGuard, RoyaltiesV2Impl {
    uint256 private _MOKE_PRICE = 0.5 ether;
    uint256 private constant _MAX_SUPPLY = 5000;
    uint256 private constant _MAX_SUPPLY_PUBLIC = 4900;
    address payable private _ROYALTY_ADDRESS;
    uint16 private _totalMinted = 0;
    uint16 private _totalMintedPublic = 0;
    uint96 private constant _ROYALTY_PERCENTAGE_BASIS_POINTS = 1000;
    uint256 private constant _MAXIMUM_PURCHASE = 20;
    string private __baseURI = "ipfs://bafybwig2jxhvmryxao5s5b7v46bbbrvp4hmah5pl5tedb7hngq4etfzd2y/"; // Initialize with unrevealed base URI
    bool private _freezeMetadataCalled = false;
    bool private _mintActive = false;

    bytes4 private constant _INTERFACE_TO_ERC2981 = 0x2a55205a;

    address[] private _paymentSplitterAddresses = [0xb94bfd3F4Fc6E45f6FD8B7eCe3ce4F4884c0Faa9,0xA5B1242b009BBf80f51eC0D85D17858abcFDe446,0x5d58E1Ae69bC927394C7D2b88862c3ecDF345aAD];
    uint256[] private _paymentSplitterShares = [50,25,25];

    constructor(uint256 ownerInitialMintCount) ERC721("MOKE NFT", "MOKE", 20, 5000) PaymentSplitter(_paymentSplitterAddresses, _paymentSplitterShares) {
        _ROYALTY_ADDRESS = payable(address(this));

        // Royalties Implementation: Rarible
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _ROYALTY_PERCENTAGE_BASIS_POINTS;
        _royalties[0].account = _ROYALTY_ADDRESS;
        _saveRoyalties(1, _royalties);

        // Mint to owner wallet
        if (ownerInitialMintCount > 0) {
            mint(ownerInitialMintCount);
        }
    }

    function DANGER_freezeMetadata() public onlyOwner {
        _freezeMetadataCalled = true;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
       require(_freezeMetadataCalled == false, "Metadata is frozen.");
       __baseURI = newBaseURI;
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted;
    }

    function totalMintedPublic() public view returns (uint256) {
        return _totalMintedPublic;
    }

    function mint(uint256 numberOfTokensToMint) public payable nonReentrant {
        require(numberOfTokensToMint <= _MAXIMUM_PURCHASE, "You can only mint 20 MOKENFT at a time.");
        require(numberOfTokensToMint > 0, "You must mint at least one token.");

        if (msg.sender == owner()) {
            require(numberOfTokensToMint + _totalMinted <= 5000, "This mint would exceed the total number of available tokens.");
        } else {
            require(_mintActive == true, "Minting is not currently active.");
            require(numberOfTokensToMint * _MOKE_PRICE <= msg.value, "Amount of ether sent for purchase is incorrect.");
            require(numberOfTokensToMint + _totalMintedPublic <= 4900, "This mint would exceed the total number of available tokens.");
            _totalMintedPublic += uint16(numberOfTokensToMint);
        }

        _totalMinted += uint16(numberOfTokensToMint);

        // Mint
        _safeMint(msg.sender, numberOfTokensToMint);
    }

    // Royalties Implementation: ERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        if (_exists(_tokenId)) {
            return (_ROYALTY_ADDRESS, _salePrice * _ROYALTY_PERCENTAGE_BASIS_POINTS / 10000);
        } else {
            return (_ROYALTY_ADDRESS, 0);
        }
    }

    // OpenSea Contract-level metadata implementation (https://docs.opensea.io/docs/contract-level-metadata)
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(__baseURI, "contract"));
    }

    function withdraw() public {
        release(payable(msg.sender));
    }

    function releaseToAccount(address payable account) public onlyOwner {
        release(account);
    }

    function toggleMintActive() public onlyOwner {
        _mintActive = !_mintActive;
    }

    function getMintActive() public view returns (bool) {
        return _mintActive;
    }

    function getPrice() public view returns (uint256) {
        return _MOKE_PRICE;
    }

    function setPriceWei(uint256 newPriceWei) public onlyOwner {
        _MOKE_PRICE = newPriceWei;
    }

    // Supports Interface Override
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
        // Rarible Royalties Interface
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }

        // ERC2981 Royalty Standard
        if (interfaceId == _INTERFACE_TO_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return __baseURI;
    }
}
