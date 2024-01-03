pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./IFactoryERC721.sol";
import "./Keycard.sol";
import "./Strings.sol";

contract KeycardFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    address public proxyRegistryAddress;
    address public nftAddress;

    mapping(uint256 => string) public sizeToMetadata;
    string private _baseURI;

    /**
     * Enforce the existence of only 42 Vaunker Keycards
     */
    uint256 MAX_SUPPLY = 42;

    /**
     * Four different sizes for minting keycards (s, m, l, xl)
     */
    uint256 NUM_OPTIONS = 4;

    constructor(address _proxyRegistryAddress, address _nftAddress) public {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;

        _baseURI = "https://ipfs.infura.io/ipfs/QmYaDvd7jMMrKNhs5nHqSZ56FMawaVydh7aETJ2dFjDjZi/";
        sizeToMetadata[0] = "small.json"; // S
        sizeToMetadata[1] = "medium.json"; // M
        sizeToMetadata[2] = "large.json"; // L
        sizeToMetadata[3] = "xlarge.json"; // XL

        fireTransferEvents(address(0), owner());
    }

    function name() external view returns (string memory) {
        return "Vaunker Genesis";
    }

    function symbol() external view returns (string memory) {
        return "VKC";
    }

    function supportsFactoryInterface() public view returns (bool) {
        return true;
    }

    function numOptions() public view returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == msg.sender ||
                owner() == msg.sender
        );
        require(canMint(_optionId));

        Keycard vaunkerKeycard = Keycard(nftAddress);
        vaunkerKeycard.mintSizeTo(_toAddress, _optionId);
    }

    function canMint(uint256 _optionId) public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        Keycard vaunkerKeycard = Keycard(nftAddress);
        uint256 keycardSupply = vaunkerKeycard.totalSupply();

        return keycardSupply < MAX_SUPPLY;
    }

    function tokenURI(uint256 _optionId) external view returns (string memory) {
        string memory _tokenURI = sizeToMetadata[_optionId];

        // Even if there is a base URI, it is only appended to non-empty token-specific URIs
        if (bytes(_tokenURI).length == 0) {
            return "";
        } else {
            // abi.encodePacked is being used to concatenate strings
            return string(abi.encodePacked(_baseURI, _tokenURI));
        }
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }
}
