// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//@author Snakes In Your Wallet
//@title Snakes In Your Wallet
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.         &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.         &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     ,,,,,     ,,,,,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     ,,,,,     ,,,,,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                    &@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*****%%%%%@@@@@*,,,,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*****%%%%%@@@@@*,,,,&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*****%&&&&@@@@@@@@@@*,,,,&@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*****%&&&&@@@@@@@@@@*,,,,&@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     ,****%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     ,****%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.    ,****%&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.    ,****%&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@     &@@@@@@@@@@@@@@.    ,****%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@     &@@@@@@@@@@@@@@.    ,****%%%%%@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@          &@@@@@@@@@@@@@@.    %&&&&@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@          &@@@@@@@@@@@@@@.    %&&&&@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@&&&&&                    ,****%&&&&@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@&&&&&                    ,****%&&&&@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@&&&&&@@@@@@@@@@@@@@@&&&&&&%%%%&&&&&&%%%%&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@&&&&&@@@@@@@@@@@@@@@&&&&&&%%%%&&&&&&%%%%&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@&&&&&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//  _____             _               _____
// /  ___|           | |             |_   _|
// \ `--. _ __   __ _| | _____  ___    | | _ __
//  `--. \ '_ \ / _` | |/ / _ \/ __|   | || '_ \
// /\__/ / | | | (_| |   <  __/\__ \  _| || | | |
// \____/|_| |_|\__,_|_|\_\___||___/  \___/_| |_|
// __   __                 _    _       _ _      _
// \ \ / /                | |  | |     | | |    | |
//  \ V /___  _   _ _ __  | |  | | __ _| | | ___| |_
//   \ // _ \| | | | '__| | |/\| |/ _` | | |/ _ \ __|
//   | | (_) | |_| | |    \  /\  / (_| | | |  __/ |_
//   \_/\___/ \__,_|_|     \/  \/ \__,_|_|_|\___|\__|

pragma solidity ^0.8.4;

import "./Strings.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./ERC721A.sol";

contract SnakesInYourWallet is ERC2981, ERC721A, Ownable {
    using Address for address payable;
    using ECDSA for bytes32;
    using Strings for uint256;

    uint32 public immutable _freeMintAmount = 1;
    uint256 public immutable _freeMintTime = 1 days;
    uint256 public immutable _mintPrice = 0.007 ether;
    uint32 public immutable _txsssssLimit = 10;
    uint32 public immutable _maxSsssssssupply = 10000;
    uint32 public immutable _maxGiftSupply = 500;
    uint32 public immutable _walletLimit = 10;

    bool public _sssssssssstarted;
    string public _metadataURI =
        "https://bafybeibrkczzyuqvckshkjxq32def7v6ub6wxeaeqzgghf74hkd6ay3hka.ipfs.nftstorage.link/";

    mapping(address => uint256) public lassssstFreeMint;
    mapping(address => bool) public isssssssFreeMintToday;
    mapping(address => uint256) public nbMint;
    mapping(address => uint256) public nbMintGift;

    constructor() ERC721A("Snakes In Your Wallet", "SIYW") {
        _setDefaultRoyalty(owner(), 700);
    }

    function currentTime() internal view returns (uint256) {
        return block.timestamp;
    }

    function snakeInYourMint(address _account, uint32 _amount)
        external
        payable
    {
        uint256 price = _mintPrice;
        uint256 requiredValue = price * _amount;
        uint64 userMinted = _getAux(msg.sender);

        require(price != 0, "Price is 0");
        require(_sssssssssstarted, "Mint is not activated");
        require(
            _amount + _totalMinted() <= _maxSsssssssupply,
            "Max supply exceeded"
        );
        require(msg.value >= price * _amount, "Not enought funds");
        require(_amount <= _txsssssLimit, "10 max per mint");
        require(
            nbMint[msg.sender] + _amount <= _walletLimit,
            "10 max per wallet"
        );

        nbMint[msg.sender] += _amount;

        if (userMinted == 0) requiredValue -= price;
        userMinted += _amount;
        _setAux(msg.sender, userMinted);
        _safeMint(_account, _amount);
    }

    function snakeInYourFreeMint() external {
        uint256 price = 0;
        uint32 _amount = _freeMintAmount;
        uint256 requiredValue = price * _amount;
        uint64 userMinted = _getAux(msg.sender);

        require(_sssssssssstarted, "Mint is not activated");

        if (currentTime() >= (lassssstFreeMint[msg.sender] + _freeMintTime)) {
            lassssstFreeMint[msg.sender] = currentTime();
            isssssssFreeMintToday[msg.sender] = false;
        }

        require(
            _amount + _totalMinted() <= _maxSsssssssupply,
            "Max supply exceeded"
        );
        require(_amount <= _txsssssLimit, "10 max per mint");
        require(!isssssssFreeMintToday[msg.sender], "Already Free mint today");
        require(
            nbMint[msg.sender] + _amount <= _walletLimit,
            "10 max per wallet"
        );

        lassssstFreeMint[msg.sender] = currentTime();
        isssssssFreeMintToday[msg.sender] = true;
        nbMint[msg.sender] += _amount;

        if (userMinted == 0) requiredValue -= price;
        userMinted += _amount;
        _setAux(msg.sender, userMinted);
        _safeMint(msg.sender, _amount);
    }

    function snakeInYourGiftMint(address to, uint32 amount) external onlyOwner {
        require(
            _totalMinted() + amount <= _maxSsssssssupply,
            "Reached max Supply"
        );

        require(
            amount + nbMintGift[msg.sender] <= _maxGiftSupply,
            "Reached max Supply Free Gifts"
        );

        nbMintGift[msg.sender] += amount;
        _safeMint(to, amount);
    }

    struct State {
        uint256 mintPrice;
        uint32 txLimit;
        uint32 walletLimit;
        uint32 maxSupply;
        uint32 totalMinted;
        uint32 userMinted;
        bool started;
    }

    function _state(address minter) external view returns (State memory) {
        return
            State({
                mintPrice: _mintPrice,
                txLimit: _txsssssLimit,
                walletLimit: _walletLimit,
                maxSupply: _maxSsssssssupply,
                totalMinted: uint32(ERC721A._totalMinted()),
                userMinted: uint32(_getAux(minter)),
                started: _sssssssssstarted
            });
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _metadataURI;
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, ERC721A)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setFeeNumerator(uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(owner(), feeNumerator);
    }

    function setSssssssstarted(bool started) external onlyOwner {
        _sssssssssstarted = started;
    }

    function setMetadataURI(string memory uri) external onlyOwner {
        _metadataURI = uri;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }
}
