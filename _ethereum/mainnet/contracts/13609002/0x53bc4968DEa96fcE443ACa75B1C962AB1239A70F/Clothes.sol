// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC721Enumerable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Clothes is ERC721Enumerable, Ownable {
    uint256 constant MAX_SUPPLY = 2460;
    uint256 ownerMintsRemaining = 40;
    uint256 constant MAX_MINT = 5;
    uint256 deploymentTime;

    uint256 public rerolledCount = 0;
    mapping(uint256 => bool) wasRerolled;

    struct MintPass {
        IERC721Enumerable token;
        uint256 count;
        mapping(uint256 => bool) used;
    }

    MintPass[3] mintPasses;

    mapping(address => uint256) rerollsRemaining;
    mapping(address => uint256) mintCount;

    uint256 constant private ADJECTIVES_OFFSET = 0;
    uint256 constant private ADJECTIVES_COUNTS = (20 << 18) + (15 << 12) + (12 << 6) + 11;
    uint256 constant private COLORS_OFFSET = (20 + 15 + 12 + 11) * 16;
    uint256 constant private COLORS_COUNTS = (10 << 18) + (8 << 12) + (13 << 6) + 6;
    uint256 constant private MATERIALS_OFFSET = COLORS_OFFSET + (10 + 8 + 13 + 6) * 16;
    uint256 constant private MATERIALS_COUNTS = (7 << 18) + (7 << 12) + 1;
    uint256 constant private ARTICLES_OFFSET = MATERIALS_OFFSET + (7 + 7 + 1) * 16;
    uint256 constant private ARTICLES_COUNTS = (16 << 18) + (18 << 12) + (17 << 6) + 10;

    bytes constant data = hex"6c6f6e6700000000000000000000000073686f72740000000000000000000000746173746566756c000000000000000062726561746861626c650000000000006672696c6c790000000000000000000066757a7a790000000000000000000000666f726d616c0000000000000000000066616e6379000000000000000000000074696768740000000000000000000000736167677900000000000000000000006c6f6f736500000000000000000000006672756d70790000000000000000000064756c6c0000000000000000000000006375746500000000000000000000000064726162000000000000000000000000736c65656b0000000000000000000000736f6674000000000000000000000000666164656400000000000000000000007368696e790000000000000000000000636c65616e00000000000000000000006f6c642d66617368696f6e65640000006e617567687479000000000000000000737461696e2d726573697374616e74006e6561746c79207072657373656400007772696e6b6c65640000000000000000686970000000000000000000000000006368696300000000000000000000000064657369676e65720000000000000000736c696e6b79000000000000000000007363726174636879000000000000000073747265746368790000000000000000736b696d7079000000000000000000006d6f6465726e000000000000000000007374756e6e696e670000000000000000737472696b696e67000000000000000076696e74616765000000000000000000666f726d2d66697474696e6700000000736578790000000000000000000000007465617261776179000000000000000066696c746879000000000000000000006669657263650000000000000000000069726f6e696300000000000000000000726574726f0000000000000000000000736f7068697374696361746564000000656c6567616e74000000000000000000657870656e7369766500000000000000676c616d6f726f757300000000000000626564617a7a6c656400000000000000666972652d726574617264616e7400006c696d697465642d65646974696f6e006d6f6e6f6772616d6d6564000000000062756c6c65742d70726f6f66000000006472792d636c65616e206f6e6c790000776174657270726f6f660000000000007461696c6f726564000000000000000068616e642d737469746368656400000072657665727369626c65000000000000656469626c650000000000000000000079656c6c6f77000000000000000000006f72616e6765000000000000000000007265640000000000000000000000000070696e6b000000000000000000000000626c7565000000000000000000000000677265656e000000000000000000000062726f776e0000000000000000000000626c61636b000000000000000000000077686974650000000000000000000000677261790000000000000000000000006e656f6e20677265656e0000000000006e656f6e206f72616e676500000000006e656f6e2079656c6c6f7700000000006261627920626c7565000000000000006e61767920626c75650000000000000070656163680000000000000000000000637265616d0000000000000000000000666f7265737420677265656e000000007275627900000000000000000000000063686172747265757365000000000000696e6469676f000000000000000000007065726977696e6b6c650000000000006d61726f6f6e0000000000000000000073616c6d6f6e00000000000000000000686f742070696e6b00000000000000006c6176656e646572000000000000000063616e6479206170706c65207265640062757267756e64790000000000000000656d6572616c6400000000000000000070756d706b696e00000000000000000073696c7665720000000000000000000063616d6f75666c6167650000000000006c656f70617264207072696e740000007469652d647965640000000000000000707572706c65000000000000000000007261696e626f77000000000000000000676f6c6400000000000000000000000064656e696d00000000000000000000006c656174686572000000000000000000636f74746f6e00000000000000000000776f6f6c000000000000000000000000706f6c79657374657200000000000000666c616e6e656c0000000000000000006e796c6f6e00000000000000000000006c61636500000000000000000000000076656c766574000000000000000000006275726c617000000000000000000000666973686e6574000000000000000000736174696e00000000000000000000007477656564000000000000000000000073696c6b000000000000000000000000456779707469616e20636f74746f6e00742d73686972740000000000000000006c656767696e677300000000000000006a65616e730000000000000000000000636f6c6c61726564207368697274000064726573730000000000000000000000626c6f757365000000000000000000006e6967687420676f776e000000000000736b6972740000000000000000000000626f786572730000000000000000000073756974000000000000000000000000706f6c6f000000000000000000000000736e65616b65727300000000000000006865656c73000000000000000000000074726f7573657273000000000000000073616e64616c730000000000000000007363617266000000000000000000000063617072692070616e74730000000000636172676f2070616e74730000000000747572746c65206e65636b000000000074757865646f00000000000000000000676f776e000000000000000000000000686f6f6469650000000000000000000068616c74657220746f700000000000007472656e636820636f61740000000000676c6f766573000000000000000000006a756d706572000000000000000000007061726b610000000000000000000000736e6f7770616e7473000000000000007475626520746f700000000000000000736c6970706572730000000000000000626f6f7473000000000000000000000074696500000000000000000000000000626f772d7469650000000000000000007261696e636f617400000000000000006576656e696e6720676f776e0000000063726f7020746f7000000000000000006b696c74000000000000000000000000737765617465722076657374000000006d696e69736b6972740000000000000062656c6c2d626f74746f6d73000000006f766572616c6c730000000000000000736b6f72740000000000000000000000686f6f7020736b697274000000000000706c6174666f726d2073686f65730000737765617470616e74730000000000006c65677761726d6572730000000000006c6f6e6720756e64657277656172000067616c6f736865730000000000000000666c69702d666c6f707300000000000073757370656e64657273000000000000706561636f6174000000000000000000726f6265000000000000000000000000747261636b2073756974000000000000736f636b7300000000000000000000007061726163687574652070616e747300726f6c6c657220736b617465730000006865656c6965730000000000000000006f6e65736965000000000000000000006173736c6573732063686170730000006c696e6765726965000000000000000063726f63730000000000000000000000";

    constructor(
        IERC721Enumerable book,
        IERC721Enumerable signet,
        IERC721Enumerable boomerang
    )
        ERC721("The Emperor's Non-fungible Clothes", "CLOTHES")
    {
        mintPasses[0].token = book;
        mintPasses[0].count = 30;

        mintPasses[1].token = signet;
        mintPasses[1].count = 25;

        mintPasses[2].token = boomerang;
        mintPasses[2].count = 2**256-1; // infinity

        deploymentTime = block.timestamp;
    }

    function contractURI() public pure returns (string memory) {
        return string(abi.encodePacked(
            'data:application/json;base64,',
            b64(abi.encodePacked(
                '{'
                    '"name": "The Emperor\'s Non-fungible Clothes",'
                    '"description": "Only the wise can see the Emperor\'s Non-fungible Clothes. Up to 2,500 unique NFTs (but collectors determine the final number!), 100% on chain. No website, and no roadmap.\\n\\nNote that this is the final artwork, permanently stored on the blockchain. The idea for this generative NFT project came about from a discussion about how a URL pointing to a JPEG or GIF is the least interesting part of a NFT.",'
                    '"image": "', getImage(), '"'
                '}'
            ))
        ));
    }

    // This function automatically mints using any available mint passes. It
    // also mints one token per 0.02 ETH sent. There is a maximum of 5 tokens
    // minted per address, and the total supply is limited to 2500, including
    // rerolled tokens.
    function mint() external payable {
        require(block.timestamp >= deploymentTime + 24 hours || msg.value == 0, "Only mint passes are accepted for the first 24 hours.");
        require(msg.value % 0.02 ether == 0, "You can only send a multiple of 0.02 ETH.");
        require(totalSupply() + rerolledCount < MAX_SUPPLY, "Cap reached.");
        uint256 available = MAX_SUPPLY - (totalSupply() + rerolledCount);

        uint256 howMany = 0;
        uint256 rerolls = 0;

        // for each mint pass
        for (uint256 i = 0; i < mintPasses.length; i++) {
            MintPass storage pass = mintPasses[i];

            // if the sender has at least one token
            if (pass.token.balanceOf(msg.sender) > 0) {
                // get their first token (should only have one)
                uint256 tokenId = pass.token.tokenOfOwnerByIndex(msg.sender, 0);

                // if the token ID is unused and less than the allowed count
                if (tokenId < pass.count && !pass.used[tokenId]) {
                    // use up the token
                    pass.used[tokenId] = true;

                    // grant another free clothes token (with reroll)
                    howMany += 1;
                    rerolls += 1;
                }
            }
        }

        // bonus for having all 3!
        if (howMany == 3) {
            howMany = 5;
            rerolls = 5;
        }

        if (howMany > available) {
            howMany = available;
            rerolls = 0; // there will be no tokens left to generate
        }

        // 0.02 ETH per paid token
        uint256 paid = msg.value / 0.02 ether;
        howMany += paid;
        rerolls += paid / 2; // one reroll per two paid tokens

        require(howMany <= available, "Cap reached.");
        require(howMany > 0, "Not minting anything.");

        mintCount[msg.sender] += howMany;
        rerollsRemaining[msg.sender] += rerolls;
        require(mintCount[msg.sender] <= MAX_MINT, "Can't mint more than 5 tokens.");

        for (uint256 i = 0; i < howMany; i++) {
            _mintOne(msg.sender);
        }
    }

    // 40 are held back for founders to mint just in case everything sells out
    function ownerMint(uint256 howMany, address to) external onlyOwner {
        require(ownerMintsRemaining > howMany);
        ownerMintsRemaining -= howMany;

        for (uint256 i = 0; i < howMany; i++) {
            _mintOne(to);
        }
    }

    // extract lambos
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function _mintOne(address recipient) internal {
        uint256 tokenId = gen();
        // generate token IDs until we found one unclaimed and unrerolled
        while (_exists(tokenId) || wasRerolled[tokenId]) {
            tokenId = gen();
        }

        // mint the token we generated
        _mint(recipient, tokenId);
    }

    // Give up a token in exchange for another randomly selected one. Rerolls
    // are limited. Mint passes give you one reroll per token, and purchased
    // tokens give you half as many rerolls as tokens purchased (in one call).
    // To maximize available rerolls, make sure to purchase at least two tokens
    // in each call to mint().
    function reroll(uint256 tokenId) external {
        require(totalSupply() + rerolledCount < MAX_SUPPLY, "Cap reached.");
        require(rerollsRemaining[msg.sender] > 0, "No rerolls remaining.");
        require(ownerOf(tokenId) == msg.sender, "Only owner may reroll.");

        rerollsRemaining[msg.sender] -= 1;
        wasRerolled[tokenId] = true;
        rerolledCount += 1;
        _burn(tokenId);

        _mintOne(msg.sender);
    }

    uint256 internalSeed = 0;
    function rand(uint256 max) internal returns (uint256) {
        return uint256(keccak256(abi.encode(
            msg.sender,
            block.timestamp,
            block.difficulty,
            blockhash(block.number - 1),
            internalSeed++))) % max;
    }
    
    function choose(uint256 counts) internal returns (uint256) {
        uint256 a = counts >> 18;
        uint256 b = (counts >> 12) & 0x3F;
        uint256 c = (counts >> 6) & 0x3F;
        uint256 d = counts & 0x3F;
        
        uint256 range = a * 10 + b * 7 + c * 4 + d * 2;
        
        uint256 r = rand(range);

        uint256 i = 0;
        while (true) {
            uint256 score = i < a ? 10 : i < a+b ? 7 : i < a+b+c ? 4 : 2;
            if (r < score) {
                return i;
            }
            r -= score;
            i += 1;
        }
        
        revert();
    }

    function wordFor(uint256 offset, uint256 index) internal pure returns (string memory) {
        uint256 position = offset + index*16;
        uint128 word = 0;

        for (uint256 i = 0; i < 16; i++) {
            word *= 256;
            word += uint8(data[position+i]);
        }

        return string(trim(abi.encodePacked(word)));
    }

    function gen() internal returns (uint256) {
        if (rand(500) == 0) {
            return rand(3);
        }
        
        if (rand(125) == 0) {
            return (1 << 32) + choose(ARTICLES_COUNTS);
        }
        
        return (2 << 32) + (choose(ADJECTIVES_COUNTS) << 24) + (choose(COLORS_COUNTS) << 16) + (choose(MATERIALS_COUNTS) << 8) + choose(ARTICLES_COUNTS);
    }

    function getImage() pure internal returns (string memory) {
        return string(abi.encodePacked(
            'data:image/svg+xml;base64,',
            b64('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 76 76" version="1.1"><rect x="4" y="4" width="68" height="68" ry="5" style="fill:#ffffff;stroke:#808080;stroke-width:2;stroke-linecap:round;stroke-dasharray:3,5"/></svg>')
        ));
    }

    function tokenURI(uint256 id) public pure override returns (string memory) {
        uint8 typ = uint8(id >> 32);
        uint8 adjective = uint8(id >> 24);
        uint8 color = uint8(id >> 16);
        uint8 material = uint8(id >> 8);
        uint8 article = uint8(id);
        
        string memory name;
        string memory adjectiveString;
        string memory colorString;
        string memory materialString;
        string memory articleString;
        
        if (typ == 0) {
            name = article == 0 ? "ugly Christmas sweater" : article == 1 ? "itsy-bitsy teeny-weeny yellow polka dot bikini" : "Hawaiian shirt";
        } else if (typ == 1) {
            adjectiveString = "diamond";
            articleString = wordFor(ARTICLES_OFFSET, article);
            name = string(abi.encodePacked("diamond ", articleString));
        } else {
            adjectiveString = wordFor(ADJECTIVES_OFFSET, adjective);
            colorString = wordFor(COLORS_OFFSET, color);
            materialString = wordFor(MATERIALS_OFFSET, material);
            articleString = wordFor(ARTICLES_OFFSET, article);
            name = string(abi.encodePacked(
                adjectiveString, " ",
                colorString, " ",
                materialString, " ",
                articleString
            ));
        }
        
        return string(abi.encodePacked(
            "data:application/json;base64,",
            b64(abi.encodePacked(
                "{",
                '"name":"the Emperor\'s ', name, '","image":"',
                getImage(),
                '","attributes":[',
                typ == 0
                ? abi.encodePacked(
                    '{"trait_type":"article","value":"',
                    name,
                    '"}]}')
                : abi.encodePacked(
                    '{"trait_type":"adjective","value":"',
                    adjectiveString,
                    '"},',
                    bytes(colorString).length != 0
                    ? string(abi.encodePacked(
                        '{"trait_type":"color","value":"',
                        colorString,
                        '"},{"trait_type":"material","value":"',
                        materialString,
                        '"},'))
                    : '',
                    abi.encodePacked(
                        '{"trait_type":"article","value":"',
                        articleString,
                        '"}]}'
                    )
                )
            ))
        ));
    }
    
    function trim(bytes memory input) internal pure returns (bytes memory) {
        uint256 len = 0;
        while (len < input.length && input[len] != 0) {
            len += 1;
        }
        bytes memory output = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            output[i] = input[i];
        }
        return output;
    }

    bytes constant private base64stdchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function b64(bytes memory bs) internal pure returns (string memory) {
        uint256 rem = bs.length % 3;

        uint256 res_length = (bs.length + 2) / 3 * 4;
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= bs.length; i += 3) {
            (res[j], res[j+1], res[j+2], res[j+3]) = encode3(
                uint8(bs[i]),
                uint8(bs[i+1]),
                uint8(bs[i+2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(bs[bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(bs[bs.length - 1]);
            }

            (bytes1 b0, bytes1 b1, bytes1 b2, ) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j+1] = b1;
            if (rem == 2) {
              res[j+2] = b2;
            }
        }
        
        for (uint256 k = j + rem+1; k < res_length; k++) {
            res[k] = '=';
        }

        return string(res);
    }

    function encode3(uint256 a0, uint256 a1, uint256 a2)
        private
        pure
        returns (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3)
    {

        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >>  6) & 63;
        uint256 c3 = (n      ) & 63;

        b0 = base64stdchars[c0];
        b1 = base64stdchars[c1];
        b2 = base64stdchars[c2];
        b3 = base64stdchars[c3];
    }
}
