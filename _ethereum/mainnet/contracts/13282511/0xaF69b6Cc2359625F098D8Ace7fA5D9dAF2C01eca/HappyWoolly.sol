// ....................................................................................................
// ....................................................................................................
// ....................................................................................................
// ....................................................................................................
// .................................................---................................................
// .............................................:ossoooso+-......:/++++/:-.............................
// ...........................................+s+-.`   `.-+o-.-//:--..-:+ss:...........................
// ................................-/osooo/-:s/`           .+/.`         `:yo..........................
// .....................------....+s/-`   `+o.               :`            `o+.........................
// ..................:osoo++ooo+:o:       ./                  `              y.-:://o+/-...............
// ................-yo-        .+/        -                                  :       .:ss:.............
// ................y.            `-                                          `          -ys............
// .............../:                                                    ````..--:/:`      oh...........
// ............-::/-                                          ```   ```.          .+o:     ys..........
// .........-os+:.`.`                               `````   .`          ..`         `+y.   .m-.........
// ........+h:`                                 `---.`    .:              .-          :d:   d:.........
// .......-m-                                 `+/`        /                -/         `od`  h-.........
// ......./m                                 :s.         :-                `+:        `/m. `y..........
// .......-m`                               :y`          o.                `-s       `.yh  :/..........
// ........oo                              `d:           //                .-h    ``./yy.  .`:/:.......
// ........-++`                            :m.           `h-              `.sy+///+oys/:`     `/s-.....
// ....../+-. `                            -m:`           +h/`          `..om+o+/:-.:` `:/.`    /h-....
// .....so`                                 oh:.`      `.++-hho-.``````.-/yNMMMMmo` `/.  `:o-    sy....
// ....sy                                    /hy+:---:/oo+dMMMNNdysooosyyoNMMMMMMMs   /:  `:s    -m....
// ....m:                                    .../+yoo/:`.NMMMMMMMs.---.`  mMMMMMMMh    /s++/`    .m-...
// ....m:                                   :.    /     /MMMMMMMMd        -mMMMMMN-     y        :m....
// ....+h`                                  //    +:    `dMMMMMMM/      ``  :oso/`      h`       y+....
// ...../y/`                                 -o++o+s`    `+hmNmy-   `/:/h:             :s       oo.....
// .......+/:.`                                ``` `s.      ```      -:d/             :y`   ``-/:......
// ......-s                                         `o/                :-           -s+`    `:o-.......
// ......+s                                          `:o/`                       ./o+.        :y.......
// ....../h`                                           `:++:-`              `.:+oo:`          .m.......
// .......ys.                                             `-/+o++//::::///+oo+/-`             +d.......
// ......../so+//:                                             `.---:::---.`                `/h:.......
// ...........--+`                                                                        `:ss-........
// .............y`                                                                   `.-:/o/-..........
// .............s/                                             `                     :.  --............
// .............-h/                               `            .`                   .s   +.............
// ..............-yy-         .                    -           :.                  +y`  .o.............
// ................:syo/-.-:/+                     .-          +`               .+y/    y-.............
// ...................-+y/:. `+`               ``   +`         s .:--`     `-/oysh`    o/..............
// .....................o:    `s/.           ./-    .+        `h+/..-/++oooo+/-..o/   +o...............
// ......................o/    ooos+:----:/+o/-::-.` o-       /s-.................s/:o/................
// .......................+o. `h..-:/+oo+/:-.....-/+osy`     `y....................---.................
// ........................:++o:....................../o     ++........................................
// ....................................................o+`  /s.........................................
// .....................................................+o/++..........................................
// .......................................................-............................................
// ....................................................................................................
// ....................................................................................................
// ....................................................................................................
// ....................................................................................................
//
// Happy Woolly Farm
//
// 14777 Wolly NFTs
// https://happywoollyfarm.com/
//
// Twitter: https://twitter.com/HappyWoollyFarm
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./IERC20.sol";

import "./IChangeName.sol";

