// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.22;

import "./ERC721.sol";
import "./Ownable.sol";
import "./StarSky.sol";

/*
 *                               A celestial Advent Calendar,
 *                   to accompany its holder throughout the advent days.
 *
 *              Every day until Dec. 24th, a new star will shine in the night
 *                      sky, sometimes together with colorful nebulae.
 *
 *                 Each NFT will generate its own unique vibrant firmament.
 *                Only at Christmas Eve the cosmic artwork will be complete.
 *
 *                 Next year? Restart it, and the magic will happen again.
 *
 *                                                                           %@@-
 *                                                                          :%@@=
 *
 *
 *    @@
 *      @%
 *      @@
 *                                     .       . ...
 *                          . .          ... .              .@:.
 *                        . .   .
 *                    .     . . .      ..       .
 *      @                 .   . . . @ .    . .     .     .
 *               .    .  .  . . ...*@-:.:... ....     .    .. .
 *                  .-@- . .......     . .... ..  ..  . . .
 *               .           ............: .... .. ..
 *                  .. ..    .......... ..........   ..         ...    .               @@@
 *                 . . .. @@ ...:......    ..........    .              .
 *             .    .  .     ........::-%@:..........:.... ..    .
 *                ...............::.::.    .:..:.. .....  ..  ..
 *             .  ..  ........:.:.:::..::..:::..::.:..........  ...  ..
 *               . .  ....:..:..::.:.::..:.....::...:........ ...  ...   ..
 *                . .........:.:.::.:.::::...:...::::::.......... .   .    ..    .
 *                . ...........::::....::::---::::::.::::.:........:.... ....
 *            .   . ......:.:::.:::::::::.:...:.::::::::...::.:...... ...   ...  .      .
 *            .    ............::.:..:::::::::::::-.::::::.:.::.:::..:....  .  ..       .
 *             .    .............::::::::::    .::::::::.:.:.::::::.::. :-.... .  .
 *        .    .  ..  ......:::::..:.:::::: @@ -:::::::::-:::::::-::::::... ...:.  .
 *            . . ..  ..........:..:::.::::    ::::::::-:   :::-:::..:. :::.. ...
 *                  .  ....    .:.:..::::.::.::::::-::--- @ ---:---:.    ..:..:: .: .   .. .
 *           .    .  . .... @@ ..::::::::::-::::::-:--::-   --:-::---*@@=::::.::  :...
 *                .  . ....    ....:.::::::.:::::::--:----::::------:.-.::::-.:.:  ...   ..
 *            ..     . .  .........:.:...::::::--:--:----:   :-----:::...:.:-.::........ . .
 *                . .  .   ..........:.::::::::::-:----:--:@%------:-:::----:::::::.. ..      .
 *                    . ... ........:.:..:.:::::-:-:------:@=:-----=----:-:--:::::..-..:....
 *                      .  ..   ...........:::::::-:--:------:  :----:-----:-:-:::::..:.. :
 *                           .  .. . ..:.....::.:::-::    ----@@:--:-----:-:--::::::.::.: . ..
 *                        .   ..  ............::::-:-- @@ ---:=+.--:---:-:--.   -:::.:.:.. ..   ..
 *                          .       .  ..........::.::    ---::.:-------:---.=@ ::::::.:.....  .
 *              :            ..   .   .. ....:::::::::::-:::-:-::---:---:--::   ::.:-::: ..... .
 *                    .      .  .  ..    ...........::.:::-:------::::::   -:--::::::.:. ... . .
 *                                 . .... . ... ::-:::::.::::::::.::-----@:--:::.:::-..:...  . .
 *                                 .       . .::  ....:.::.:::-:-:-::..: ..::...::.-..      .
 *                            .     . .  .       .   :. .:.:....:.::--::-::..:----.: .:-+- ...
 *                                           .   .:..:-:...::::::::.::....::::..:.::..-#+::
 *                                             ..... .   ..  ....:.:.. .:.::: ::... ..
 *                                    @@   . .         .. . :.....  .::.:..:.... . .. ...  .
 *                                                 . .. .  ..  ...::::.        . .:...
 *                                                               .    .........
 *
 */

