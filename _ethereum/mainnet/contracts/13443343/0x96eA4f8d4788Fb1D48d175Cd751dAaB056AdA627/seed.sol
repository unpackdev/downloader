// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface GM420 {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}


contract Seed is ERC721Enumerable, ReentrancyGuard, Ownable, AccessControl {

    using SafeMath for uint256;
    using Strings for uint256;

    bytes32 public constant WHITE_LIST_ROLE = keccak256("WHITE_LIST_ROLE");
    uint256 public constant PRICE = 0.04 ether;
    uint256 public constant TOTAL_NUMBER_OF_SEEDS_PAIRS = 5330;
    uint256 public constant TOTAL_NUMBER_OF_SEED_TOKENS = TOTAL_NUMBER_OF_SEEDS_PAIRS * 2;
    uint256 public constant SEED_WORDS_PER_TOKEN = 12;
    uint256 public constant MAX_MINT_PER_TRANSACTION = 10;

    uint256 public giveaway_reserved_pairs = 50;
    uint256 public gm420_pre_mint_reserved_pairs = 420;

    uint256 public minted_seed_pairs = 0;

    mapping(uint256 => bool) private _gm420_redeemed_tokens;

    bool public paused_mint = true;
    bool public paused_gm420_pre_mint = true;

    bool public words_can_be_added = true;
    mapping(uint256 => string) public seeds_to_plant;
    uint256 public seed_words_count = 0;

    address gm420;

    // withdraw addresses
    address lolabs_splitter;

    modifier whenMintNotPaused() {
        require(!paused_mint, "Seed: mint is paused");
        _;
    }

    modifier whenPreMintNotPaused() {
        require(!paused_gm420_pre_mint, "Seed: pre mint is paused");
        _;
    }

    modifier senderIsGm420TokenOwner(uint256 gm420TokenId) {
        bool is_gm420_token_owner = false;
        uint256 tokenCount = GM420(gm420).balanceOf(msg.sender);
        for (uint256 i; i < tokenCount; i++) {
            uint256 ownerTokenId = GM420(gm420).tokenOfOwnerByIndex(msg.sender, i);
            if (ownerTokenId == gm420TokenId) {
                is_gm420_token_owner = true;
                break;
            }
        }

        require(is_gm420_token_owner, "Seed: GM420 token is not owned by the sender.");
        _;
    }

    event MintPaused(address account);

    event MintUnpaused(address account);

    event PreMintPaused(address account);

    event PreMintUnpaused(address account);

    event GM420Redeemed(address account, uint256 gm420Token);

    function random(string memory input) public pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input,'lola_is_the_perfectest_dog')));
    }

    function check_words_duplication(uint256[SEED_WORDS_PER_TOKEN] memory words, uint256 words_count, uint256 new_word) public pure returns (bool) {
        for (uint256 i; i < words_count; i++) {
            if (words[i] == new_word) {
                return true;
            }
        }

        return false;
    }

    function seeds_factory(uint256 tokenId) internal view returns (string[SEED_WORDS_PER_TOKEN] memory) {
        string[SEED_WORDS_PER_TOKEN] memory words_selected;
        uint256[SEED_WORDS_PER_TOKEN] memory words_selected_indexes;

        for (uint256 i; i < SEED_WORDS_PER_TOKEN; i++) {
            uint256 rand = random(string(abi.encodePacked(i.toString(), tokenId.toString())));
            uint256 rand_word_index = rand % seed_words_count;

            while (check_words_duplication(words_selected_indexes, i, rand_word_index)) {
                rand = rand + 1;
                rand_word_index = rand % seed_words_count;
            }

            words_selected_indexes[i] = rand_word_index;
            words_selected[i] = seeds_to_plant[rand_word_index];
        }

        return words_selected;
    }


    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "Seeds: cannot display non existing token");

        string[SEED_WORDS_PER_TOKEN] memory words_selected = seeds_factory(tokenId);
        string memory color;
        if (tokenId % 2 == 1) {
            color = 'red' ;
        } else {
            color = 'blue';
        }
        string memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="';
        output = string(abi.encodePacked(output, color, '" /><text x="10" y="20" class="base">'));
        string memory attributes = string(abi.encodePacked('[', '{"trait_type":"Color", "value":"', color, '"},'));
        uint256 y = 40;
        for (uint256 i; i < SEED_WORDS_PER_TOKEN; i++) {
            string memory separator = string(abi.encodePacked('</text><text x="10" y="', ((i * 20) + y).toString(), '" class="base">'));
            output = string(abi.encodePacked(output, separator, words_selected[i]));
            if(i != SEED_WORDS_PER_TOKEN-1) {
                attributes = string(abi.encodePacked(attributes, '{"value":"', words_selected[i], '"},'));
            } else {
                attributes = string(abi.encodePacked(attributes, '{"value":"', words_selected[i], '"}]'));
            }
        }
        output = string(abi.encodePacked(output, '</text></svg>'));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "S33D #', tokenId.toString(),
            '", "description": "S33D is a collection of randomized seed phrases generated and stored on-chain. S33D can be used for riddles and puzzles. You can use it for anything you want. It\'s a seed phrase. It\'s fun.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)),
            '","attributes": ', attributes,
            '}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;

    }

    function mint(uint256 num) public payable nonReentrant whenMintNotPaused() {
        require(num <= MAX_MINT_PER_TRANSACTION, "Seed: You can mint a maximum of 10 Seeds");
        require(msg.value >= PRICE * num, "Seeds: Ether sent is less than PRICE*num");
        require(minted_seed_pairs + num <= TOTAL_NUMBER_OF_SEEDS_PAIRS - (giveaway_reserved_pairs + gm420_pre_mint_reserved_pairs), "Seed: Exceeds maximum Seeds supply");
        require(msg.sender == tx.origin, "Seeds: contracts cannot mint");

        for (uint256 i = 0; i < num; i++) {
            _lfg(msg.sender);
        }
    }

    function claim(uint256 gm420TokenId) public whenPreMintNotPaused() nonReentrant senderIsGm420TokenOwner(gm420TokenId) {
        require(gm420_pre_mint_reserved_pairs > 0, "Seed: all gm420 tokens were redeemed");
        require(_gm420_redeemed_tokens[gm420TokenId] == false, "Seed: GM420 token was already redeemed");
        _gm420_redeemed_tokens[gm420TokenId] = true;
        gm420_pre_mint_reserved_pairs -= 1;
        _lfg(msg.sender);
        emit GM420Redeemed(msg.sender, gm420TokenId);
    }

    function claimAll() public whenPreMintNotPaused() nonReentrant {
        require(gm420_pre_mint_reserved_pairs > 0, "Seed: all gm420 tokens were redeemed");

        uint256 tokenCount = GM420(gm420).balanceOf(msg.sender);
        for (uint256 i; i < tokenCount; i++) {
            uint256 gm420TokenId = GM420(gm420).tokenOfOwnerByIndex(msg.sender, i);

            if (!_gm420_redeemed_tokens[gm420TokenId] && gm420_pre_mint_reserved_pairs > 0) {
                _gm420_redeemed_tokens[gm420TokenId] = true;
                gm420_pre_mint_reserved_pairs -= 1;
                _lfg(msg.sender);
                emit GM420Redeemed(msg.sender, gm420TokenId);
            }

        }
    }

    function giveaway(address _to) external onlyRole(WHITE_LIST_ROLE) {
        require(0 < giveaway_reserved_pairs, "Seed: giveaway more than supply of reserved");
        giveaway_reserved_pairs = giveaway_reserved_pairs - 1;
        _lfg(_to);
    }

    function giveawayBatch(address _to, uint256 count) external onlyRole(WHITE_LIST_ROLE) {
        require(0 <= giveaway_reserved_pairs - count, "Seed: giveawayBatch more than supply of reserved");
        for (uint256 i; i < count; i++) {
            giveaway_reserved_pairs = giveaway_reserved_pairs - 1;
            _lfg(_to);
        }
    }

    function _lfg(address _to) internal {
        uint256 supply = totalSupply();
        minted_seed_pairs = minted_seed_pairs + 1;
        _safeMint(_to, supply);
        _safeMint(_to, supply + 1);
    }

    function pauseMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_mint = true;
        emit MintPaused(msg.sender);
    }

    function unpauseMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_mint = false;
        emit MintUnpaused(msg.sender);
    }

    function pausePreMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_gm420_pre_mint = true;
        emit PreMintPaused(msg.sender);
    }

    function unpausePreMint() public onlyRole(WHITE_LIST_ROLE) {
        paused_gm420_pre_mint = false;
        emit PreMintUnpaused(msg.sender);
    }

    function updateLolaSplitterAddress(address _lolabs_splitter) public onlyRole(WHITE_LIST_ROLE) {
        lolabs_splitter = _lolabs_splitter;
    }

    function getLolabsSplitter() view public onlyRole(WHITE_LIST_ROLE) returns(address splitter) {
        return lolabs_splitter;
    }

    function updateGM420Address(address _gm420) public onlyRole(WHITE_LIST_ROLE) {
        gm420 = _gm420;
    }

    function getGM420Address() view public returns(address) {
        return gm420;
    }

    function accountIsGM420TokenOwner() view public returns(bool) {
        uint256 tokenCount = GM420(gm420).balanceOf(msg.sender);
        return tokenCount > 0;
    }

    function withdrawAmountToSplitter(uint256 amount) public onlyRole(WHITE_LIST_ROLE) {
        uint256 _balance = address(this).balance ;
        require(_balance > 0, "Seed: withdraw amount call without balance");
        require(_balance-amount >= 0, "Seed: withdraw amount call with more than the balance");
        require(payable(lolabs_splitter).send(amount), "Seed: FAILED withdraw amount call");
    }

    function withdrawAllToSplitter() public onlyRole(WHITE_LIST_ROLE) {
        uint256 _balance = address(this).balance ;
        require(_balance > 0, "Seed: withdraw all call without balance");
        require(payable(lolabs_splitter).send(_balance), "Seed: FAILED withdraw all call");
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function is_gm420_token_redeemed(uint256 gm420TokenId) public view returns(bool) {
        require(gm420TokenId >= 0 && gm420TokenId < 420, "Seed: Token ID invalid");
        return _gm420_redeemed_tokens[gm420TokenId];
    }

    function add_seeds_to_plant(string[] memory seeds_to_add) public onlyRole(WHITE_LIST_ROLE) {
        require(words_can_be_added, "Seed: cannot add seed words when locked");
        for(uint256 i; i < seeds_to_add.length; i++){
            seeds_to_plant[seed_words_count] = seeds_to_add[i];
            seed_words_count = seed_words_count + 1;
        }
    }

    function lock_seed_words() public onlyRole(WHITE_LIST_ROLE) {
        words_can_be_added = false;
    }

    constructor(address lolabs_team, address splitter, address gm420_contract) ERC721("Seed", "SEED") Ownable() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, lolabs_team);

        _setupRole(WHITE_LIST_ROLE, msg.sender);
        _setupRole(WHITE_LIST_ROLE, lolabs_team);

        gm420 = gm420_contract;
        lolabs_splitter = splitter;

    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

receive() external payable {}

fallback() external payable {}
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