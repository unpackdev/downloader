// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./Ownable.sol";
import "./PaymentSplitter.sol";
import "./ERC721Enumerable.sol";
import "./ERC165Storage.sol";
import "./Strings.sol";

import "./IAbilities.sol";
import "./ILuchadores.sol";
import "./ILuchaNames.sol";

import "./Base64.sol";
import "./StringUtils.sol";


contract Lootchadores is ERC721Enumerable, Ownable, ERC165Storage, PaymentSplitter {
    using strings for *;
    using Strings for string;
    using Strings for uint256;

    struct AbilityStats {
        uint8 stars;
        uint8 charisma;
        uint8 constitution;
        uint8 dexterity;
        uint8 intelligence;
        uint8 strength;
        uint8 wisdom;
        uint256 tokenId;
    }

    mapping(uint256 => AbilityStats) internal luchaAbilites;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0xc155531d;

    uint256 public constant MINT_PRICE = 0.03 ether;
    uint256 public constant ROYALTY_AMOUNT = 9;

    address public LUCHADORES_ADDRESS;
    address public LUCHADORES_NAME_ADDRESS;
    address public ABILITY_SCORES_ADDRESS;

    constructor(
        address luchaAddress,
        address luchaNamesAddress,
        address abilityAddress,
        address[] memory _payees,
        uint256[] memory _shares
    )
    payable
    PaymentSplitter(_payees, _shares)
    ERC721("Lootchadores", "LOOTCHA") {
        _registerInterface(_INTERFACE_ID_ERC2981);
        LUCHADORES_ADDRESS = luchaAddress;
        LUCHADORES_NAME_ADDRESS = luchaNamesAddress;
        ABILITY_SCORES_ADDRESS = abilityAddress;
    }

    function mintWithLucha(uint256 luchadoreId,uint256 abilityScoreId) public payable {
        require(msg.value == MINT_PRICE, "L:mWL:402");
        require(msg.sender == ILuchadores(LUCHADORES_ADDRESS).ownerOf(luchadoreId), "L:mWL:403");
        require(msg.sender == IAbilities(ABILITY_SCORES_ADDRESS).ownerOf(abilityScoreId), "L:mWL:403");

        persistStats(luchadoreId, abilityScoreId);

        _mint(msg.sender, luchadoreId);
    }

    function persistStats(uint256 tokenId, uint256 abilityId) internal {
        uint8 charisma = extractValue(IAbilities(ABILITY_SCORES_ADDRESS).getCharisma(abilityId));
        uint8 constitution = extractValue(IAbilities(ABILITY_SCORES_ADDRESS).getConstitution(abilityId));
        uint8 dexterity = extractValue(IAbilities(ABILITY_SCORES_ADDRESS).getDexterity(abilityId));
        uint8 intelligence = extractValue(IAbilities(ABILITY_SCORES_ADDRESS).getIntelligence(abilityId));
        uint8 strength = extractValue(IAbilities(ABILITY_SCORES_ADDRESS).getStrength(abilityId));
        uint8 wisdom = extractValue(IAbilities(ABILITY_SCORES_ADDRESS).getWisdom(abilityId));

        uint8 stars = uint8((charisma + constitution + dexterity + intelligence + strength + wisdom) / 20);

        luchaAbilites[tokenId] = AbilityStats({
            charisma: charisma,
            constitution: constitution,
            dexterity: dexterity,
            intelligence: intelligence,
            strength: strength,
            wisdom: wisdom,
            tokenId: abilityId,
            stars: stars
        });
    }

    /* solhint-disable quotes */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "L:tU:404");
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                getName(tokenId),
                                '", "image": "',
                                svgBase64Data(tokenId),
                                '", ',
                                tokenProperties(tokenId),
                                '"}}'
                            )
                        )
                    )
                )
            );
    }

    function tokenProperties(uint256 tokenId) internal view returns (bytes memory) {
        AbilityStats memory stats = luchaAbilites[tokenId];

        return abi.encodePacked(
            '"properties": { "Charisma": "',
            uint256(stats.charisma).toString(),
            '", "Constitution": "',
            uint256(stats.constitution).toString(),
            '", "Dexterity": "',
            uint256(stats.dexterity).toString(),
            '", "Intelligence": "',
            uint256(stats.intelligence).toString(),
            '", "Strength": "',
            uint256(stats.strength).toString(),
            '", "Wisdom": "',
            uint256(stats.wisdom).toString()
        );
    }

    function svgBase64Data(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "L:sb64D:404");

        return string(
            abi.encodePacked(
                'data:image/svg+xml;base64,',
                Base64.encode(svgRaw(tokenId))
            )
        );
    }

    function svgRaw(uint256 tokenId) public view returns (bytes memory) {
        require(_exists(tokenId), "L:sR:404");
        return
            abi.encodePacked(
                '<svg viewBox="0 0 640 890" xmlns="http://www.w3.org/2000/svg"><rect x="16" y="16" width="608" height="858" style="fill: rgb(253, 227, 36); stroke-width: 4px; stroke:#FD6F21;"/>',
                '<rect x="16" y="16" width="607" height="604" style="fill: rgb(216, 216, 216); stroke-width: 4px; stroke:#FD6F21"/><svg x="30" y="30" width="580" height="580">',
                ILuchadores(LUCHADORES_ADDRESS).imageData(tokenId),
                '</svg><line style="stroke-width: 2px; stroke:#FD6F21;" x1="48" x2="248" y1="650" y2="650"/>',
                renderStars(tokenId),
                '<line style="stroke-width: 2px; stroke:#FD6F21;" x1="392" x2="592" y1="650" y2="650"/>',
                renderName(getName(tokenId)),
                renderAttributes(tokenId),
                "</svg>"
            );
    }

    function getName(uint256 tokenId) internal view returns (string memory) {
        string memory name = ILuchaNames(LUCHADORES_NAME_ADDRESS).getName(LUCHADORES_ADDRESS, tokenId);
        return bytes(name).length == 0 ? string(abi.encodePacked("Lootchadore #", tokenId.toString())) : name;
    }

    function renderStar(bool filled, uint256 x) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<path transform="translate(',
                x.toString(),
                ',636) scale(0.5)" fill="',
                filled ? "#009ADE" : "none",
                '" stroke-width="2" stroke="#009ADE" d="m25,1 6,17h18l-14,11 5,17-15-10-15,10 5-17-14-11h18z"/>'
            );
    }

    function renderStars(uint256 tokenId) internal view returns (bytes memory) {
        AbilityStats memory stats = luchaAbilites[tokenId];
        uint8 starRating = stats.stars;

        return
            abi.encodePacked(
                renderStar(starRating >= 1, 248),
                renderStar(starRating >= 2, 278),
                renderStar(starRating >= 3, 308),
                renderStar(starRating >= 4, 338),
                renderStar(starRating >= 5, 368)
            );
    }

    function renderName(string memory name) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<text text-anchor="middle" width="600" style="fill: #FD6F21; font-family: \'Georgia\'; font-size: 36px; font-weight: 600;" x="320" y="720">',
                name,
                "</text>"
            );
    }

    function renderAttributes(uint256 _tokenId) internal view returns (bytes memory) {
        AbilityStats memory stats = luchaAbilites[_tokenId];
        return
            abi.encodePacked(
                renderAttribute(stats.charisma, " CHA", 128, 780),
                renderAttribute(stats.constitution, " CON", 320, 780),
                renderAttribute(stats.dexterity, " DEX", 512, 780),
                renderAttribute(stats.intelligence, " INT", 128, 830),
                renderAttribute(stats.strength, " STR", 320, 830),
                renderAttribute(stats.wisdom, " WIS", 512, 830)
            );
    }

    function renderAttribute(
        uint256 value,
        string memory label,
        uint256 x,
        uint256 y
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<text text-anchor="middle" x="',
                x.toString(),
                '" y="',
                y.toString(),
                '" style="fill: #009ADE; font-size: 24px; font-weight: 600; font-family: \'Helvetica\'">',
                uint256(value).toString(),
                label,
                "</text>"
            );
    }

    function extractValue(string memory ability) internal pure returns (uint8) {
        strings.slice memory value = ability.toSlice();
        value.split(" ".toSlice());
        return uint8(safeParseInt(value.toString(), 0));
    }

    function safeParseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) break;
                    else _b--;
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                require(!decimals, 'More than one decimal encountered in string!');
                decimals = true;
            } else {
                revert("Non-numeral character encountered in string!");
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }


    function royaltyInfo(
        uint256 tokenId,
        uint256 value,
        bytes calldata _data
    ) external view returns (address _receiver, uint256 royaltyAmount) {
        royaltyAmount = (value * ROYALTY_AMOUNT) / 100;

        return (owner(), royaltyAmount);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165Storage, ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) || ERC165Storage.supportsInterface(interfaceId);
    }
}
