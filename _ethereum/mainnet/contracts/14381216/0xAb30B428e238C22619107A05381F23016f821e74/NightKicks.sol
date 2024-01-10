//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Strings.sol";
import "./ERC721Enumerable.sol";

contract NightKicks is ERC721Enumerable, Ownable, ReentrancyGuard {
    IERC721Enumerable MembershipToken;
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public maxSupply;
    bool public sale;
    bool public publicSale;
    string public _tokenURI;
    uint256 membershipPrice = 0.06 ether;
    uint256 publicPrice = 0.08 ether;
    address[] artists = [
        0x759C4eBeBE5071DB56C78B6c7bae53c15CB2F6D8,
        0x3146a2997E71155c144aE25FCE2d866092Bc91F3,
        0xCDD99ee657A33b1DA6802F4117D7e5cB2FFA5d79,
        0x91F95B32D4D07C80ea796A184745f63d92F743ef,
        0x32BE83A8EAb1eFe1bFCE275e4FDef4a2a350eb96,
        0x2205D45163F81139fc54a7694B7D809b294b38fF
    ];
    mapping(uint256 => bool) public usedMembershipToken;

    event NftBought(address indexed, uint256 memberShipTokenId);

    constructor(address _tokenAddress) ERC721("NightKicks", "NK") {
        MembershipToken = IERC721Enumerable(_tokenAddress);
        maxSupply = 5555;
        _tokenURI = "https://ipfs.io/ipfs/QmXpXqbiEX52H4vmbxGNA9o71MHpFbHP4JvQobG7KwEUpt/";
        sale = false;
        publicSale = false;
    }

    function buyWithMembershipToken(uint256 _count, uint256[] memory tokenId)
        public
        payable
        nonReentrant
    {
        require(
            totalSupply() + _count <= maxSupply,
            "ERROR: max limit reached"
        );
        require(
            _count <= 10 && tokenId.length <= 10,
            "ERROR: max 10 mint per transaction"
        );
        require(_count == tokenId.length, "ERROR: wrong token ID or count");
        require(sale, "ERROR: not on sale");
        require(msg.value >= _count * membershipPrice, "ERROR: wrong price");
        require(
            _count <= MembershipToken.balanceOf(msg.sender),
            "ERROR: not enough MembershipToken"
        );
        for (uint256 i = 0; i < tokenId.length; i++) {
            require(
                msg.sender == MembershipToken.ownerOf(tokenId[i]),
                "ERROR: u don't have this token ID"
            );

            require(
                !usedMembershipToken[tokenId[i]],
                "ERROR: this Membership Token is already used"
            );
        }

        for (uint256 j = 0; j < _count; j++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();

            usedMembershipToken[tokenId[j]] = true;

            _safeMint(_msgSender(), newItemId);

            emit NftBought(_msgSender(), tokenId[j]);
        }
    }

    function publicMint(uint256 _count) public payable nonReentrant {
        require(
            totalSupply() + _count <= maxSupply,
            "ERROR: max limit reached"
        );
        require(_count <= 10, "ERROR: max 10 mint per transaction");
        require(publicSale, "ERROR: not on sale");
        require(msg.value >= _count * publicPrice, "ERROR: wrong price");

        for (uint256 j = 0; j < _count; j++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();

            _safeMint(_msgSender(), newItemId);
        }
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory uri = _baseURI();
        return
            bytes(uri).length > 0
                ? string(abi.encodePacked(uri, _tokenId.toString(), ".json"))
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenURI;
    }

    function changeTokenUri(string memory _newUri) public onlyOwner {
        _tokenURI = _newUri;
    }

    function unLockSale() public onlyOwner {
        sale = true;
    }

    function lockSale() public onlyOwner {
        sale = false;
    }

    function unLockPublicSale() public onlyOwner {
        publicSale = true;
    }

    function lockPublicSale() public onlyOwner {
        publicSale = false;
    }

    function changePublicPrice(uint256 _newPrice) public onlyOwner {
        publicPrice = _newPrice;
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        uint256 _eth = address(this).balance;
        uint256 artShare = (_eth * 10) / 100;
        uint256 ownerShare = ((_eth * 41) / 2) / 100;

        // OWNER
        payable(0xdC463F26272D2FE8758D8072BA498B16A30AaaC2).transfer(
            ownerShare
        );
        // ARTIIST
        payable(address(artists[0])).transfer(artShare);
        payable(address(artists[1])).transfer(artShare);
        payable(address(artists[2])).transfer(artShare);
        payable(address(artists[3])).transfer(artShare);
        payable(address(artists[4])).transfer(artShare);
        payable(address(artists[5])).transfer(artShare);
        // DEVELOPMENT
        payable(0x7cF196415CDD1eF08ca2358a8282D33Ba089B9f3).transfer(artShare);
        // Art desingners
        payable(0xef843F881F1693b9881403cAa064C4A907D4cBbf).transfer(
            (_eth * 5) / 100
        );
        payable(0xE6D6540E109F8FA08De6d1440Fe14849b17843b1).transfer(
            (_eth * 1) / 100
        );
        payable(0x9f4b5E8241FEcd432B3081f552737290888022B7).transfer(
            (_eth * 1) / 100
        );
        // DAO
        payable(0xa861a10A90AF9448EeFB5EBdf84Ad51727aaE2a6).transfer(
            ((_eth * 5) / 2) / 100
        );
    }

    function emergencyWithdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}
