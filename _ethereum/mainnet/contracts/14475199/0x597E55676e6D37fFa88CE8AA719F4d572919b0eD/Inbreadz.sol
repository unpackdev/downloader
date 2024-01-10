// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";
import "./Counters.sol";
import "./AddressManager.sol";

/**
 * @title Inbreadz NFT Smart Contract
 *
 *                   k:.              3+I
 *                  /|}c|            xn~uf
 *                 >b! 'mx          _d  >b,
 *                 :d+  [M"        '}O. ib`
 *                  _nza&$8On[^^_xLk8$MQq~
 *           .     . C$$Y<+|Xpa#omn}+]Z$$1    gUc
 *        ^')Y,!l:'  r$$j   lW$$$Y    r&$j .,[%dL|l
 *     .."C{ xCJput- .X$$Z+}8$X]k$a-IU$$U`txuYxu_U[<^
 *     1hX'"l^%B$&jh,  <CB$$$8x)jM$$&$m- zJOWBW$} `f<^
 * rcdqCi(OB$&$&$B#0f~   Z&aq#MaqQp#1 `J&&$$&$&$&^]>)
 *  ]nc/ IrqoW&&#aqwM&8aU[:I       "|cwo$$%MW88&#b0]
 *          .^""' `_jJdk8av)+;`!_/C^$$Bdu]:`^,,"'
 *                    ;-xcaB0JzLdB$qf~^
 *                      .|M&$WOqwdav)!.
 *            ..   I1trZ&$$MZf!1cOw&$dhL(l     5.
 *        l||jxrzZbB$$$Bqx_^     ^<fL0bo%awYJ/tjf|[;
 *       'MzwW&8B$$&Wqjl             ^>|c^q8$8%%$wYu
 *       ~uYh$$&B$#JYXutxt{|)[+I^'.     p$BBB$8r)+.
 *       ~)1tp&&OUCCCcjvuC0QQJvtt/r/(]t%&$$$f
 *        [#zUvUCXjvzzXYzxtxrcYJCUvrnJ0QQL0qqmO/{>'
 *        ']/?;&CCk}[)/jxnuvvuvccvufrxcYYUJUXxfuccxI
 *             3zz)    '";li<_]1|frnuxjxvnncvnxjnxJ[
 *                               .^"zdLL[uUfuzrxnn)`
 *                                   !<" n$vop`^"'
 *                                        t}_'
 */
contract Inbreadz is ERC721Enumerable, ERC721URIStorage, AddressManager {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event PaymentReleased(address to, uint256 amount);

    // Mapping pack type to owner
    mapping(uint256 => mapping(uint256 => address)) public packs;

    // Prices
    uint256 private _bronze_pack_price;
    uint256 private _silver_pack_price;
    uint256 private _gold_pack_price;
    uint256 private _current_price;

    uint256 public totalPacks;

    uint256 public constant maxTotalSupply = 4126;

    bool private _vipLive;
    bool private _greenLive;
    bool private _whiteLive;
    bool private _packLive;
    bool private _standardLive;

    constructor() ERC721("Inbreadz", "INBZ") {
        _bronze_pack_price = 0.5 ether;
        _silver_pack_price = 1 ether;
        _gold_pack_price = 2 ether;

        totalPacks = 0;

        _vipLive = true;
        _greenLive = false;
        _whiteLive = false;
        _packLive = false;
        _standardLive = false;

        // Set starting price
        _current_price = 0.0799 ether;
    }

    // Public
    function Bake(uint256 multiple) public payable {
        require(_standardLive, "Standard Minting Not Live");
        require(
            msg.value > _current_price,
            "Not enough ETH sent: check price."
        );

        _multiMint(multiple);
    }

    function BakeVip(uint256 multiple) public payable onlyViplisted {
        require(_vipLive, "VIP Mint Not Live");
        require(
            msg.value > _current_price,
            "Not enough ETH sent: check price."
        );

        _multiMint(multiple);
    }

    function BakeGreen(uint256 multiple) public payable onlyGreenlisted {
        require(_greenLive, "Green list Mint Not Live");
        require(
            msg.value > _current_price,
            "Not enough ETH sent: check price."
        );

        _multiMint(multiple);
    }

    function BakePack(uint256 packType) public payable onlyPacklisted {
        require(
            packType < 4,
            "Please choose from 1 - Gold, 2 - Silver or 3 - Bronze"
        );

        uint256 _packPrice = (
            packType == 1
                ? _gold_pack_price
                : (packType == 2 ? _silver_pack_price : _bronze_pack_price)
        );

        require(msg.value > _packPrice, "Not enough ETH sent: check price.");
        // Pack Size Static Set to 4
        for (uint256 pack_items = 0; pack_items < 4; pack_items++) {
            _oven();
        }

        // Link msg.sender to packtype for metadata oracle to allocate rarity
        _mapPack(msg.sender, packType);
    }

    function giveawayBake(uint256 multiple) public onlyOwner {
        // Bake Gas only for giveaways
        for (uint256 baked = 0; baked < multiple; baked++) {
            _oven();
        }
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        // solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    // Administrative
    function setCurrentPrice(uint256 newPrice) public onlyOwner {
        _current_price = newPrice * 1 ether;
    }

    function enableVip() public onlyOwner {
        _vipLive = (_vipLive ? false : true);
    }

    function enableGreen() public onlyOwner {
        _greenLive = (_greenLive ? false : true);
    }

    function enableWhite() public onlyOwner {
        _whiteLive = (_whiteLive ? false : true);
    }

    function enableStandard() public onlyOwner {
        _standardLive = (_standardLive ? false : true);
    }

    function withdraw(address to,uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");

        Address.sendValue(payable(to), amount);
        emit PaymentReleased(to, amount);
    }

    // Private
    function _oven() private returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, _baseURI());

        return newItemId;
    }

    function _multiMint(uint256 multiple) private {
        require(totalSupply() < maxTotalSupply, "Max Total Supply Reached");
        for (uint256 baked = 0; baked < multiple; baked++) {
            _oven();
        }
    }

    function _mapPack(address to, uint256 packType) private {
        packs[totalPacks][packType] = to;
        totalPacks += totalPacks;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