contract HappyWoollyFarm is ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    struct Whitelist {
        uint256 MAX_WOOLLY;
        uint256 totalSupply;
    }

    // Private variables
    address private vault; 
    address private shepherd;
    mapping (string => bool) private _nameReserved;
    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;
    // Name change token address
    address private tokenAddress;

    // Public variables
    uint256 public constant MAX_WOOLLY_SUPPLY = 14777;
    uint256 public reserved = 4777;
    uint256 public price = 0.0777 ether;
    uint256 public duration = 210 days;
    uint256 public nameChangePrice = 77 * (10 ** 18);
    uint256 public REVEAL_TIMESTAMP = block.timestamp + 7 days;
    uint256 public coolDownDuration = 7 minutes;
    uint256 public mintLimit = 7;
    uint256 public woollyStartBlock = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    bool public whaleProtection;
    bool public paused = true;
    // This is the provenance record of all Happy Woolly artwork in existence
    string public HAPPY_WOOLLY_PROVENANCE = '';
    uint256 public offsetIndexBlock;
    uint256 public offsetIndex;

    mapping(address => Whitelist) public whitelist;
    
    mapping(address => uint256) public coolDown;
    
    // Mapping if tokens for certain NFT ID has already been claimed
    mapping (address => mapping(uint256 => bool)) private _claimedNfts;
    
    // Mapping if certain name string has already been reserved
    mapping(uint256 => string) public tag;
    
    mapping(uint256 => uint256) public nameChangeDuration;
    
    // Addresses that were claimed tokens
    EnumerableSet.AddressSet private _claimedOwners;

    // Events
    event NameChange (uint256 indexed maskIndex, string newName);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor () ERC721("HappyWoollyFarm", "WOOLLY") {}

    /// @dev check Prevent gas war.
    modifier isWhaleProtection(uint256 num) {
        require((whaleProtection && (block.timestamp.sub(coolDown[msg.sender]) >= coolDownDuration)) || whaleProtection == false, "cooldown");
        require((whaleProtection && balanceOf(msg.sender).add(num) <= mintLimit) || whaleProtection == false, "exceed mint limit");
        _;
    }

    function setOffsetIndexBlock() internal {
        /**
        * Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        */
        if (offsetIndexBlock == 0 && (totalSupply() >= MAX_WOOLLY_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            offsetIndexBlock = block.number;
        }
    }

    /**
    * @dev Mints Happy Woolly
    */
    function mintNFT(uint256 numberOfNfts) public isWhaleProtection(numberOfNfts) payable {
        require(!paused, "sale paused");
        require(block.number >= woollyStartBlock, "not started");
        require(numberOfNfts > 0 && numberOfNfts <= 7, "max 7");
        require(totalSupply().add(numberOfNfts) <= MAX_WOOLLY_SUPPLY - reserved, "over the supply");
        require(msg.value >= price.mul(numberOfNfts), "eth not sufficient");

        uint256 mintIndex = totalSupply();
        for (uint256 i = 0; i < numberOfNfts; i++) {
            _safeMint(msg.sender, mintIndex + i);
        }
        setOffsetIndexBlock();
        coolDown[msg.sender] = block.timestamp;
    }

    /**
     * @dev Returns if tokens for certain NFT ID has already been claimed
     */
    function isTokensForNftClaimed(address nftAddress, uint256 nftId) public view returns (bool) {
        return _claimedNfts[nftAddress][nftId];
    }

    /**
     * @dev Returns if `owner` address has already claimed tokens
     */
    function isOwnerClaimedTokens(address owner) public view returns (bool) {
        return _claimedOwners.contains(owner);
    }

    /**
     * @dev Returns number of NFTs in `owner`'s account.
     */
    function nftBalanceOf(address owner, address nftAddress) public view returns (uint256) {
        return IERC721Enumerable(nftAddress).balanceOf(owner);
    }

    /**
     * @dev The same as the external `canClaim()` but also sets `_claimedNfts`=true for all NFTs
     * and add an `owner` address to `_claimedOwners`
     * This function can be called only by `claim()`
     * 
     * Duplicate code is required to save gas; otherwise, we need to iterate NFTs twice:
     * The first time is to call the external `canClaim()`
     * (i.e. check if an `owner` address can claim tokens)
     * The second is to update `_claimedNfts` and `_claimedOwners`
     */
    function _canClaim(address owner, address nftAddress) internal returns (bool) {

        // one address can claim only once
        if (isOwnerClaimedTokens(owner) == true) {
            return false;
        }

        bool _canOwnerClaim = false;

        uint256 nftsNumber = nftBalanceOf(owner, nftAddress);
        for (uint i = 0; i < nftsNumber; i++) {
            uint256 currentNftId = IERC721Enumerable(nftAddress).tokenOfOwnerByIndex(owner, i);

            if (isTokensForNftClaimed(nftAddress, currentNftId) == false) {
                _canOwnerClaim = true;
                _claimedNfts[nftAddress][currentNftId] = true;
            }
        }

        if (_canOwnerClaim == true) {
            _claimedOwners.add(owner);
        }
        return _canOwnerClaim;
    }

    function communityMint(address _whitelist) public {
        require(!paused, "paused");
        require(nftBalanceOf(msg.sender, _whitelist) > 0, "not qualified");
        bool canSenderClaim = _canClaim(msg.sender, _whitelist);
        require(canSenderClaim == true, "Sender cannot claim");
        Whitelist storage info = whitelist[_whitelist];
        require(info.MAX_WOOLLY > 0, "not whitelisted");
        require(reserved > 0 && info.totalSupply < info.MAX_WOOLLY, "fully adopted");
        
        reserved -= 1;
        info.totalSupply += 1;
        _safeMint(msg.sender, totalSupply());
        setOffsetIndexBlock();
    }

    /**
     * @dev Finalize starting index
     */
    function setOffsetIndex() public {
        require(offsetIndex == 0, "starting index has already been set");
        require(offsetIndexBlock != 0, "starting index block must be set");
        
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(offsetIndexBlock) > 255) {
            offsetIndex = uint256(blockhash(block.number - 1)).mod(MAX_WOOLLY_SUPPLY);
        }else {
            offsetIndex = uint256(blockhash(offsetIndexBlock)).mod(MAX_WOOLLY_SUPPLY);
        }
        // Prevent default sequence
        if (offsetIndex == 0) {
            offsetIndex = 1;
        }
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if ((totalSupply() >= MAX_WOOLLY_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            uint256 offsetId = tokenId.add(MAX_WOOLLY_SUPPLY.sub(offsetIndex)).mod(MAX_WOOLLY_SUPPLY);
            return string(abi.encodePacked(baseURI(), offsetId.toString()));
        } else {
            return string(abi.encodePacked(baseURI(), "abducted"));
        }
    }

    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Changes the name for Woolly tokenId
     */
    function changeName(uint256 tokenId, string memory newName, string memory _tag, uint256 _price) public {
        address owner = ownerOf(tokenId);

        require(tokenAddress != address(0), "token not set");
        require(shepherd != address(0) && IERC721(shepherd).balanceOf(owner) > 0, "shepherd not set or not detected");
        require((block.timestamp - nameChangeDuration[tokenId] > duration) || _price >= nameChangePrice, "condition not matched");
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(validateName(newName) == true, "not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "new name is same as the current one");
        require(isNameReserved(newName) == false, "name already reserved");

        if(_price >= nameChangePrice) {
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), nameChangePrice);
            IERC20(tokenAddress).transfer(vault, nameChangePrice);
        }

        if(bytes(_tag).length > 0) {
            tag[tokenId] = _tag;
        }

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        nameChangeDuration[tokenId] = block.timestamp;        
        emit NameChange(tokenId, newName);
    }

    /*
     * Only the owner can do these things
     */

    function setCoolDownDuration(uint256 _duration) public onlyOwner {
        coolDownDuration = _duration;
    }

    function setMintLimit(uint256 _limit) public onlyOwner {
        mintLimit = _limit;
    }

    function setProvenanceHash(string memory _hash) public onlyOwner {
        HAPPY_WOOLLY_PROVENANCE = _hash;
    }

    function setStartBlock(uint256 _startBlock) public onlyOwner {
        woollyStartBlock = _startBlock;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function setNameChangePrice (uint256 _nameChangePrice) public onlyOwner {
        nameChangePrice = _nameChangePrice;
    }

    function setWhitelist(address[] calldata _whitelist, uint256[] calldata _maxWoolly) public onlyOwner {
        uint256 len = _whitelist.length;
        require(_maxWoolly.length == len, "bad length");
        for (uint256 idx = 0; idx < len; idx++) {
            whitelist[_whitelist[idx]] = Whitelist({
                MAX_WOOLLY: uint256(_maxWoolly[idx]),
                totalSupply: uint256(0)
            });
        }
    }

    function setWhaleProtection() public onlyOwner {
        whaleProtection = !whaleProtection;
    }

    function setPaused()public onlyOwner {
        paused = !paused;
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
    */
    function withdraw(uint256 _amount, address _to) public onlyOwner {
        require(address(_to) != address(0), "do not burn");
        require(payable(_to).send(_amount));
    }

    function setWaitingTime(uint256 _duration) public onlyOwner {
        duration = _duration;
    }

    function setShepherd(address _shepherd) public onlyOwner {
        shepherd = _shepherd;
    }

    function setToken(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function setVault(address _vault) public onlyOwner {
        vault = _vault;
    }

    function forwardERC20s(IERC20 _token, address _to, uint256 _amount) public onlyOwner {
        require(address(_to) != address(0));
        _token.transfer(_to, _amount);
    }

    function emergencySetOffsetIndexBlock() public onlyOwner {
        require(offsetIndex == 0, "starting index is already set");
        offsetIndexBlock = block.number;
    }

    function mintReserve(address _to, uint256 num) public onlyOwner {
        require(!paused, "paused");
        require(num <= reserved, "fully adopted");
        require(num > 0 && num <= 7, "bad input");

        uint256 mintIndex = totalSupply();
        for(uint256 i; i < num; i++){
            _safeMint(_to, mintIndex + i);
        }
        reserved -= num;
        setOffsetIndexBlock();
    }

    /**
     * @dev Converts the string to lowercase
     */
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }
}