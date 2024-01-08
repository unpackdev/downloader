// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./IERC2981.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./VRFConsumerBase.sol";

// Rinkeby
// VRFConsumerBase(
//     0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B,
//     0x01BE23585060835E02B77ef475b0Cc51aA1e0709
// )
// _keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
// _fee = 1e17;

contract HogGang is
    Ownable,
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    VRFConsumerBase,
    IERC2981
{
    using Strings for uint256;

    string private _ipfsURI;
    bytes32 private _requestId;
    address payable private _payout;
    uint256 private constant FEE = 2e18;
    bytes32 private constant KEY_HASH =
        0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;

    string public constant PROVENANCE =
        '2974f603bb107189a312694b92c9880d40cc92f3c8796d67443de17b1cf3068f'; // IPFS Hash as SHA256
    uint256 public constant PRICE = 7e16;
    uint256 public constant MAX_PURCHASE = 10;
    uint256 public revealAmount;
    uint256 public maxSupply;
    uint256 public saleStart;
    uint256 public offset;
    uint256 public limit;

    constructor(
        address payout,
        uint256 _revealAmount,
        uint256 _maxSupply
    )
        ERC721('Hog Gang', 'HOGS')
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        )
    {
        _payout = payable(payout);
        revealAmount = _revealAmount;
        maxSupply = _maxSupply;

        for (uint256 i = _maxSupply - 1; i > _maxSupply - 51; i--) {
            _safeMint(msg.sender, i);
        }
    }

    receive() external payable {}

    function mint(uint256 amount) external payable {
        require(saleStart != 0, 'Sale not yet started');
        require(amount > 0, 'Cannot mint zero');
        require(
            limit == 0 || balanceOf(msg.sender) + amount <= limit,
            'Over limit'
        );

        uint256 supply = totalSupply();
        require(supply < maxSupply, 'Sold out');
        require(
            amount <= MAX_PURCHASE && supply + amount <= maxSupply,
            'Mint amount too high'
        );
        require(msg.value >= PRICE * amount, 'Not enough ETH for minting');

        for (uint256 i = supply; i < supply + amount; i++) {
            _safeMint(msg.sender, i);
        }

        if (
            (supply + amount >= revealAmount ||
                block.timestamp - saleStart >= 2 days) && _requestId == 0
        ) {
            _requestId = requestRandomness(KEY_HASH, FEE);
        }
    }

    function reveal() external {
        require(offset == 0, 'Already revealed');
        require(saleStart != 0, 'Sale not yet started');
        require(_requestId == 0, 'Reveal already requested');
        require(
            totalSupply() >= revealAmount - 10 ||
                block.timestamp - saleStart >= 2 days,
            'Sale not over'
        );

        _requestId = requestRandomness(KEY_HASH, FEE);
    }

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        royaltyAmount = salePrice / 10; // 10%
        receiver = _payout;
    }

    function toggleSale(uint256 limit_) external onlyOwner {
        saleStart = saleStart == 0 ? block.timestamp : 0;
        limit = limit_;
    }

    function setLimit(uint256 limit_) external onlyOwner {
        limit = limit_;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        require(bytes(_ipfsURI).length == 0, 'baseURI already set');
        _ipfsURI = baseURI;
    }

    function withdraw() external {
        require(address(this).balance > 0, 'No balance');
        (bool sent, ) = _payout.call{
            value: address(this).balance,
            gas: 129_100
        }('');

        require(sent, 'Failed to withdraw');
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory baseURI = _baseURI();
        if (offset == 0 || bytes(baseURI).length == 0) {
            return 'ipfs://QmPvBJbxzHmZ8fjrfa1T4MeuTzmf9e7neRDVVxFs6bpcAY';
        } else {
            uint256 lastId = maxSupply - 1;
            uint256 hogId = tokenId == lastId
                ? tokenId
                : (tokenId + offset) % (lastId);
            return string(abi.encodePacked(baseURI, hogId.toString(), '.json'));
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _ipfsURI;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        require(_requestId == requestId, 'Wrong request');
        require(offset == 0, 'Already revealed');

        offset = (randomness % (maxSupply - 1)) + 1;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
