// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./base64.sol";
import "./ICrypto2048Token.sol";

contract Crypto2048NFT is ERC1155, Ownable {
    using Counters for Counters.Counter;

    string public constant name = "Crypto2048";
    string public constant symbol = "2048";

    uint256 public constant MAX_SUPPLY = 8888; // 2 * 2 * [2,2048] => 8188, but I like 8888, how about 10240?
    uint256 public constant MAX_MINT = 2048;
    uint256 public constant PRICE = 0.02 ether;

    uint256 constant private Tile0 = 1; // 2 ^ 0 = 1, deprecated math.pow
    uint256 constant public Tile1 = Tile0 * 2; // 2
    uint256 constant public Tile2 = Tile1 * 2; // 4
    uint256 constant public Tile3 = Tile2 * 2; // 8
    uint256 constant public Tile4 = Tile3 * 2; // 16
    uint256 constant public Tile5 = Tile4 * 2; // 32
    uint256 constant public Tile6 = Tile5 * 2; // 64
    uint256 constant public Tile7 = Tile6 * 2; // 128
    uint256 constant public Tile8 = Tile7 * 2; // 256
    uint256 constant public Tile9 = Tile8 * 2; // 512
    uint256 constant public Tile10 = Tile9 * 2; // 1024
    uint256 constant public Tile11 = Tile10 * 2; // 2048

    mapping(uint256 => uint256) public tiles; // Mapping from token ID to tile number
    mapping(uint256 => string) public tilesTextColor; // Mapping from token ID to tile text color
    mapping(uint256 => string) public tilesBackGroundColor; // Mapping from token ID to tile background color

    uint256 private _totalSupply; // Total supply of all tiles
    mapping(uint256 => uint256) private _tokenSupply; // Mapping from token ID to token supply

    Counters.Counter private _claimCounter; // the total 2048 tiles burn
    uint256 public nextClaimBlock; // the block after which can burn 2048 NFT to claim 2048 Token

    address constant public token2048 = 0x2596B971eE0dE4532566C59FA394C0D29f21D224;

    event Found2048(address owner, uint256 amount); // 2048 found!
    event Claimed(address owner); // 2048 NFT burned and 2048 token minted

    constructor() ERC1155("") {
        tiles[1] = Tile1;
        tiles[2] = Tile2;
        tiles[3] = Tile3;
        tiles[4] = Tile4;
        tiles[5] = Tile5;
        tiles[6] = Tile6;
        tiles[7] = Tile7;
        tiles[8] = Tile8;
        tiles[9] = Tile9;
        tiles[10] = Tile10;
        tiles[11] = Tile11;

        // all colors are from game 2048
        tilesTextColor[1] = "776e65";
        tilesTextColor[2] = "776e65";
        tilesTextColor[3] = "f9f6f2";
        tilesTextColor[4] = "f9f6f2";
        tilesTextColor[5] = "f9f6f2";
        tilesTextColor[6] = "f9f6f2";
        tilesTextColor[7] = "f9f6f2";
        tilesTextColor[8] = "f9f6f2";
        tilesTextColor[9] = "f9f6f2";
        tilesTextColor[10] = "f9f6f2";
        tilesTextColor[11] = "f9f6f2";

        tilesBackGroundColor[1] = "eee4da";
        tilesBackGroundColor[2] = "ede0c8";
        tilesBackGroundColor[3] = "f2b179";
        tilesBackGroundColor[4] = "f59563";
        tilesBackGroundColor[5] = "f67c5f";
        tilesBackGroundColor[6] = "f65e3b";
        tilesBackGroundColor[7] = "edcf72";
        tilesBackGroundColor[8] = "edcc61";
        tilesBackGroundColor[9] = "edc850";
        tilesBackGroundColor[10] = "edc53f";
        tilesBackGroundColor[11] = "edc22e";

        nextClaimBlock = block.number;
    }

    /**
     * @dev Returns random number base on seed and MAX_SUPPLY
     * @param seed The number of seed for random
     * @return amount less than MAX_SUPPLY
     */
    function getRandom(uint256 seed) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
                seed,
                block.number,
                block.timestamp,
                msg.sender,
                block.difficulty,
                gasleft(), // oh, no
                address(this).balance,
                tx.gasprice))) % MAX_SUPPLY;
    }

    /*
     * @dev Returns random token id between 1 and 11, [1,11]
     * @param seed The number of seed fro random
     * @return tokenId between 1 and 11
     * 2       4       8       16     32     64     128   256   512   1024  2048
     * 4096 +  2048 +  1024 +  512 +  256 +  128 +  64 +  32 +  16 +  8 +   4 = 8188
     * 8188 <= 4092 <= 2044 <= 1020 <= 508 <= 252 <= 124 <= 60 <= 28 <= 12 <= 4 <= 0
     */
    function getRandomTokenId(uint256 seed) public view returns (uint256) {
        uint256 rand = getRandom(seed);
        // [0-MAX]
        if (rand < 4) {
            return 11;
        } else if (rand < 12) {
            return 10;
        } else if (rand < 28) {
            return 9;
        } else if (rand < 60) {
            return 8;
        } else if (rand < 124) {
            return 7;
        } else if (rand < 252) {
            return 6;
        } else if (rand < 508) {
            return 5;
        } else if (rand < 1020) {
            return 4;
        } else if (rand < 2044) {
            return 3;
        } else if (rand < 4092) {
            return 2;
        }

        return 1;
    }

    /**
     * @dev Returns the total quantity for a token id
     * @param id ID of the token to query
     * @return amount of token in existence
     */
    function tokenSupply(uint256 id) public view returns (uint256) {
        return _tokenSupply[id];
    }

    /**
     * @dev Returns the total quantity for all tokens
     * @return amount of all token
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Oh, yes, this is the 2048! Merge the tiles to next.
     * The 2048 can't be merged.
     * @param tokenId The tokenId of the tile to be merged, [1,11)
     * @param amount The amount used to merge
     */
    function merge(uint256 tokenId, uint256 amount) public {
        // only [1,11)
        require(tokenId < 11, "Crypto2048: TokenId must less than 11");

        uint256 nextTokenId = tokenId + 1;
        amount = amount / 2;
        require(amount > 0, "Crypto2048: No need to merge");

        _burn(msg.sender, tokenId, amount * 2);
        _tokenSupply[tokenId] -= amount * 2;
        _totalSupply -= amount * 2;

        _mint(msg.sender, nextTokenId, amount, new bytes(0));
        _tokenSupply[nextTokenId] += amount;
        _totalSupply += amount;

        if (nextTokenId == 2048) {
            emit Found2048(msg.sender, amount);
        }
    }

    /**
     * @dev Try to merge again and again based on the given amount
     * @param tokenId The from tokenId of the tile to be merged, [1,11)
     * @param amount The amount used to merge
     */
    function deepMerge(uint256 tokenId, uint256 amount) public {
        for (; tokenId < 11; tokenId++) {
            uint256 nextTokenId = tokenId + 1;

            amount /= 2;
            if (amount == 0) {
                // ok, it's the best
                break;
            }

            _burn(msg.sender, tokenId, amount * 2);
            _tokenSupply[tokenId] -= amount * 2;
            _totalSupply -= amount * 2;

            _mint(msg.sender, nextTokenId, amount, new bytes(0));
            _tokenSupply[nextTokenId] += amount;
            _totalSupply += amount;

            if (nextTokenId == 2048) {
                emit Found2048(msg.sender, amount);
            }
        }
    }

    /**
     * @dev 2048! Try to merge all tiles you owned
     */
    function fullMerge() public {
        for (uint256 tokenId = 1; tokenId < 11; tokenId++) {
            uint256 nextTokenId = tokenId + 1;

            uint256 amount = balanceOf(msg.sender, tokenId);

            amount /= 2;
            if (amount == 0) {
                // ignore this and try the next
                continue;
            }

            _burn(msg.sender, tokenId, amount * 2);
            _tokenSupply[tokenId] -= amount * 2;
            _totalSupply -= amount * 2;

            _mint(msg.sender, nextTokenId, amount, new bytes(0));
            _tokenSupply[nextTokenId] += amount;
            _totalSupply += amount;

            if (nextTokenId == 2048) {
                emit Found2048(msg.sender, amount);
            }
        }
    }

    /**
     * @dev Try to burn the 2048 NFT and mint 2048 token.
     * Only can be burn one by one.
     * Every 8 blocks are allowed to burn once, but it can be accumulated.
     * Top 2048 burn have additional token rewards, but the rewards are diminishing.
     * Finally, 2048 tokens for every burn.
     */
    function claim() public {
        require(nextClaimBlock < block.number, "Crypto2048: Rate limit");
        nextClaimBlock += 8;

        _burn(msg.sender, 11, 1);
        _tokenSupply[11] -= 1;
        _totalSupply -= 1;

        // reward
        if (_claimCounter.current() < 2048) {
            ICrypto2048Token(token2048).mint(msg.sender, (2048 - _claimCounter.current()) * 2048 * 1e18);
        } else {
            ICrypto2048Token(token2048).mint(msg.sender, 2048 * 1e18);
        }
        _claimCounter.increment();

        emit Claimed(msg.sender);
    }

    /**
     * @dev Return the cliamed amount
     * @return amount of cliamed
     */
    function claimCounter() public view returns (uint256) {
        return _claimCounter.current();
    }

    /**
     * @dev Mint some tiles, all tiles are randomly mint on chain.
     * Only token id between 1 and 11 will be mint, 
     * corresponding to tiles from 2 to 2048.
     * @param amount The amount to mint
     */
    function mint(uint256 amount)
    public
    payable
    {
        require(totalSupply() < MAX_SUPPLY, "Crypto2048: No more tiles can be mint");
        require(amount > 0, "Crypto2048: Amount is zero");
        require(amount <= MAX_MINT, "Crypto2048: Amount exceeds the maximum number to mint");
        require(totalSupply() + amount <= MAX_SUPPLY, "Crypto2048: Total supply will exceeds the max");
        require(PRICE * amount == msg.value, "Crypto2048: Price mismatch");

        uint256 found2048Amount = 0;
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = getRandomTokenId(i);

            // one by one            
            _mint(msg.sender, tokenId, 1, new bytes(0));
            _tokenSupply[tokenId] += 1;
            _totalSupply += 1;

            if (tiles[tokenId] == 2048) {
                found2048Amount += 1;
            }
        }

        if (found2048Amount > 0) {
            emit Found2048(msg.sender, found2048Amount);
        }
    }

    /**
     * @dev Withdraw all balance.
     * For Dev
     * For DAO
     * For Airdrop
     * For Liquidity pool
     * For 2048
     */
    function withdraw() public {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev Store uri permanently on the chain, all image base on 2048
     */
    function uri(uint256 tokenId)
    public
    view
    override
    returns (string memory)
    {
        // [1,11]
        require(1 <= tokenId && tokenId <= 11, "Crypto2048: URI query for nonexistent token");

        string memory image = Base64.encode(abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 512 512"><style>.base { fill: #',
                tilesTextColor[tokenId],
                '; font-family: serif; font-size: 128px; }</style><rect x="0" y="0" rx="64" ry="64"  width="100%" height="100%" fill="#',
                tilesBackGroundColor[tokenId],
                '"/><text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">',
                Strings.toString(tiles[tokenId]),
                '</text></svg>'
            ));

        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"description":"Crypto2048 is the on-chain version of 2048. Get your tiles and merge your tiles. Happy Merge!","image":"data:image/svg+xml;base64,',
                            image,
                            '","name":"Tile ',
                            Strings.toString(tiles[tokenId]),
                            '","attributes":[{"display_type":"number","max_value":',
                            Strings.toString(_totalSupply),
                            ',"trait_type":"TokenSupply","value":',
                            Strings.toString(_tokenSupply[tokenId]),
                            '},{"trait_type":"Tile","value":"',
                            Strings.toString(tiles[tokenId]),
                            '"}]}'
                        )
                    )
                )
            )
        );
    }
}