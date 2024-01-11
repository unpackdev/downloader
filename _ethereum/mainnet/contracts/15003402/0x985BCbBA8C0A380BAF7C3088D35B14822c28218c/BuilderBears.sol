//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./AggregatorV3Interface.sol";

/*
 *  ______     __  __     __     __         _____     ______     ______
 * /\  == \   /\ \/\ \   /\ \   /\ \       /\  __-.  /\  ___\   /\  == \
 * \ \  __<   \ \ \_\ \  \ \ \  \ \ \____  \ \ \/\ \ \ \  __\   \ \  __<
 *  \ \_____\  \ \_____\  \ \_\  \ \_____\  \ \____-  \ \_____\  \ \_\ \_\
 *   \/_____/   \/_____/   \/_/   \/_____/   \/____/   \/_____/   \/_/ /_/
 *   ______     ______     ______     ______     ______
 *  /\  == \   /\  ___\   /\  __ \   /\  == \   /\  ___\
 *  \ \  __<   \ \  __\   \ \  __ \  \ \  __<   \ \___  \
 *   \ \_____\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \/\_____\
 *    \/_____/   \/_____/   \/_/\/_/   \/_/ /_/   \/_____/
 */                                                                 
contract BuilderBears is ERC721A, Ownable, ReentrancyGuard {
    mapping(uint256 => string) private ceilingPriceToBaseURI;
    uint256[] private ceilingPrices;

    uint public immutable collectionSize = 4269;

    AggregatorV3Interface internal priceFeed;

    bool public isMintActive = false;

    constructor(address _priceFeedAddress) ERC721A("BuilderBears", "BUILDERBEAR") {
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function mint()
        external
        payable
        nonReentrant
    {
        require(isMintActive, "mint not active");
        require(msg.value == 0 ether, "free mint requires no fee");
        require(_totalMinted() < collectionSize, "sold out");
        require(tx.origin == msg.sender, "contracts not allowed");

        _safeMint(msg.sender, 1);
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        uint latestEthPriceUSD = getLatestEthPriceUSD();

        for (uint i = 0; i < ceilingPrices.length; i++) {
            if (latestEthPriceUSD < ceilingPrices[i]) {
                return ceilingPriceToBaseURI[ceilingPrices[i]];
            }
        }

        return ceilingPriceToBaseURI[ceilingPrices[ceilingPrices.length - 1]];
    }

    function withdraw()
        external
        onlyOwner
    {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "failed transfer");
    }

    function setCeilingPriceToBaseURIMapping(
        uint256[] calldata _ceilingPrices,
        string[] calldata _baseURIs
    )
        external
        onlyOwner
    {
        require(_ceilingPrices.length == _baseURIs.length, "mismatched array lengths");
        ceilingPrices = _ceilingPrices;
        for (uint8 i = 0; i < ceilingPrices.length; i++) {
            ceilingPriceToBaseURI[ceilingPrices[i]] = _baseURIs[i];
        }
    }

    function setIsMintActive(bool _isMintActive)
        external
        onlyOwner
    {
        isMintActive = _isMintActive;
    }

    function setPriceFeed(address _address)
        external
        onlyOwner
    {
        priceFeed = AggregatorV3Interface(_address);
    }

    function getIsMintActive()
        public
        view
        returns (bool)
    {
        return isMintActive;
    }

    function getLatestEthPriceUSD()
        public
        view
        returns (uint) 
    {
        (,int price,,,) = priceFeed.latestRoundData();
        uint8 decimals = priceFeed.decimals();
        return uint(price) / 10 ** decimals;
    }

    function _startTokenId()
        internal
        pure
        override
        returns (uint256) 
    {
        return 1;
    }

    fallback()
        external
        payable
    {
        require(false, "not implemented");
    }

    receive()
        external
        payable
    {
        require(false, "not implemented");
    }
}