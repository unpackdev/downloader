//
//   ██████╗  ██████╗ ███╗   ██╗     █████╗  ██████╗  █████╗ ███╗   ███╗
//   ██╔══██╗██╔═══██╗████╗  ██║    ██╔══██╗██╔════╝ ██╔══██╗████╗ ████║
//   ██████╔╝██║   ██║██╔██╗ ██║    ███████║██║  ███╗███████║██╔████╔██║
//   ██╔══██╗██║   ██║██║╚██╗██║    ██╔══██║██║   ██║██╔══██║██║╚██╔╝██║
//   ██║  ██║╚██████╔╝██║ ╚████║    ██║  ██║╚██████╔╝██║  ██║██║ ╚═╝ ██║
//   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
//
//   Arist          : Ron Agam
//   Collection     : New York
//   Year           : 2022
//   Owner          : Ron Agam (RonAgam.com)
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

contract RonAgamNewYork is Ownable, ERC721, PaymentSplitter, ReentrancyGuard, RoyaltiesV2Impl {
    uint256 private _RON_AGAM_PRICE = 0.2 ether;
    address payable private _ROYALTY_ADDRESS;
    uint256 private constant _MAX_SUPPLY = 2500;
    uint256 private constant _MAX_SUPPLY_PUBLIC = 2400;
    uint16 private _totalMinted = 0;
    uint16 private _totalMintedPublic = 0;
    uint96 private constant _ROYALTY_PERCENTAGE_BASIS_POINTS = 1000;
    uint256 private constant _MAXIMUM_PURCHASE = 20;
    string private __baseURI = "ipfs://bafybwigue7mqvik4gyuwqezvt5zsvk3qwkyzjh3b5bolzblv3vb2vjqbym/";
    bool private _freezeMetadataCalled = false;
    bool private _mintActive = false;

    bytes4 private constant _INTERFACE_TO_ERC2981 = 0x2a55205a;

    address[] private _paymentSplitterAddresses = [0x1D9e767A79a2Df64cb86B8e9A4272F817651E9Ad,0xA5B1242b009BBf80f51eC0D85D17858abcFDe446,0xB74DB67e8eC2A700C0BFb2c93A3c4EC7e2CAE093];
    uint256[] private _paymentSplitterShares = [150,25,25];

    constructor(uint256 ownerInitialMintCount) ERC721("Ron Agam New York", "NY", 20, 2500) PaymentSplitter(_paymentSplitterAddresses, _paymentSplitterShares) {
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
        return _RON_AGAM_PRICE;
    }

    function setPriceWei(uint256 newPriceWei) public onlyOwner {
        _RON_AGAM_PRICE = newPriceWei;
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
        require(numberOfTokensToMint <= _MAXIMUM_PURCHASE, "You can only mint 20 RonAgamNewYork at a time.");
        require(numberOfTokensToMint > 0, "You must mint at least one token.");

        if (msg.sender == owner()) {
            require(numberOfTokensToMint + totalMinted() <= 2500, "This mint would exceed the total number of available tokens.");
        } else {
            require(_mintActive, "Minting is not currently active.");
            require(numberOfTokensToMint * _RON_AGAM_PRICE <= msg.value, "Amount of ether sent for purchase is incorrect.");
            require(numberOfTokensToMint + _totalMintedPublic <= 2400, "This mint would exceed the total number of available tokens.");
            _totalMintedPublic += uint16(numberOfTokensToMint);
        }

        _totalMinted += uint16(numberOfTokensToMint);

        // Mint
        _safeMint(msg.sender, numberOfTokensToMint);
    }

    // Royalties Implementation: ERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (_ROYALTY_ADDRESS, _salePrice * _ROYALTY_PERCENTAGE_BASIS_POINTS / 10000);
    }

    // OpenSea Contract-level metadata implementation (https://docs.opensea.io/docs/contract-level-metadata)
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(__baseURI, "contract"));
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
