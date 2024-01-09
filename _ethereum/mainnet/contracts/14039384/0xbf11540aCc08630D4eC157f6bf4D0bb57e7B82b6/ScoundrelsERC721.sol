// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./ERC165.sol";

contract ScoundrelsERC721 is ERC165, ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 constant DEV_FEE = 10;
    uint256 public constant DISCOUNT_SPOTS = 100;
    uint256 public constant DISCOUNTED_PRE_SALE_ETH = 0.06 ether;
    uint256 public constant PRE_SALE_ETH = 0.07 ether;
    uint256 public constant MIN_ETH = 0.09 ether;
    uint256 public constant MAX_CAP = 10000;
    uint256 public constant MAX_WHITELIST_PER_REGISTREE = 3;
    uint256 public constant TOTAL_PRE_SALE_MINT_PASS = 1000;
    uint256 public constant TOTAL_WHITELIST_SPOTS = 900;
    uint256 public constant PRE_SALE_WINDOW = 24 hours;
    uint256 public immutable MINT_START; // 1645315200 ~ 2022/02/20 @ 00:00:00 GMT
    string constant BASE_EXTENSION = '.json';

    address devAddress;

    string private baseUri;
    uint256 public tokenIds;

    mapping(address => uint256) presaleRegistration;
    uint256 public presaleRegistrees;

    bool whitelistOpen;

    constructor(
        string memory __baseUri,
        address _devAddress,
        uint256 _mint_start
    ) ERC721('Scoundrels', 'SCDL') {
        baseUri = __baseUri;
        devAddress = _devAddress;
        MINT_START = _mint_start;
    }

    event RegisterPresale(address _registree);

    function bulkRegisterPresale(uint256 _times) external payable {
        for (uint256 i = 0; i < _times; i++) {
            registerPreSale();
        }
    }

    function registerPreSale() public payable {
        require(block.timestamp < MINT_START, 'ScoundrelsERC721::registerPreSale Registrations time over');
        if (!whitelistOpen) {
            require(
                presaleRegistrees < TOTAL_PRE_SALE_MINT_PASS,
                'ScoundrelsERC721::registerPreSale Pre-sale registration spots full'
            );
        } else {
            require(
                presaleRegistrees < TOTAL_PRE_SALE_MINT_PASS + TOTAL_WHITELIST_SPOTS,
                'ScoundrelsERC721::registerPreSale Whitelist registration spots full'
            );
            require(
                presaleRegistration[msg.sender] < MAX_WHITELIST_PER_REGISTREE,
                'ScoundrelsERC721::registerPreSale Registree maxed out registrations'
            );
        }
        uint256 min_eth = MIN_ETH;
        if (presaleRegistrees < TOTAL_PRE_SALE_MINT_PASS) {
            min_eth = presaleRegistrees >= DISCOUNT_SPOTS ? PRE_SALE_ETH : DISCOUNTED_PRE_SALE_ETH;
        }
        _requireAndWithdraw(min_eth, 'ScoundrelsERC721::registerPreSale Not enough ETH');

        presaleRegistrees++;
        presaleRegistration[msg.sender]++;

        if (!whitelistOpen) {
            emit RegisterPresale(msg.sender);
        }
    }

    function bulkMint(uint256 _times) external payable returns (uint256[] memory ids) {
        ids = new uint256[](_times);

        for (uint256 i = 0; i < _times; i++) {
            ids[i] = mint();
        }
        return ids;
    }

    function mint() public payable returns (uint256) {
        require(tokenIds < MAX_CAP, 'ScoundrelsERC721::mint All NFTs have been minted');
        if (presaleRegistration[msg.sender] > 0) {
            require(block.timestamp >= MINT_START - PRE_SALE_WINDOW, 'ScoundrelsERC721::mint Minting is not open yet');
            presaleRegistration[msg.sender]--;
        } else {
            require(block.timestamp >= MINT_START, 'ScoundrelsERC721::mint Minting is not open yet');
            _requireAndWithdraw(MIN_ETH, 'ScoundrelsERC721::mint Not enough ETH');
        }

        _safeMint(msg.sender, tokenIds);
        tokenIds++;

        return tokenIds;
    }

    function openWhitelist() external onlyOwner {
        require(!whitelistOpen, 'ScoundrelsERC721::openWhitelist Already open');
        require(
            presaleRegistrees >= TOTAL_PRE_SALE_MINT_PASS,
            "ScoundrelsERC721::openWhitelist Pre-sale didn't sold out"
        );
        whitelistOpen = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), BASE_EXTENSION)) : '';
    }

    function cost() external view returns (uint256) {
        uint256 min_eth = MIN_ETH;
        if (block.timestamp < MINT_START && presaleRegistrees < TOTAL_PRE_SALE_MINT_PASS) {
            min_eth = presaleRegistrees >= DISCOUNT_SPOTS ? PRE_SALE_ETH : DISCOUNTED_PRE_SALE_ETH;
        }
        return min_eth;
    }

    function _updateDevAddr(address _newAdrr) external {
        require(msg.sender == devAddress, 'ScoundrelsERC721::_updateDevAddr Unauthorized');
        require(_newAdrr != address(0x0));
        devAddress = _newAdrr;
    }

    function _requireAndWithdraw(uint256 _min_amount, string memory _err) internal {
        require(msg.value >= _min_amount, _err);

        uint256 toDev = (_min_amount * DEV_FEE) / 100;
        uint256 toOwner = _min_amount - toDev;
        payable(devAddress).transfer(toDev);
        payable(owner()).transfer(toOwner);
    }

    function _withdraw(uint256 amount) external {
        require(msg.sender == devAddress || msg.sender == owner(), 'ScoundrelsERC721::_withdraw Unauthorized');

        uint256 balance = address(this).balance;
        uint256 toDev = (balance * DEV_FEE) / 100;
        uint256 toOwner = balance - toDev;
        payable(devAddress).transfer(toDev);
        payable(owner()).transfer(toOwner);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string calldata _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }
}
