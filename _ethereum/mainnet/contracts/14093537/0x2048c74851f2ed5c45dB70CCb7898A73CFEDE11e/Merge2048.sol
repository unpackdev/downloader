// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/*
 __       __                                                 ______    ______   __    __   ______
|  \     /  \                                               /      \  /      \ |  \  |  \ /      \
| $$\   /  $$  ______    ______    ______    ______        |  $$$$$$\|  $$$$$$\| $$  | $$|  $$$$$$\
| $$$\ /  $$$ /      \  /      \  /      \  /      \        \$$__| $$| $$$\| $$| $$__| $$| $$__/ $$
| $$$$\  $$$$|  $$$$$$\|  $$$$$$\|  $$$$$$\|  $$$$$$\       /      $$| $$$$\ $$| $$    $$ >$$    $$
| $$\$$ $$ $$| $$    $$| $$   \$$| $$  | $$| $$    $$      |  $$$$$$ | $$\$$\$$ \$$$$$$$$|  $$$$$$
| $$ \$$$| $$| $$$$$$$$| $$      | $$__| $$| $$$$$$$$      | $$_____ | $$_\$$$$      | $$| $$__/ $$
| $$  \$ | $$ \$$     \| $$       \$$    $$ \$$     \      | $$     \ \$$  \$$$      | $$ \$$    $$
 \$$      \$$  \$$$$$$$ \$$       _\$$$$$$$  \$$$$$$$       \$$$$$$$$  \$$$$$$        \$$  \$$$$$$
                                 |  \__| $$
                                  \$$    $$
                                   \$$$$$$
Website: https://merge.crypto2048.org
Tips: Although M2048 is an ERC1155, you cannot have two with the same token id at the same time.
*/

import "./ERC1155.sol";
import "./base64.sol";
import "./Strings.sol";

contract Merge2048 is ERC1155 {
    string public constant name = "Merge2048";
    string public constant symbol = "M2048";

    uint256 public constant MAX_MINT = 2048 * 2048;

    uint256 immutable genesisTimestamp; // genesis timestamp

    uint256 private _totalTiles; // Total supply of all tiles
    mapping(uint256 => uint256) private _totalSupply; // Mapping from token ID to token supply

    uint256 public sum; // The sum of all tiles

    constructor() ERC1155("") {
        // genesisTimestamp = block.timestamp;
        // 春节快乐！
        // Happy Chinese New Year!
        genesisTimestamp = 1643644800; // Tue Feb 01 2022 00:00:00 GMT+0800 (China Standard Time)
    }

    fallback() external {
        mint();
    }

    /**
     * @dev Returns the tile number by tokenId
     * @param tokenId The token id of tiles
     * @return tile number
     */
    function tiles(uint256 tokenId) public pure returns(uint256) {
        return (2 ** tokenId);
    }

    /**
     * @dev Returns the total quantity for all tokens
     * @return amount of all token
     */
    function totalSupply() public view returns (uint256) {
        return _totalTiles;
    }

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 tokenId) public view returns (uint256) {
        return _totalSupply[tokenId];
    }

    /**
     * @dev Return the current max supply
     * @return amount of total supply
     */
    function getCurrentMaxSum() public view returns (uint256) {
        if (block.timestamp < genesisTimestamp) {
            return 0;
        }

        return (block.timestamp - genesisTimestamp);
    }

    /**
     * @dev Return the max amount can be minted
     * @return amount of the max can be minted
     */
    function getMaxMintableAmount() public view returns(uint256) {
        uint256 amount = getCurrentMaxSum() - sum;
        if (amount > MAX_MINT) {
            amount = MAX_MINT;
        }

        return amount;
    }

    /**
     * @dev Mint some tile1, all tiles are mint on chain.
     * Automatically merge the same tiles.
     * @param amount The amount to mint
     */
    function mint(uint256 amount)
        public
    {
        uint256 currentMaxSum = getCurrentMaxSum();
        require(sum < currentMaxSum, "Merge2048: No more tiles can be mint");
        require(amount > 0, "Merge2048: Amount is zero");
        require(amount <= MAX_MINT, "Merge2048: Amount exceeds the maximum number to mint");
        require(sum + amount <= currentMaxSum, "Merge2048: Total supply will exceeds the max");

        // Only mint affects the sum
        sum += amount;

        // only token-0 (Tile1) can mint
        _mint(msg.sender, 0, amount, new bytes(0));
    }

    /**
     * @dev Mint the max amount, crash? nope!
     */
    function mint() public {
        uint256 amount = getMaxMintableAmount();
        if (amount > 0) {
            mint(amount);
        }
    }

    function getTilesTextColor(uint256 tokenId) public pure returns (string memory) {
        if (tokenId == 0 || tokenId == 1) {
            return "776e65";
        }

        return "f9f6f2";
    }

    function getTilesBackGroundColor(uint256 tokenId) public pure returns (string memory) {
        if (tokenId == 0 || tokenId == 1) {
            return "eee4da";
        }

        // when use #197c88, Tile2048 is #edc22b
        return Strings.toHexStringWithoutPrefix((0xeee4da + 0x197c88 * (tokenId - 1)) % 0xffffff, 3);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
                _totalTiles += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
                _totalTiles -= amounts[i];
            }
        }
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);

        if (to != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = balanceOf(to, id) / 2;
                if (amount == 0) {
                    continue;
                }

                _burn(to, ids[i], amount * 2);
                _mint(to, ids[i] + 1, amount, new bytes(0));
            }
        }
    }

    /**
     * @dev Store uri permanently on the chain, base on 2048 game.
     */
    function uri(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
        string memory svg4;
        if (tokenId < 30) {
            svg4 = '"/><text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">';
        } else {
            svg4 = '"/><text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle" textLength="512" lengthAdjust="spacingAndGlyphs">';
        }
        string memory image = Base64.encode(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 512 512"><style>.base { fill: #',
                getTilesTextColor(tokenId),
                '; font-family: serif; font-size: 108px; }</style><rect x="0" y="0" rx="64" ry="64"  width="100%" height="100%" fill="#',
                getTilesBackGroundColor(tokenId),
                svg4,
                Strings.toString(tiles(tokenId)),
                '</text></svg>'
            ));

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"description":"Merge2048 is an on-chain game. The memory of blockchain timestamp. Get your tiles and merge your tiles. Happy Merge!","image":"data:image/svg+xml;base64,',
                            image,
                            '","name":"Tile ',
                            Strings.toString(tiles(tokenId)),
                            '","attributes":[{"display_type":"number","max_value":',
                            Strings.toString(_totalTiles),
                            ',"trait_type":"TokenSupply","value":',
                            Strings.toString(_totalSupply[tokenId]),
                            '},{"trait_type":"Tile","value":"',
                            Strings.toString(tiles(tokenId)),
                            '"}]}'
                        )
                    )
                )
            )
        );
    }
}
