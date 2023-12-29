// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

interface IRandomizer {
    function getRandomNumber(uint256 upperLimit, uint256 idForUniquenessInBlock) external view returns (uint256);
}

interface IN is IERC721 {
    function getFirst(uint256 tokenId) external view returns (uint256);

    function getSecond(uint256 tokenId) external view returns (uint256);

    function getThird(uint256 tokenId) external view returns (uint256);

    function getFourth(uint256 tokenId) external view returns (uint256);

    function getFifth(uint256 tokenId) external view returns (uint256);

    function getSixth(uint256 tokenId) external view returns (uint256);

    function getSeventh(uint256 tokenId) external view returns (uint256);

    function getEight(uint256 tokenId) external view returns (uint256);
}

interface IPunk {
    function balanceOf(address wallet) external view returns (uint256);
}

/*
    https://twitter.com/_n_collective

    Numbers are the basis of the entire universe, the base layer of perceived reality. The rest is but a mere expression of those.
    Numbers are all around us, have always been, will always be.

    And God said, let there be Code; and there was Code. You may argue that I’m on mushrooms now but if our base reality itself is
    an expression of an underlying algorithm, wouldn't the n be just another loop of algorithmic reality creation; layer on top of layer, infinite, inception?
    And so, as the Big Bang is a symbolic manifestation of the creation of our reality, the @the_n_project_ is just another
     Big Bang of an alternate reality — the metaverse.

    Pythagorean Masks are the first of the creations of the @_n_Collective.
    The Collective settled on Masks as a design choice in order to amplify the idea that the individual who wears them shall hide
    his identity for that the Collective can shine. The Collective are the Mask holders, the Mask wearers;
    it represents your belonging to a community, the Collective, with the potential to shape reality in unprecedented ways.

    He who wears the Pythagorean Mask oaths to the Collective honest loyalty, for what is to come is beyond our scope of understanding.

    Welcome to the n Collective.
*/
contract PythagoreanMasks is ERC721, Ownable, ReentrancyGuard, ERC721Holder {
    IN public constant n = IN(0x05a46f1E545526FB803FF974C790aCeA34D1f2D6);
    IPunk public constant punk = IPunk(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    IRandomizer public constant randomizer = IRandomizer(0x498Ed28C41Eec6732A455158692760c7a3743ECB);

    uint256 public constant RESERVED_N_TOKENS_TO_MINT = 4005;
    uint256 public constant RESERVED_PUNK_TOKENS_TO_MINT = 1001;
    uint256 public constant RESERVED_TEAM_TOKENS_TO_MINT = 879;
    uint256 public constant RESERVED_OPEN_TOKENS_TO_MINT = 3003;
    uint256 public constant MAX_SUPPLY = 8888;
    uint256 public constant MINT_FEE = 0.0369258147 ether;

    mapping(address => uint256) public nHoldersMintedByAddress;
    uint256 public totalNHoldersMinted;
    mapping(address => uint256) public punkHoldersMintedByAddress;
    uint256 public totalPunkHoldersMinted;
    uint256 public totalTeamMinted;
    uint256 public totalOpenMinted;
    uint256 public totalSupply;
    bool public _finishInitialization;
    uint256 public endMintingPeriodDateAndTime;
    uint256 public nextVestingPeriodDataAndTime;

    string[15] private _firstAssets;
    string[15] private _secondAssets;
    string[15] private _thirdAssets;
    string[15] private _fourthAssets;
    string[15] private _fifthAssets;
    string[15] private _sixthAssets;
    string[15] private _seventhAssets;
    string[15] private _eightAssets;

    modifier onlyWhenInit() {
        require(!_finishInitialization, "Wut?");
        _;
    }

    modifier onlyWhenFinishInit() {
        require(_finishInitialization, "Can't call this yet");
        _;
    }

    modifier includesMintFee(uint256 amountToMint) {
        require(msg.value >= MINT_FEE * amountToMint, "Mint cost 0.0369258147 eth per token");
        _;
    }

    modifier onlyInMintingPeriod() {
        require(endMintingPeriodDateAndTime > block.timestamp, "Claiming period is over");
        _;
    }

    constructor(uint256 _endMintingPeriodDateAndTime) ERC721("Pythagorean Masks", "PythagoreanMasks") {
        endMintingPeriodDateAndTime = _endMintingPeriodDateAndTime;
        nextVestingPeriodDataAndTime = block.timestamp + (30 * 24 * 60 * 60);
    }

    function setFirstAssets(string[15] memory first) public onlyOwner onlyWhenInit {
        _firstAssets = first;
    }

    function setSecondAssets(string[15] memory second) public onlyOwner onlyWhenInit {
        _secondAssets = second;
    }

    function setThirdAssets(string[15] memory third) public onlyOwner onlyWhenInit {
        _thirdAssets = third;
    }

    function setFourthAssets(string[15] memory fourth) public onlyOwner onlyWhenInit {
        _fourthAssets = fourth;
    }

    function setFifthAssets(string[15] memory fifth) public onlyOwner onlyWhenInit {
        _fifthAssets = fifth;
    }

    function setSixthAssets(string[15] memory sixth) public onlyOwner onlyWhenInit {
        _sixthAssets = sixth;
    }

    function setSeventhAssets(string[15] memory seventh) public onlyOwner onlyWhenInit {
        _seventhAssets = seventh;
    }

    function setEightAssets(string[15] memory eight) public onlyOwner onlyWhenInit {
        _eightAssets = eight;
    }

    function finishInitialization(address newOwner) public onlyOwner onlyWhenInit {
        _finishInitialization = true;
        transferOwnership(newOwner);
    }

    function claimVestedTeamTokens(uint256[] memory tokenIds) public onlyOwner onlyWhenFinishInit {
        require(block.timestamp > nextVestingPeriodDataAndTime, "can't claim yet");
        // Vesting period every 1 month
        nextVestingPeriodDataAndTime = nextVestingPeriodDataAndTime + (30 * 24 * 60 * 60);
        for (uint256 i; i < tokenIds.length && i < 88; i++) {
            _safeTransfer(address(this), owner(), tokenIds[i], "");
        }
    }

    function mintToken(uint256 amountToMint)
        public
        payable
        nonReentrant
        includesMintFee(amountToMint)
        onlyInMintingPeriod
        onlyWhenFinishInit
    {
        require(amountToMint > 0, "Amount cannot be zero");
        require(totalOpenMinted < RESERVED_OPEN_TOKENS_TO_MINT, "Can't mint anymore");
        uint256 i;
        uint256 randomNumber = randomizer.getRandomNumber(MAX_SUPPLY, totalSupply);
        for (; i < amountToMint && totalOpenMinted < RESERVED_OPEN_TOKENS_TO_MINT; i++) {
            totalOpenMinted++;
            randomNumber = mintNextToken(randomNumber, msg.sender) + 1;
        }
        uint256 mintingFee = i * MINT_FEE;
        if (mintingFee > 0) {
            Address.sendValue(payable(owner()), mintingFee);
        }
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForNHolders(uint256 amountToMint)
        public
        payable
        nonReentrant
        includesMintFee(amountToMint)
        onlyInMintingPeriod
        onlyWhenFinishInit
    {
        require(amountToMint > 0, "Amount cannot be zero");
        require(totalNHoldersMinted < RESERVED_N_TOKENS_TO_MINT, "Can't mint anymore");
        uint256 balance = n.balanceOf(msg.sender);
        require(balance > 0 && balance > nHoldersMintedByAddress[msg.sender], "Insufficient balance");
        uint256 i;
        uint256 randomNumber = randomizer.getRandomNumber(MAX_SUPPLY, totalSupply);
        for (
            ;
            i < amountToMint &&
                totalNHoldersMinted < RESERVED_N_TOKENS_TO_MINT &&
                balance > nHoldersMintedByAddress[msg.sender];
            i++
        ) {
            totalNHoldersMinted++;
            nHoldersMintedByAddress[msg.sender]++;
            randomNumber = mintNextToken(randomNumber, msg.sender) + 1;
        }
        uint256 mintingFee = i * MINT_FEE;
        if (mintingFee > 0) {
            Address.sendValue(payable(owner()), mintingFee);
        }
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForPunkHolders(uint256 amountToMint)
        public
        payable
        nonReentrant
        includesMintFee(amountToMint)
        onlyInMintingPeriod
        onlyWhenFinishInit
    {
        require(amountToMint > 0, "Amount cannot be zero");
        require(totalPunkHoldersMinted < RESERVED_PUNK_TOKENS_TO_MINT, "Can't mint anymore");
        uint256 balance = punk.balanceOf(msg.sender);
        require(balance > 0 && balance > punkHoldersMintedByAddress[msg.sender], "Insufficient balance");
        uint256 i;
        uint256 randomNumber = randomizer.getRandomNumber(MAX_SUPPLY, totalSupply);
        for (
            ;
            i < amountToMint &&
                totalPunkHoldersMinted < RESERVED_PUNK_TOKENS_TO_MINT &&
                balance > punkHoldersMintedByAddress[msg.sender];
            i++
        ) {
            totalPunkHoldersMinted++;
            punkHoldersMintedByAddress[msg.sender]++;
            randomNumber = mintNextToken(randomNumber, msg.sender) + 1;
        }
        uint256 mintingFee = i * MINT_FEE;
        if (mintingFee > 0) {
            Address.sendValue(payable(owner()), mintingFee);
        }
        if (msg.value - mintingFee > 0) {
            Address.sendValue(payable(msg.sender), msg.value - mintingFee);
        }
    }

    function mintTokenReservedForTeam(uint256 amountToMint)
        public
        nonReentrant
        onlyOwner
        onlyInMintingPeriod
        onlyWhenFinishInit
    {
        require(totalTeamMinted < RESERVED_TEAM_TOKENS_TO_MINT, "Can't mint anymore");
        uint256 randomNumber = randomizer.getRandomNumber(MAX_SUPPLY, totalSupply);
        for (uint256 i; i < amountToMint && totalTeamMinted < RESERVED_TEAM_TOKENS_TO_MINT; i++) {
            totalTeamMinted++;
            // Only 10% now
            randomNumber = mintNextToken(randomNumber, totalTeamMinted > 87 ? address(this) : msg.sender) + 1;
        }
    }

    function getFirst(uint256 tokenId) public view returns (uint256) {
        return n.getFirst(tokenId);
    }

    function getSecond(uint256 tokenId) public view returns (uint256) {
        return n.getSecond(tokenId);
    }

    function getThird(uint256 tokenId) public view returns (uint256) {
        return n.getThird(tokenId);
    }

    function getFourth(uint256 tokenId) public view returns (uint256) {
        return n.getFourth(tokenId);
    }

    function getFifth(uint256 tokenId) public view returns (uint256) {
        return n.getFifth(tokenId);
    }

    function getSixth(uint256 tokenId) public view returns (uint256) {
        return n.getSixth(tokenId);
    }

    function getSeventh(uint256 tokenId) public view returns (uint256) {
        return n.getSeventh(tokenId);
    }

    function getEight(uint256 tokenId) public view returns (uint256) {
        return n.getEight(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        string[12] memory parts;

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 842 902"><defs><style> .cls-1{fill:#060606;}.cls-2{fill:url(#linear-gradient);}.cls-3{fill:url(#linear-gradient-2);}.cls-4{fill:url(#linear-gradient-3);}.cls-5{fill:url(#linear-gradient-4);}.cls-6{fill:url(#linear-gradient-5);}.cls-7{fill:url(#linear-gradient-6);}.cls-8{fill:url(#linear-gradient-7);}.cls-9{fill:url(#linear-gradient-8);}.cls-10{fill:url(#linear-gradient-9);}.cls-11{fill:url(#linear-gradient-10);} </style><linearGradient id="linear-gradient" x1="209.77" y1="593.77" x2="468.51" y2="548.14" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.01" stop-color="#acacac"/><stop offset="0.16" stop-color="#d0d0d0"/><stop offset="0.3" stop-color="#eaeaea"/><stop offset="0.43" stop-color="#fafafa"/><stop offset="0.53" stop-color="#fff"/></linearGradient><linearGradient id="linear-gradient-2" x1="314" y1="573.93" x2="314" y2="841.6" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.44" stop-color="#dbdbdb"/><stop offset="0.8" stop-color="#fff"/></linearGradient><linearGradient id="linear-gradient-3" x1="369.19" y1="485.41" x2="275.93" y2="646.94" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.13" stop-color="silver" stop-opacity="0.74"/><stop offset="0.28" stop-color="#d7d7d7" stop-opacity="0.47"/><stop offset="0.42" stop-color="#e8e8e8" stop-opacity="0.27"/><stop offset="0.56" stop-color="#f5f5f5" stop-opacity="0.12"/><stop offset="0.68" stop-color="#fcfcfc" stop-opacity="0.03"/><stop offset="0.78" stop-color="#fff" stop-opacity="0"/></linearGradient><linearGradient id="linear-gradient-4" x1="409.55" y1="666.27" x2="371.34" y2="666.27" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.25" stop-color="silver"/><stop offset="0.78" stop-color="#f7f7f7"/><stop offset="0.85" stop-color="#fff"/></linearGradient><linearGradient id="linear-gradient-5" x1="394.32" y1="669.89" x2="394.32" y2="689.04" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.3" stop-color="silver"/><stop offset="0.92" stop-color="#f7f7f7"/><stop offset="1" stop-color="#fff"/></linearGradient><linearGradient id="linear-gradient-6" x1="395.2" y1="659.62" x2="395.2" y2="708.24" gradientUnits="userSpaceOnUse"><stop offset="0.38" stop-color="#aaa"/><stop offset="0.48" stop-color="#acacac" stop-opacity="0.98"/><stop offset="0.58" stop-color="#b2b2b2" stop-opacity="0.91"/><stop offset="0.67" stop-color="#bbb" stop-opacity="0.8"/><stop offset="0.76" stop-color="#c8c8c8" stop-opacity="0.64"/><stop offset="0.85" stop-color="#dadada" stop-opacity="0.44"/><stop offset="0.94" stop-color="#eee" stop-opacity="0.2"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient><linearGradient id="linear-gradient-7" x1="411.09" y1="690.84" x2="411.09" y2="643.92" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.06" stop-color="#b4b4b4"/><stop offset="0.28" stop-color="#d4d4d4"/><stop offset="0.49" stop-color="#ececec"/><stop offset="0.68" stop-color="#fafafa"/><stop offset="0.85" stop-color="#fff"/></linearGradient><linearGradient id="linear-gradient-8" x1="379.82" y1="841.71" x2="379.82" y2="783.12" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#aaa"/><stop offset="0.17" stop-color="silver" stop-opacity="0.75"/><stop offset="0.55" stop-color="#ededed" stop-opacity="0.21"/><stop offset="0.72" stop-color="#fff" stop-opacity="0"/></linearGradient><linearGradient id="linear-gradient-9" x1="394.9" y1="762.41" x2="394.9" y2="803.85" gradientUnits="userSpaceOnUse"><stop offset="0.08" stop-color="#aaa"/><stop offset="0.26" stop-color="#c8c8c8" stop-opacity="0.65"/><stop offset="0.44" stop-color="#e0e0e0" stop-opacity="0.37"/><stop offset="0.59" stop-color="#f1f1f1" stop-opacity="0.17"/><stop offset="0.71" stop-color="#fbfbfb" stop-opacity="0.04"/><stop offset="0.79" stop-color="#fff" stop-opacity="0"/></linearGradient><linearGradient id="linear-gradient-10" x1="319.93" y1="509.65" x2="306.85" y2="583.81" gradientUnits="userSpaceOnUse"><stop offset="0.37" stop-color="#aaa"/><stop offset="0.43" stop-color="#b1b1b1" stop-opacity="0.91"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient></defs>';

        parts[1] = buildVariation(_firstAssets[getFirst(tokenId)]);
        parts[2] = buildVariation(_secondAssets[getSecond(tokenId)]);

        // Must be third
        parts[3] = buildVariation(
            '<path class="cls-2" d="M216.1,359.5l-12.4,52a34.9,34.9,0,0,0,3.5,24.9l8.1,14.6s11.6,26.1,3.1,56.2l-7.5,27.7a120.3,120.3,0,0,0,5,77.2c9.2,22,21.6,49.3,34.9,71.8,27,45.6,51.7,92.7,51.7,92.7s35.6,66.3,118.5,63.2V278.7s-97.8.6-171.2,38A64.5,64.5,0,0,0,216.1,359.5Z"/><path class="cls-3" d="M421,740.2V841.6c-82.4,1-118.5-65-118.5-65s-24.7-47.1-51.7-92.7c-13.3-22.5-25.7-49.8-34.9-71.8a120.2,120.2,0,0,1-8.9-38.2s1.6,29.9,36,44.3l48.8,25.7s28.8,14,36.6,45.8l9.6,26.6A22.7,22.7,0,0,0,355.5,731c7.7,1.3,17.4,2.7,25.2,2.7Z"/><path class="cls-4" d="M205.7,433.5s21.7,34.7,115.7,37c0,0,16.2-1.1,36.9,8.9a99.2,99.2,0,0,1,37.1,31.5l2.8,4a70.4,70.4,0,0,1,13,47c-1.7,21.2-4.5,49.8-7.9,64.4L401.7,641a59.4,59.4,0,0,0,1.7,22.2l4.1,15.4a15.8,15.8,0,0,0,12.7,11.6h.8v40.4l-93.5-72.4A326.8,326.8,0,0,1,223.2,519.4l-4.8-12.2s8.4-26.7-3.1-56.2Z"/><path class="cls-5" d="M409.5,683.2l-7.4-25.8a35.7,35.7,0,0,1-.7-8.1H385.2a13.1,13.1,0,0,0-11.4,6.6c-2.2,3.9-3.6,9.7-1.2,17.4Z"/><path class="cls-6" d="M372.6,673.3s1.2-3.9,9-3.3a23.8,23.8,0,0,1,10,3.1l17.9,10.1a17.5,17.5,0,0,0,3.2,3.5,13.3,13.3,0,0,0,3.7,2.3l-26.9-6.7-6.6-1.5C378.7,680,370.5,677.8,372.6,673.3Z"/><path class="cls-7" d="M372.2,659.6a29.3,29.3,0,0,0,0,15.3s-.5,4.3,13.8,6.5l29.5,7.2s2.9,2.1,5.5,1.7v17.9s-29.7-3.3-46.9-25c-5.2-6.5-6.1-14-2.7-23C371.5,659.9,371.9,659.8,372.2,659.6Z"/><path class="cls-1" d="M380.9,680.4c.4-1.7,4.3-2.7,8.2-1.7s6.7,3.4,6.3,5"/><path class="cls-8" d="M421,690.8s-6.1.4-11.5-7.6l-7.6-26.9s-1.3-4.5-.4-12.4H421Z"/><path class="cls-9" d="M421,841.6s-28.2,2.3-59-12.6-22.3-45.9-22.3-45.9l81.3,8Z"/><path class="cls-10" d="M372.2,775c8.3-7.1,21.2-12.6,48.8-12.6v41.5l-45-12.1A9.7,9.7,0,0,1,372.2,775Z"/><path class="cls-11" d="M394.3,566.5s-14.1-11-43.8-7.2-56.9-4.1-67.4-10.1c0,0-30.5-17-45-54,0,0-3.3,52.6,53.6,81.5S394.3,566.5,394.3,566.5Z"/>'
        );

        parts[5] = buildVariation(_thirdAssets[getThird(tokenId)]);
        parts[6] = buildVariation(_fourthAssets[getFourth(tokenId)]);
        parts[7] = buildVariation(_fifthAssets[getFifth(tokenId)]);
        parts[8] = buildVariation(_sixthAssets[getSixth(tokenId)]);
        parts[9] = buildVariation(_seventhAssets[getSeventh(tokenId)]);
        parts[10] = buildVariation(_eightAssets[getEight(tokenId)]);

        parts[11] = "</svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8])
        );
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11]));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "Pythagorean Mask # ',
                        toString(tokenId),
                        '", "description": "The Pythagorean school of thought teaches us that numbers are the basis of the entire universe, the base layer of perceived reality. The rest is but a mere expression of those. Numbers are all around us, have always been, will always be. Welcome to the n Collective.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));

        return output;
    }

    function buildVariation(string memory variation) internal pure returns (string memory output) {
        output = string(
            abi.encodePacked(
                "<g>",
                variation,
                "</g>",
                '<g transform="scale(-1 1) translate(-842,0)">',
                variation,
                "</g>"
            )
        );
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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

    // For gas efficiency, allowing to send the random number
    function mintNextToken(uint256 randomNumber, address to) internal returns (uint256) {
        uint256 nextTokenId = getNextToken(randomNumber);
        _safeMint(to, nextTokenId);
        totalSupply++;
        return nextTokenId;
    }

    function getNextToken(uint256 randomNumber) internal view returns (uint256) {
        uint256 nextToken = randomNumber;
        for (uint256 i; i < MAX_SUPPLY; i++) {
            if (!_exists(nextToken)) {
                break;
            }
            nextToken = (nextToken + 1) % MAX_SUPPLY;
        }
        return nextToken;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
