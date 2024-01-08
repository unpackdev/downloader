// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./IFactoryERC721.sol";
import "./PieceSkyDreams.sol";
import "./PieceMermaidClouds.sol";
import "./PieceCastleBrush.sol";
import "./PiecePeckingOrder.sol";
import "./PieceTerraferma.sol";
import "./PieceHairFlip.sol";
import "./PieceLostAtSea.sol";
import "./PieceUnderwater.sol";
import "./PieceYarrr.sol";

contract WolfpacksFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    uint256 constant NUM_ITEM_OPTIONS = 9;
    address public proxyRegistryAddress;
    address public skyDreamsAddress;
    address public mermaidCloudsAddress;
    address public castleBrushAddress;
    address public peckingOrderAddress;
    address public terrafermaAddress;
    address public hairFlipAddress;
    address public lostAtSeaAddress;
    address public underwaterAddress;
    address public yarrrAddress;
    string public baseURI =
        "https://www.grannywolf.com/api/factories/wolfpack/";
    uint256 TOTAL_SUPPLY = 12000;
    uint256 NUM_OPTIONS = 1;
    uint256 OPTION_ID = 0;
    uint256 CARD_TOTAL = 9;

    constructor(
        address _proxyRegistryAddress,
        address _skyDreamsAddress,
        address _mermaidCloudsAddress,
        address _castleBrushAddress,
        address _peckingOrderAddress,
        address _terrafermaAddress,
        address _hairFlipAddress,
        address _lostAtSeaAddress,
        address _underwaterAddress,
        address _yarrrAddress
    ) {
        proxyRegistryAddress = _proxyRegistryAddress;
        skyDreamsAddress = _skyDreamsAddress;
        mermaidCloudsAddress = _mermaidCloudsAddress;
        castleBrushAddress = _castleBrushAddress;
        peckingOrderAddress = _peckingOrderAddress;
        terrafermaAddress = _terrafermaAddress;
        hairFlipAddress = _hairFlipAddress;
        lostAtSeaAddress = _lostAtSeaAddress;
        underwaterAddress = _underwaterAddress;
        yarrrAddress = _yarrrAddress;
        fireTransferEvents(address(0), owner());
    }

    function name() external pure override returns (string memory) {
        return "Granny Wolf Wolfpacks";
    }

    function symbol() external pure override returns (string memory) {
        return "GWWTPACKSF";
    }

    function supportsFactoryInterface() public pure override returns (bool) {
        return true;
    }

    function numOptions() public view override returns (uint256) {
        return NUM_OPTIONS;
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        emit Transfer(_from, _to, 1);
    }

    function mint(uint256 _optionId, address _toAddress) public override {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        assert(
            address(proxyRegistry.proxies(owner())) == _msgSender() ||
                owner() == _msgSender()
        );
        require(canMint(_optionId));

        // 1
        PieceSkyDreams pSkyDreams = PieceSkyDreams(skyDreamsAddress);
        PieceMermaidClouds pMermaidClouds = PieceMermaidClouds(
            mermaidCloudsAddress
        );
        PieceCastleBrush pCastleBrush = PieceCastleBrush(castleBrushAddress);
        PiecePeckingOrder pPeckingOrder = PiecePeckingOrder(
            peckingOrderAddress
        );
        PieceTerraferma pTerraferma = PieceTerraferma(terrafermaAddress);
        PieceHairFlip pHairFlip = PieceHairFlip(hairFlipAddress);
        PieceLostAtSea pLostAtSea = PieceLostAtSea(lostAtSeaAddress);
        PieceUnderwater pUnderwater = PieceUnderwater(underwaterAddress);
        PieceYarrr pYarr = PieceYarrr(yarrrAddress);
        uint256 selectedIndex = randMod(9);
        if (selectedIndex == 0) {
            pMermaidClouds.mintTo(_toAddress); // 1
            pLostAtSea.mintTo(_toAddress); // 6
            pCastleBrush.mintTo(_toAddress); // 2
            pUnderwater.mintTo(_toAddress); // 7
            pSkyDreams.mintTo(_toAddress); // 0
            pPeckingOrder.mintTo(_toAddress); // 3
            pYarr.mintTo(_toAddress); // 8
            pCastleBrush.mintTo(_toAddress); // 2
            pPeckingOrder.mintTo(_toAddress); // 3
        } else if (selectedIndex == 1) {
            pYarr.mintTo(_toAddress); // 8
            pYarr.mintTo(_toAddress); // 8
            pTerraferma.mintTo(_toAddress); // 4
            pPeckingOrder.mintTo(_toAddress); // 3
            pUnderwater.mintTo(_toAddress); // 7
            pUnderwater.mintTo(_toAddress); // 7
            pSkyDreams.mintTo(_toAddress); // 0
            pPeckingOrder.mintTo(_toAddress); // 3
            pMermaidClouds.mintTo(_toAddress); // 1
        } else if (selectedIndex == 2) {
            pLostAtSea.mintTo(_toAddress); // 6
            pPeckingOrder.mintTo(_toAddress); // 3
            pYarr.mintTo(_toAddress); // 8
            pUnderwater.mintTo(_toAddress); // 7
            pHairFlip.mintTo(_toAddress); // 5
            pTerraferma.mintTo(_toAddress); // 4
            pMermaidClouds.mintTo(_toAddress); // 1
            pSkyDreams.mintTo(_toAddress); // 0
            pYarr.mintTo(_toAddress); // 8
        } else if (selectedIndex == 3) {
            pHairFlip.mintTo(_toAddress); // 5
            pMermaidClouds.mintTo(_toAddress); // 1
            pUnderwater.mintTo(_toAddress); // 7
            pUnderwater.mintTo(_toAddress); // 7
            pPeckingOrder.mintTo(_toAddress); // 3
            pYarr.mintTo(_toAddress); // 8
            pSkyDreams.mintTo(_toAddress); // 0
            pMermaidClouds.mintTo(_toAddress); // 1
            pTerraferma.mintTo(_toAddress); // 4
        } else if (selectedIndex == 4) {
            pSkyDreams.mintTo(_toAddress); // 0
            pLostAtSea.mintTo(_toAddress); // 6
            pCastleBrush.mintTo(_toAddress); // 2
            pYarr.mintTo(_toAddress); // 8
            pTerraferma.mintTo(_toAddress); // 4
            pPeckingOrder.mintTo(_toAddress); // 3
            pMermaidClouds.mintTo(_toAddress); // 1
            pUnderwater.mintTo(_toAddress); // 7
            pSkyDreams.mintTo(_toAddress); // 0
        } else if (selectedIndex == 5) {
            pSkyDreams.mintTo(_toAddress); // 0
            pPeckingOrder.mintTo(_toAddress); // 3
            pHairFlip.mintTo(_toAddress); // 5
            pHairFlip.mintTo(_toAddress); // 5
            pYarr.mintTo(_toAddress); // 8
            pLostAtSea.mintTo(_toAddress); // 6
            pCastleBrush.mintTo(_toAddress); // 2
            pCastleBrush.mintTo(_toAddress); // 2
            pUnderwater.mintTo(_toAddress); // 7
        } else if (selectedIndex == 6) {
            pUnderwater.mintTo(_toAddress); // 7
            pYarr.mintTo(_toAddress); // 8
            pMermaidClouds.mintTo(_toAddress); // 1
            pCastleBrush.mintTo(_toAddress); // 2
            pUnderwater.mintTo(_toAddress); // 7
            pTerraferma.mintTo(_toAddress); // 4
            pLostAtSea.mintTo(_toAddress); // 6
            pPeckingOrder.mintTo(_toAddress); // 3
            pSkyDreams.mintTo(_toAddress); // 0
        } else if (selectedIndex == 7) {
            pPeckingOrder.mintTo(_toAddress); // 3
            pCastleBrush.mintTo(_toAddress); // 2
            pMermaidClouds.mintTo(_toAddress); // 1
            pSkyDreams.mintTo(_toAddress); // 0
            pTerraferma.mintTo(_toAddress); // 4
            pHairFlip.mintTo(_toAddress); // 5
            pLostAtSea.mintTo(_toAddress); // 6
            pUnderwater.mintTo(_toAddress); // 7
            pSkyDreams.mintTo(_toAddress); // 0
        } else if (selectedIndex == 8) {
            pYarr.mintTo(_toAddress); // 8
            pUnderwater.mintTo(_toAddress); // 7
            pLostAtSea.mintTo(_toAddress); // 6
            pLostAtSea.mintTo(_toAddress); // 6
            pSkyDreams.mintTo(_toAddress); // 0
            pYarr.mintTo(_toAddress); // 8
            pPeckingOrder.mintTo(_toAddress); // 3
            pTerraferma.mintTo(_toAddress); // 4
            pTerraferma.mintTo(_toAddress); // 4
        }
    }

    function canMint(uint256 _optionId) public view override returns (bool) {
        return true;
    }

    function tokenURI(uint256 _optionId)
        external
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(_optionId)));
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
        return
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        return owner();
    }

    // Defining a function to generate
    // a random number
    function randMod(uint256 _modulus) internal view returns (uint256) {
        return uint256(blockhash(block.number - 1)) % 9;
    }
}
