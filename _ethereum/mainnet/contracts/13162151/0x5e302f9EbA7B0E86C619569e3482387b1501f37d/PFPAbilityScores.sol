//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./PFPAbilityScoresSvgs.sol";

contract PFPAbilityScores is ERC721Enumerable, ERC721Burnable, Ownable, ReentrancyGuard {
    // ON-CHAIN METADATA
    PFPAbilityScoresSvgs metadata;

    // CONSTANTS
    uint256 public constant MINT_PRICE = 15000000000000000;
    uint256 public constant MAX_PURCHASE_COUNT = 20;
    uint256 public MAX_NFT_COUNT = 40000;

    // METADATA SEED
    uint256 public FINAL_BLOCK_HEIGHT = 0;
    uint256 public RANDOM_SEED = 0;

    // ABILITIES
    uint256 NUM_TRAITS = 6;
    uint256 NUM_ELEMENTS = 6;
    uint256[15] SCORE_THRESHOLDS = [5, 17, 38, 70, 118, 186, 281, 411, 588, 827, 1147, 1574, 2142, 2896, 3896];

    uint256 OFFSET_TRAITS   = 0;
    uint256 OFFSET_ELEMENTS = 16;
    uint256 OFFSET_SCORE    = 32;

    uint256 TRAIT_MASK   = 0xffff;
    uint256 ELEMENT_MASK = 0xffff;
    uint256 SCORE_MASK   = 0xffffffff;

    uint8 DEFAULT_SCORE = 10;
    uint256 MIN_SCORE = 11;
    uint256 MAX_SCORE = 25;

    enum AbilityTrait { STR, DEX, CON, INT, WIS, CHA }
    enum AbilityElement { VOID, EARTH, FIRE, LIGHTNING, WIND, WATER }
    struct Ability {
        uint256        tokenId;
        AbilityTrait   trait;
        AbilityElement element;
        uint8          score;
    }

    // METADATA
    string public DESCRIPTION = "These are a set of 100% on-chain stats (Strength, Dexterity, Constitution, Intelligence, Wisdom, and Charismma) you can rely on being available for any wallet, anytime.  Work to collect, trade, and upgrade your PFP's abilities today.";
    string public EXTERNAL_URL = "https://pfpabilityscores.eth.link";

    // LOGIC
    constructor(address _metadata) ERC721("PFP Ability Scores", "PFPABILITYSCORES") {
        metadata = PFPAbilityScoresSvgs(_metadata);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setDescription(string calldata _desc) public onlyOwner {
        DESCRIPTION = _desc;
    }

    function setExternalUrl(string calldata _url) public onlyOwner {
        EXTERNAL_URL = _url;
    }

    function burnRemaining() public onlyOwner {
        require(totalSupply() < MAX_NFT_COUNT, "Can't burn remaining when supply is max");
        MAX_NFT_COUNT = totalSupply(); // Reduce supply
        _setFinalBlock(); // Set final block
    }

    function purchase(uint256 _numTokens) public payable nonReentrant {
        require(_numTokens <= MAX_PURCHASE_COUNT, "Max 20 NFTs can be minted");
        require((MINT_PRICE * _numTokens) == msg.value, "Incorrect ETH amount sent");
        require((totalSupply() + _numTokens) <=  MAX_NFT_COUNT, "Mint request exceeds supply");

        uint256 _tokenId = totalSupply();
        for (uint256 i = 0; i < _numTokens; i++) {
            _safeMint(msg.sender, ++_tokenId);
        }

        if (totalSupply() == MAX_NFT_COUNT) {
            _setFinalBlock();
        }
    }

    function airdrop(address[] calldata _to, uint256 _numTokensEach) public nonReentrant onlyOwner {
        require((totalSupply() + _numTokensEach * _to.length) <=  MAX_NFT_COUNT, "Mint request exceeds supply");

        uint256 _tokenId = totalSupply();

        for (uint256 iAddr = 0; iAddr < _to.length; iAddr++) {
            for (uint256 i = 0; i < _numTokensEach; i++) {
                _safeMint(_to[iAddr], ++_tokenId);
            }
        }

        if (totalSupply() == MAX_NFT_COUNT) {
            _setFinalBlock();
        }
    }

    function _setFinalBlock() internal {
        require(FINAL_BLOCK_HEIGHT == 0, "Final block height already set");
        FINAL_BLOCK_HEIGHT = block.number;
    }

    function lockSeed() public nonReentrant {
        require(FINAL_BLOCK_HEIGHT > 0, "Final block height not set");
        require(RANDOM_SEED == 0, "Random seed already set");

        // Use the blockhash of the final block height to determine the random seed
        if (FINAL_BLOCK_HEIGHT + 255 <= block.number) {
            RANDOM_SEED = uint256(
                keccak256(
                    abi.encodePacked(
                        FINAL_BLOCK_HEIGHT,
                        blockhash(FINAL_BLOCK_HEIGHT)
                    )
                )
            );
        // If, for whatever reason, we don't set the random seed in time, then fallback
        } else {
            RANDOM_SEED = uint256(
                keccak256(
                    abi.encodePacked(
                        FINAL_BLOCK_HEIGHT,
                        owner()
                    )
                )
            );
        }
    }

    function revealed() public view returns (bool) {
        return RANDOM_SEED > 0;
    }

    function getStats(address _wallet) public view returns(Ability[] memory stats) {
        stats = new Ability[](6);

        // Defaults
        for (uint256 i = 0; i < stats.length; i++) {
            stats[i].trait = AbilityTrait(i);
            stats[i].score = DEFAULT_SCORE;
        }

        if (revealed()) {
            // Get stats
            uint256 balance = balanceOf(_wallet);
            for (uint256 i = 0; i < balance; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(_wallet, i);
                Ability memory tokenAbility = getTokenAbility(tokenId);
                if (stats[uint256(tokenAbility.trait)].score < tokenAbility.score) {
                    stats[uint256(tokenAbility.trait)] = tokenAbility;
                }
            }
        }
    }

    function getElementalStats(address _wallet, uint256 _element) public view returns(Ability[] memory stats) {
        stats = new Ability[](6);

        // Defaults
        for (uint256 i = 0; i < stats.length; i++) {
            stats[i].trait = AbilityTrait(i);
            stats[i].score = DEFAULT_SCORE;
        }

        if (revealed()) {
            // Get stats
            uint256 balance = balanceOf(_wallet);
            for (uint256 i = 0; i < balance; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(_wallet, i);
                Ability memory tokenAbility = getTokenAbility(tokenId);
                if (tokenAbility.element == AbilityElement(_element)) {
                    if (stats[uint256(tokenAbility.trait)].score < tokenAbility.score) {
                        stats[uint256(tokenAbility.trait)] = tokenAbility;
                    }
                }
            }
        }
    }

    function getAbilityStats(address _wallet, uint256 _trait) public view returns(Ability memory abilityStats) {
        abilityStats = Ability(0, AbilityTrait(_trait), AbilityElement(0), DEFAULT_SCORE);

        if (revealed()) {
            // Get stats
            uint256 balance = balanceOf(_wallet);
            for (uint256 i = 0; i < balance; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(_wallet, i);
                Ability memory tokenAbility = getTokenAbility(tokenId);
                if (tokenAbility.trait == AbilityTrait(_trait)) {
                    if (abilityStats.score < tokenAbility.score) {
                        abilityStats = tokenAbility;
                    }
                }
            }
        }
    }

    function getStrength(address _wallet) public view returns(Ability memory) {
        return getAbilityStats(_wallet, uint256(AbilityTrait.STR));
    }

    function getDexterity(address _wallet) public view returns(Ability memory) {
        return getAbilityStats(_wallet, uint256(AbilityTrait.DEX));
    }

    function getConstitution(address _wallet) public view returns(Ability memory) {
        return getAbilityStats(_wallet, uint256(AbilityTrait.CON));
    }

    function getIntelligence(address _wallet) public view returns(Ability memory) {
        return getAbilityStats(_wallet, uint256(AbilityTrait.INT));
    }

    function getWisdom(address _wallet) public view returns(Ability memory) {
        return getAbilityStats(_wallet, uint256(AbilityTrait.WIS));
    }

    function getCharisma(address _wallet) public view returns(Ability memory) {
        return getAbilityStats(_wallet, uint256(AbilityTrait.CHA));
    }

    function getTokenAbility(uint256 _tokenId) public view returns (Ability memory) {
        if (!revealed()) {
            return Ability(_tokenId, AbilityTrait(0), AbilityElement(0), DEFAULT_SCORE);
        }

        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(RANDOM_SEED, _tokenId)
            )
        );

        // Determine the trait, element
        AbilityTrait   trait   = getTrait(randomNumber);
        AbilityElement element = getElement(randomNumber);

        // Determine the score
        uint8 score = getScore(randomNumber);

        return Ability(_tokenId, trait, element, score);
    }

    function getTrait(uint256 _random) internal view returns (AbilityTrait) {
        return AbilityTrait(((_random >> OFFSET_TRAITS) & TRAIT_MASK) % NUM_TRAITS);
    }

    function getElement(uint256 _random) internal view returns (AbilityElement) {
        if (_random == 0) {
            return AbilityElement(0); // VOID
        }

        return AbilityElement((((_random >> OFFSET_ELEMENTS) & ELEMENT_MASK) % (NUM_ELEMENTS - 1)) + 1);
    }

    function getScore(uint256 _random) internal view returns (uint8) {
        if (_random == 0) {
            return DEFAULT_SCORE; // Default per wallet
        }

        uint256 score = ((_random >> OFFSET_SCORE) & SCORE_MASK) % SCORE_THRESHOLDS[SCORE_THRESHOLDS.length - 1];

        // Start at the second-to-last, work down
        for (uint256 i = SCORE_THRESHOLDS.length - 2; i > 0; i--) {
            if (score >= SCORE_THRESHOLDS[i]) {
                return uint8(MAX_SCORE - (i + 1));
            }
        }

        if (score >= SCORE_THRESHOLDS[0]) {
            return uint8(MAX_SCORE - 1);
        }

        return uint8(MAX_SCORE);
    }


    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(totalSupply() >= _tokenId, "Token ID does not exist");

        // Pre-reveal
        if (RANDOM_SEED == 0) {
            return string(
                abi.encodePacked(
                    abi.encodePacked(
                        bytes('data:application/json;utf8,{"name":"Ability #'),
                        uint2str(_tokenId),
                        bytes('","description":"'),
                        DESCRIPTION,
                        bytes('","external_url":"'),
                        bytes(EXTERNAL_URL),
                        bytes('","image_data":"'),
                        metadata.getDefaultSvg(),
                        bytes('"}')
                    )
                )
            );
        }

        Ability memory ability = getTokenAbility(_tokenId);

        return string(
            abi.encodePacked(
                abi.encodePacked(
                    bytes('data:application/json;utf8,{"name":"Ability #'),
                    uint2str(_tokenId),
                    bytes('","description":"'),
                    DESCRIPTION,
                    bytes('","external_url":"'),
                    bytes(EXTERNAL_URL),
                    bytes('","image_data":"'),
                    metadata.getSvg(uint256(ability.trait), uint256(ability.element), uint256(ability.score))
                ),
                abi.encodePacked(
                    bytes('","attributes":[{"trait_type": "Ability", "value": "'),
                    traitToString(ability.trait),
                    bytes('"},{"trait_type": "Element", "value": "'),
                    elementToString(ability.element),
                    bytes('"},{"trait_type": "Score", "value": '),
                    uint2str(uint256(ability.score)),
                    bytes('}]}')
                )
            )
        );
    }

    function traitToString(AbilityTrait _trait) public pure returns (string memory) {
        if (_trait == AbilityTrait.STR) {
            return "Strength";
        } else if (_trait == AbilityTrait.DEX) {
            return "Dexterity";
        } else if (_trait == AbilityTrait.CON) {
            return "Constitution";
        } else if (_trait == AbilityTrait.INT) {
            return "Intelligence";
        } else if (_trait == AbilityTrait.WIS) {
            return "Wisdom";
        } else if (_trait == AbilityTrait.CHA) {
            return "Charisma";
        }

        return "";
    }

    function elementToString(AbilityElement _element) public pure returns (string memory) {
        if (_element == AbilityElement.EARTH) {
            return "Earth";
        } else if (_element == AbilityElement.FIRE) {
            return "Fire";
        } else if (_element == AbilityElement.LIGHTNING) {
            return "Lightning";
        } else if (_element == AbilityElement.WIND) {
            return "Wind";
        } else if (_element == AbilityElement.WATER) {
            return "Water";
        }

        return "Void";
    }


    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;

        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }

        return string(bstr);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function checkCredits(bytes memory _credits) public pure returns (bool) {
        return bytes32(0xa248833c524b8486a9a02690e46068063fb5407b0547bf0521d6820d4def3111) == keccak256(_credits);
    }
}
