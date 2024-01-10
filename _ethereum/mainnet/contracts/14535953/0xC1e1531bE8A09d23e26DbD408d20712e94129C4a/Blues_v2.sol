import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SafeMath.sol";
import "./StringsUpgradeable.sol";

library OpenSeaGasFreeListing {
    /**
    @notice Returns whether the operator is an OpenSea proxy for the owner, thus
    allowing it to list without the token owner paying gas.
    @dev ERC{721,1155}.isApprovedForAll should be overriden to also check if
    this function returns true.
     */
    function isApprovedForAll(address owner, address operator)
        internal
        view
        returns (bool)
    {
        ProxyRegistry registry;
        assembly {
            switch chainid()
            case 1 {
                // mainnet
                registry := 0xa5409ec958c83c3f309868babaca7c86dcb077c1
            }
            case 4 {
                // rinkeby
                registry := 0xf57b2c51ded3a29e6891aba85459d600256cf317
            }
        }

        return
            address(registry) != address(0) &&
            address(registry.proxies(owner)) == operator;
    }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

pragma solidity ^0.8.0;

interface IBlue {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getOwnerLedger(address addr)
        external
        view
        returns (uint16[] memory);

    function balanceOf(address account) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IOcean {
    function getTokenOwner(uint256 index) external view returns (address);

    function isLegendary(uint256 tokenID) external pure returns (bool);
}

contract BluesMigrated is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    event BlueMigrated(address, uint256);

    using StringsUpgradeable for uint256;

    bool public isRevealed;
    uint16 public maxSupply;
    uint16 public supply;
    address public bluesAddress;
    address public oceanAddress;

    string public baseExtension;
    string public baseURI;
    string public notRevealedUri;

    IBlue Blues;
    IOcean Ocean;

    mapping(uint256 => address) public ownersLedger;
    mapping(address => uint256) public legendaryHoldings;

    function initialize(
        string memory _name,
        string memory _symbol,
        address _ocean,
        address _blues
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __ERC721_init(_name, _symbol);
        Blues = IBlue(_blues);
        Ocean = IOcean(_ocean);
        bluesAddress = _blues;
        oceanAddress = _ocean;
        isRevealed = true;
        maxSupply = 5571;
        supply = 0;
        baseExtension = ".json";
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBlues(address _blues) external onlyOwner {
        Blues = IBlue(_blues);
    }

    function setOcean(address _ocean) external onlyOwner {
        Ocean = IOcean(_ocean);
    }

    function migrate(uint256[] memory tokenIds) external nonReentrant {
        for (uint256 i; i < tokenIds.length; i++) {
            if (Blues.ownerOf(tokenIds[i]) == oceanAddress) {
                address trueOwner = Ocean.getTokenOwner(tokenIds[i]);
                require(trueOwner == msg.sender, "you are not the owner");
            } else {
                require(
                    Blues.ownerOf(tokenIds[i]) == msg.sender,
                    "you are not the owner"
                );
            }

            _safeMint(msg.sender, tokenIds[i]);
            supply++;
            emit BlueMigrated(msg.sender, tokenIds[i]);
        }
    }

    function ownerMint(uint256[] memory tokenIds) external onlyOwner {
        for (uint256 i; i < tokenIds.length; i++) {
            _safeMint(msg.sender, tokenIds[i]);
            supply++;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId));

        if (isRevealed == true) {
            string memory currentBaseURI = _baseURI();
            return
                bytes(currentBaseURI).length > 0
                    ? string(
                        abi.encodePacked(
                            currentBaseURI,
                            tokenId.toString(),
                            baseExtension
                        )
                    )
                    : "";
        } else return notRevealedUri;
    }

    function totalSupply() external view returns (uint16) {
        return supply;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        external
        onlyOwner
    {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return
            OpenSeaGasFreeListing.isApprovedForAll(owner, operator) ||
            super.isApprovedForAll(owner, operator);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);

        if (isLegendary(tokenId)) {
            legendaryHoldings[to]++;

            if (legendaryHoldings[from] > 0) legendaryHoldings[from]--;
        }

        ownersLedger[tokenId] = to;
    }

    function getLegendaryHoldings(address addr)
        external
        view
        returns (uint256)
    {
        return legendaryHoldings[addr];
    }

    function isLegendary(uint256 tokenID) public pure returns (bool) {
        if (
            tokenID == 756 ||
            tokenID == 2133 ||
            tokenID == 1111 ||
            tokenID == 999 ||
            tokenID == 888 ||
            tokenID == 435 ||
            tokenID == 891 ||
            tokenID == 918 ||
            tokenID == 123 ||
            tokenID == 432 ||
            tokenID == 543 ||
            tokenID == 444 ||
            tokenID == 333 ||
            tokenID == 222 ||
            tokenID == 235 ||
            tokenID == 645 ||
            tokenID == 898 ||
            tokenID == 1190 ||
            tokenID == 3082 ||
            tokenID == 3453 ||
            tokenID == 2876 ||
            tokenID == 5200 ||
            tokenID == 451 ||
            tokenID > 5555
        ) return true;

        return false;
    }
}
