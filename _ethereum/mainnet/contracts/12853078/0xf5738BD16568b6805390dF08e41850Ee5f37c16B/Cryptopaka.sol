// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.4;

import "./ERC721Enumerable.sol";
import "./Context.sol";
import "./Ownable.sol";

contract Cryptopaka is Context, ERC721Enumerable, Ownable {
    string private _baseTokenURI = "https://api.cryptopaka.com/token/";
    bool private _paused = true;
    uint256 private _lastTimestamp = 0;
    uint256 private _lastPrice = 10000 gwei;

    uint256 public constant basePrice = 10000 gwei;
    bytes32 public searchSeed = 0x0; // prevent "premining"

    // used to verify the parser
    bytes32 public constant jsSHA256 =
        0x1288f5184d996524ea5f6e6d51fc46548caced33616e91dcfe205189d1a03e2e;

    constructor() ERC721("Cryptopaka", "CPK") {}

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused(), "not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     */
    function pause() public whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     */
    function unpause() public whenPaused onlyOwner {
        searchSeed = blockhash(block.number - 1);
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri; // we will change to a decentralized solution
    }

    /**
     * @dev Returns the current minting cost of a single paka
     */
    function price() public view returns (uint256) {
        uint256 discount = (block.timestamp - _lastTimestamp) * 1 gwei; // 1 gwei/s
        if (_lastPrice > 100000000000000000) {
            discount *= 100; // if price > 0.1 eth then increase the discount
        }
        uint256 ret = (_lastPrice * 6) / 5; // 1.2
        if (discount >= ret - basePrice) {
            return basePrice; // minimum price
        }
        ret -= discount;
        if (ret > 690000000000000000) {
            return 690000000000000000; // clamped at 0.69 eth
        }
        return ret;
    }

    function mint(bytes32 seed) public payable {
        uint256 p = price();
        require(totalSupply() <= 142053); // 142053 + 16 genesis pakas = 142069
        require(p <= msg.value, "ether below range"); // you could pay a bit more
        require(p * 2 > msg.value, "ether above range"); // but not too much

        _lastTimestamp = block.timestamp;
        _lastPrice = p;
        bytes32 h = keccak256(abi.encodePacked(seed, searchSeed));
        require(h[29] | h[30] | h[31] == 0x0, "invalid seed");
        uint256 tokenId = uint256(h >> 216);

        // genesis paka are not mintable
        require(!isGenesis(tokenId));

        _mint(_msgSender(), tokenId);
    }

    function mintGenesis(uint256 tokenId) public onlyOwner {
        require(isGenesis(tokenId)); // owner can only mint genesis pakas
        _mint(_msgSender(), tokenId);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function isGenesis(uint256 tokenId) public pure returns (bool) {
        return
            tokenId == 1099511562240 ||
            tokenId == 1099511566336 ||
            tokenId == 1099511570432 ||
            tokenId == 1099511574528 ||
            tokenId == 1099511578624 ||
            tokenId == 1099511582720 ||
            tokenId == 1099511586816 ||
            tokenId == 1099511590912 ||
            tokenId == 1099511595008 ||
            tokenId == 1099511599104 ||
            tokenId == 1099511603200 ||
            tokenId == 1099511607296 ||
            tokenId == 1099511611392 ||
            tokenId == 1099511615488 ||
            tokenId == 1099511619584 ||
            tokenId == 1099511623680;
    }
}
