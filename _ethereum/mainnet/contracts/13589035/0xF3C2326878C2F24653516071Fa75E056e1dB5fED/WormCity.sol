// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Presale.sol";

/*
 *
 *                   .....     :=*#%@@%%*+-.    -=++++++===-.
 *         ..    -#@@@@@@@@%+*@@@@@@%%%@@@@@%=*@@@@@@@@@@@@@@@%+.   :=++==-:
 *  :=*#%@@@@@%=-@@@#**++*@@@@@%=:      .-+@@@@@@-:::::::--=*%@@@#+@@@@@@@@@@@#%%#+=-.
 *.%@@@@%#*+*@@@@@@%      .@@#:             =@@@+             :#@@@@@=:.:-=+%@@@@@@@@@@=
 *+@@@.      .@@##%%      .@+                .@@=               *@@@=       :+    .:+@@@-
 *:@@@-       -    -      -%      .*%@%=      -@=       .=      :@@%                 %@@*
 * #@@%                   =+      @@@@@@=      @=       .-      #@@.                 #@@%
 * .@@@+                  **      +@@@@%.     .@-             -%@@+                  +@@@
 *  +@@@.                 %@:       ::.       #@-            =#%@%                   -@@@.
 *   %@@#                 @@@-               #@@-               .:                   :@@@-
 *   :@@@-        -      .@@@@#-          .+@@@@-              .+                     @@@=
 *    +@@@.       %-    .=@@@@@@@#*====+*@@@@@@@+...  .=%+:   -@+       =+. .=        @@@*
 *     %@@%-::=+#%@@@@@@@@@@+.=#@@@@@@@@@@%@@@@@@@@@@@@@@@@@%@@@@@@%#***@@@@@@=.      @@@*
 *      *@@@@@@@@@#******+=.  .%@@@%*+*%@-  *#::#@@++%%%%@@@@%*++*#%@@@@@#**@@@@@@@@@@@@@.
 *       .-=+=-:              %@@#.     +=:.=    :#  +   %@@*                -+*##%%%%#=
 *                           .@@@-   #**%-  #-  :+%. .   @@@+
 *                            %@@#   .  =+  @#    ++    -@@@:
 *                            .%@@@*===#@%**@@#==*@%+=+#@@@*
 *                              =#@@@@@@@@@@@@@@@@@@@@@@@#-
 *                                 .:-:. ...  .::. .:-:.
*/
contract WormCity is ERC721, ERC721Enumerable, Presale, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _wormId;

    event Minted(address account, uint256 amount);
    event MayorMinted(address account);
    event MintedOnPresale(address account, uint256 amount);
    event MintedReserved(address account, uint256 amount);

    uint256 public wormPrice = 80000000000000000; // 0.08 ETH
    uint256 public constant maxWormsForPurchase = 30;
    uint256 public constant maxWormsForWhitelistedPurchase = 10;
    uint256 public constant maxWormsForWhitelistedAccount = 10;
    uint256 public MAX_WORMS = 11110;
    uint256 public RESERVED_WORMS = 0;
    uint256 public RESERVED_MINTED = 0;
    uint256 public MAYOR_ID = 11111; // Mayor number is constant and predefined
    string private _baseURIPrefix;

    constructor() ERC721("Worm.City", "WORM") {}

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }

    function getBaseURI() public view virtual returns (string memory) {
        return _baseURI();
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseURIPrefix = baseURI;
    }

    /*
     * Mints mayor and sends it to specified address
     */
    function mintMayor(address account) public onlyOwner {
        _safeMint(account, MAYOR_ID);

        emit MayorMinted(account);
    }

    function mayorOwner() public whenMayorMinted view virtual returns (address) {
        return ownerOf(MAYOR_ID);
    }

    function mayorMinted() public view virtual returns (bool) {
        return _exists(MAYOR_ID);
    }

    modifier whenMayorMinted() {
        require(mayorMinted(), "Mayor is not minted");
        _;
    }

    function startPresale() public onlyOwner {
        _startPresale();
    }

    function stopPresale() public onlyOwner {
        _stopPresale();
    }

    function startSale() public onlyOwner {
        _startSale();
    }

    function stopSale() public onlyOwner {
        _stopSale();
    }

    function fromPresaleToSale() public onlyOwner {
        stopPresale();
        startSale();
    }

    function whitelist(address account) public onlyOwner {
        _whitelist(account);
    }

    function removeFromWhitelist(address account) public onlyOwner {
        _removeFromWhitelist(account);
    }

    function safeMint(address to, uint256 amount) public onlyOwner {
        uint256 i;
        for (i = 0; i < amount; i++) {
            _safeMint(to, _wormId.current());
            _wormId.increment();
        }

        emit Minted(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*
     * Reserves specified amount which could be minted only by owner
     * These worms are needed for giveaways, contests and other
     */
    function reserve(uint256 amount) public onlyOwner {
        require(amount < MAX_WORMS, "Cannot reserve more than total supply");

        RESERVED_WORMS = amount;
    }

    function getReservedAmount() public view returns (uint256) {
        return RESERVED_WORMS;
    }

    function getMintedReservedAmount() public view returns (uint256) {
        return RESERVED_MINTED;
    }

    /*
     * Mints reserved worms for giveaways, contests and other
     */
    function mintReserved(uint256 amount, address to) public onlyOwner {
        require(
            RESERVED_MINTED.add(amount) <= RESERVED_WORMS,
            "Minting would exceed max supply of reserved worms"
        );

        RESERVED_MINTED += amount;

        _mintMultiple(amount, to);

        emit MintedReserved(to, amount);
    }

    /*
     * Mints worm in presale mode
     */
    function presale(uint256 amount) public payable whenPresaleStarted whenWhitelisted {
        require(
            getMintedAmount().add(amount) <= MAX_WORMS - RESERVED_WORMS,
            "Purchase would exceed max supply of Worms"
        );

        require(
            amount <= maxWormsForWhitelistedPurchase,
            "Only 10 tokens could be minted at a time"
        );

        require(
            balanceOf(_msgSender()).add(amount) <= maxWormsForWhitelistedAccount,
            "Only 10 tokens could be minted for whitelisted account"
        );

        _mintPayedMultiple(amount);

        emit MintedOnPresale(_msgSender(), amount);
    }

    /*
     * Function that returns minted worms without mayor
     */
    function getMintedAmount() public view returns (uint256) {
        uint256 total = totalSupply();

        if (mayorMinted()) {
            total = total.sub(1);
        }

        return total;
    }

    /*
     * Mints worm
     */
    function mint(uint256 amount) public payable whenSaleStarted {
        require(
            amount <= maxWormsForPurchase,
            "Can mint only 30 worms at a time"
        );

        require(
            getMintedAmount().add(amount) <= MAX_WORMS - RESERVED_WORMS,
            "Purchase would exceed max supply of Worms"
        );

        _mintPayedMultiple(amount);

        emit Minted(_msgSender(), amount);
    }

    function _mintPayedMultiple(uint256 amount) internal {
        require(
            wormPrice.mul(amount) <= msg.value,
            "Ether value sent is not correct"
        );

        _mintMultiple(amount, _msgSender());
    }

    function _mintMultiple(uint256 amount, address to) internal {
        uint256 mintIndex = totalSupply();
        uint256 i;
        for (i = 0; i < amount; i++) {
            if (mintIndex + i <= MAX_WORMS) {
                _safeMint(to, _wormId.current());

                _wormId.increment();
            }
        }
    }

    /*
     * Function which withdraws specified amount of funds for certain needs (development, hosting, etc.)
     */
    function withdraw(uint256 amount) public onlyOwner {
        payable(owner()).transfer(amount);
    }

    /*
     * Function witch withdraws all funds
     */
    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;

        payable(owner()).transfer(balance);
    }
}