contract AdventStars is StarSky, ERC721, Ownable {
    uint256 public immutable MINT_END;
    uint256 public immutable PRICE;
    uint256 public constant MAX_SUPPLY = 432;

    uint256 currentToken = 1;

    mapping(uint256 => uint256) _seeds;
    mapping(uint256 => uint256) _tokenToYear;
    mapping(address => uint256) _discordUsersDiscount;

    constructor(
        uint256 price,
        uint256 mintEnd
    ) ERC721("Advent Stars", "STARS") {
        PRICE = price;
        MINT_END = mintEnd;
    }

    /* Admin */

    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "fail");
    }

    function setDiscounts(
        address[] memory wallets,
        uint256[] memory discounts
    ) public onlyOwner {
        uint256 length = wallets.length;
        for (uint256 i = 0; i < length; ) {
            _discordUsersDiscount[wallets[i]] = discounts[i];
            unchecked {
                i++;
            }
        }
    }

    /* Public Write */

    function mint(uint256 amount) public payable {
        require(msg.value >= PRICE * amount, "not enough ether");
        require(block.timestamp < MINT_END, "mint ended");
        for (uint256 i = 0; i < amount; ) {
            _mint();
            unchecked {
                i++;
            }
        }
    }

    function restart(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "not the owner");
        (uint256 month, uint256 day, uint256 year) = toDate(block.timestamp);
        require(2023 != year, "not this year");
        require(_tokenToYear[tokenId] != year, "already restarted");
        require((month == 11 && day > 23) || month == 12, "too early");

        _tokenToYear[tokenId] = year;
        _seeds[tokenId] = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), tokenId))
        );
    }

    function mintDiscount(uint256 amount) public payable {
        require(_discordUsersDiscount[msg.sender] > 0, "you have no discount");
        require(
            msg.value >=
                ((PRICE * amount) * 100) / _discordUsersDiscount[msg.sender],
            "not enough ether"
        );
        delete _discordUsersDiscount[msg.sender];
        require(block.timestamp < MINT_END, "mint ended");
        for (uint256 i = 0; i < amount; ) {
            _mint();
            unchecked {
                i++;
            }
        }
    }

    /* Public Read */

    function minted() public view returns (uint256) {
        return currentToken - 1;
    }

    function tokenAtIndex(uint256 index) public view returns (uint256) {
        for (uint256 i = 1; i < currentToken; ) {
            if (msg.sender == ownerOf(i)) {
                if (index == 0) {
                    return i;
                } else {
                    index--;
                }
            }

            unchecked {
                i = i + 1;
            }
        }

        revert("you don't that many tokens");
    }

    function adventDay() public view returns (uint256) {
        (uint256 month, uint256 day, ) = toDate(block.timestamp);

        if (month == 12 && day < 25) {
            return day;
        } else if (month == 12) {
            return 24;
        } else {
            return 0;
        }
    }

    function render(uint256 tokenId) public view returns (string memory) {
        (uint256 currentAdventDay, uint256 year) = _validateRequest(tokenId);
        return _render(_seeds[tokenId], currentAdventDay, year);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        (uint256 currentAdventDay, uint256 year) = _validateRequest(tokenId);
        return _json(tokenId, _seeds[tokenId], currentAdventDay, year);
    }

    /* Possibly useful public utilities */

    function toDate(
        uint256 s
    ) public pure returns (uint256 month, uint256 day, uint256 year) {
        uint256 z = s / 86400 + 719468;
        uint256 era = (z >= 0 ? z : z - 146096) / 146097;
        uint256 doe = z - era * 146097;
        uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        year = yoe + era * 400;
        uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        uint256 mp = (5 * doy + 2) / 153;
        day = doy - (153 * mp + 2) / 5 + 1;
        month = uint256(int256(mp) + (mp < 10 ? int256(3) : -9));
        year += (month <= 2 ? 1 : 0);
    }

    /* Internal */

    function _validateRequest(
        uint256 tokenId
    ) internal view returns (uint256 currentAdventDay, uint256 tokenYear) {
        require(_exists(tokenId), "not a token");
        tokenYear = _tokenToYear[tokenId];
        if (tokenYear == 0) {
            tokenYear = 2023;
        }

        (uint256 month, uint256 day, uint256 currentYear) = toDate(
            block.timestamp
        );

        if (tokenYear == currentYear && month == 12 && day <= 24) {
            currentAdventDay = day;
        } else if (tokenYear == currentYear && month < 12) {
            currentAdventDay = 0;
        } else {
            currentAdventDay = 24;
        }
    }

    function _mint() internal {
        require(currentToken <= MAX_SUPPLY, "beyond supply");
        _seeds[currentToken] = uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), currentToken)
            )
        );
        _mint(msg.sender, currentToken++);
    }
}
