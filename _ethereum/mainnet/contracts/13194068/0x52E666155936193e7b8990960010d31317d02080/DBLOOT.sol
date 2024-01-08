// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Address.sol";

import "./ILootLike.sol";
import "./Base64.sol";

contract DBLOOT is ILootLike, ERC721Enumerable, Ownable {
    using Address for address payable;

    string[] private assetOne = [
        'Bloot (not for Weaks)',
        'Loot (for Adventurers)',
        'CryptoPunks',
        'CryptoKitties',
        'Lazlo Lissitsky',
        'Bored Ape Yacht Club',
        'Stoner Cats',
        'Mooncats',
        'Pudgy Penguins',
        'Art Blocks',
        'Cool Cats',
        'Deadbeef',
        'Twin Flames',
        'Gyre',
        'Squiggly.WTF',
        'Autoglyphs',
        'Etheria v1.1 Tiles',
        'Realms of Ether',
        'Sea Hams',
        'Fidenza',
        'Ringer',
        'Chromie Squiggle',
        'Unigrid',
        'Subscape',
        'Singluarity',
        'Hyper Hash',
        'Pigments',
        'Apparaitions',
        'Phases',
        'Dino Pals',
        'Avid Lines',
        'EtherRocks',
        '0xmons',
        'Crypto Pochis',
        'TBOA Token',
        'MetaHeroes',
        'Punks Comics'
    ];

    string[] private assetTwo = [
        'BTC',
        'ETH',
        'ADA',
        'USDT',
        'XRP',
        'DOGE',
        'SOL',
        'DOT',
        'USDC',
        'SOL',
        'FTM',
        'DGB',
        'XMR',
        'ZEC',
        'AVAX',
        'HEX',
        'OHM',
        'DOGE',
        'PREMIA'
    ];

    string[] private assetThree = [
        'UNI',
        'LINK',
        'LUNA',
        'BCH',
        'LTC',
        'WBTC',
        'WETH',
        'MATIC',
        'TRX',
        'ATOM',
        'XMR',
        'DAI',
        'CAKE',
        'GRT',
        'AAVE',
        'COMP',
        'XTZ',
        'SUSHI',
        'MKR',
        'PREMIA',
        'ETH',
        'BTC',
        'DOGE'
    ];

    string[] private assetFour = [
        'BNB',
        'SNX',
        'SHIBA',
        'ETC',
        'POLYDOGE',
        'SAFEMOON',
        'SAFEMARS',
        'SAFEMOONCASH',
        'EVERMUSK',
        'ZEC',
        'HEGIC',
        'ETH',
        'BTC',
        'SCAM',
        'NFD',
        'DOG'
    ];

    string[] private assetFive = [
        'Gonna Make It',
        'Not Gonna Make It',
        'WAGMI',
        'Having Fun Staying Poor',
        'Not Having Fun Staying Poor',
        'Apathetic',
        'Jaded',
        'Just Hodling',
        'Script Kiddie',
        'Looks Rare',
        'Shoo Poor',
        'Poverty',
        'Generational Wealth',
        'Generational Poverty',
        'Poverty Speak',
        'Pleb',
        'Oh My',
        'Buckle Up',
        'Gonna Be a Dicey Week',
        'Cringe bro',
        'Old as Gainzy',
        'NFT influencers are killing it bro',
        'Defi Degen',
        'NFT Degen',
        'Mooning'
    ];

    string[] private assetSix = [
        'Lambo',
        'Fleet of Lambos',
        'Lambo on the moon',
        'Yacht',
        "Bitcoin Pizza (Papa John's)",
        "Bitcoin Pizza (Domino's)",
        'Bitcoin Pizza (Pizza Hut)',
        'A modest home in the suburbs',
        'A medium sized house',
        'A 2nd condo with no Fidenza',
        'Rolex',
        'Audemars Piguet',
        'Patek'
    ];

    string[] private assetSeven = [
        'Cointelegraph',
        'CoinDesk',
        'rekt.news',
        'Decrypt',
        'twitter.com/sunnya97_bot',
        'MSNBC',
        "Bitboy Crypto's Youtube",
        'Ivan On Tech Academy',
        'Bitcoin.com',
        'DefiPulse',
        'Defi Slate',
        'e-girl Capital Insights',
        'Delphi Digital'
    ];

    string[] private assetEight = [
        'Ledger',
        'TREZOR',
        'KeepKey',
        'MEW',
        'Metamask',
        'Rainbow',
        'Exodus',
        'Edge',
        'Trust',
        'Coinbase Wallet',
        'MCW',
        'Paper Wallet',
        'Post-It Note'
    ];

    string[] private suffixes = [
        'hodled since 2021',
        'hodled since 2017',
        'hodled since 2009',
        'hodled since 1995',
        '(safu)',
        '(very safu)',
        'on a Dell OptiPlex lost in a landfill',
        'on Mt. Gox',
        'on Coinbase',
        'on the moon',
        'in The DAO',
        'in tornado.cash',
        'in a safe deposit box',
        'all in',
        '!floor',
        "it's airgapped bro",
        'class of 2011',
        'Class of 2013',
        'class of 2017',
        'class of 2021',
        'up only'
    ];

    constructor() ERC721('BLOOT (for Degens)', '(D)BLOOT') Ownable() {}

    function ownerOf(uint256 tokenId)
        public
        view
        override(ILootLike, ERC721)
        returns (address owner)
    {
        return super.ownerOf(tokenId);
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getAsset1(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return pluck(tokenId, 'NFT', assetOne, true);
    }

    function getAsset2(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return pluck(tokenId, 'COIN1', assetTwo, true);
    }

    function getAsset3(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return pluck(tokenId, 'COIN2', assetThree, true);
    }

    function getAsset4(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return pluck(tokenId, 'COIN3', assetFour, true);
    }

    function getAsset5(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return pluck(tokenId, 'PERSONA', assetFive, false);
    }

    function getAsset6(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return pluck(tokenId, 'PROFIT', assetSix, false);
    }

    function getAsset7(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return pluck(tokenId, 'NEWS', assetSeven, false);
    }

    function getAsset8(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return pluck(tokenId, 'WALLET', assetEight, false);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray,
        bool suffix
    ) internal view returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );
        string memory output = sourceArray[rand % sourceArray.length];

        if (suffix) {
            uint256 greatness = ((rand >> 128) *
                block.number *
                block.timestamp) % 21;

            if (greatness > 17) {
                output = string(
                    abi.encodePacked(
                        output,
                        ' ',
                        suffixes[rand % suffixes.length]
                    )
                );
            }
        }

        return output;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string[17] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: #01ff01; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getAsset1(tokenId);

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = getAsset2(tokenId);

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = getAsset3(tokenId);

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = getAsset4(tokenId);

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = getAsset5(tokenId);

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = getAsset6(tokenId);

        parts[12] = '</text><text x="10" y="140" class="base">';

        parts[13] = getAsset7(tokenId);

        parts[14] = '</text><text x="10" y="160" class="base">';

        parts[15] = getAsset8(tokenId);

        parts[16] = '</text></svg>';

        string memory output = string(
            abi.encodePacked(
                parts[0],
                parts[1],
                parts[2],
                parts[3],
                parts[4],
                parts[5],
                parts[6],
                parts[7],
                parts[8]
            )
        );
        output = string(
            abi.encodePacked(
                output,
                parts[9],
                parts[10],
                parts[11],
                parts[12],
                parts[13],
                parts[14],
                parts[15],
                parts[16]
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "(D)BLOOT #',
                        toString(tokenId),
                        '", "description": "(d)bloot is basically bloot, but for degenerates", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked('data:application/json;base64,', json)
        );

        return output;
    }

    function claim(uint256 tokenId) public payable {
        require(msg.value == 0.02 ether, 'Must send 0.02 ETH');
        require(tokenId > 0 && tokenId <= (8008 - 880), 'Token ID invalid');
        _safeMint(_msgSender(), tokenId);
    }

    function claimForBloot(uint256 tokenId) public {
        require(
            IERC721(0x4F8730E0b32B04beaa5757e5aea3aeF970E5B613).balanceOf(
                msg.sender
            ) > 0,
            'Must be BLOOT holder'
        );
        require(tokenId > 0 && tokenId <= (8008 - 880), 'Token ID invalid');
        _safeMint(_msgSender(), tokenId);
    }

    function ownerClaim(uint256[] calldata tokenIds) public onlyOwner {
        address account = owner();

        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(
                tokenId > (8008 - 880) && tokenId <= 8008,
                'Token ID invalid'
            );
            _safeMint(account, tokenId);
        }
    }

    function ownerWithdraw() public onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return '0';
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
