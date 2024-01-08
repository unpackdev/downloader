// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract BAMC is ERC721("BAMC Capital", "BAMCC"), ERC721Enumerable, Ownable {
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant PRICE = 2 * 10**18; // 2ETH
    string public baseURI =
        "ipfs://bafybeiacfuwzr52qfehohdllvv2t73urq7aqknzow6aovpaw4u3azjwin4/";
    bool public mintStarted = true;
    uint256 public nextTokenId;

    address internal constant _artist =
        0x2Bd07813C54B090fd137Ee9E4eBA6A8307c262e0;

    mapping(address => uint256) public allowListMinted;
    mapping(address => uint256) public allowList;

    event Mint(address minter, uint256 amount);
    event MintStatusChanged(bool isStarted);

    function setMintStart(bool isStarted) external onlyOwner {
        mintStarted = isStarted;
        emit MintStatusChanged(isStarted);
    }

    function addToAllowList(address[] memory toAllowList) external onlyOwner {
        for (uint256 i = 0; i < toAllowList.length; i++) {
            allowList[toAllowList[i]] += 1;
        }
    }

    function allowMintCount(address owner) public view returns (uint256) {
        return allowList[owner];
    }

    function allowListMint(uint256 amount) external {
        require(mintStarted, "BAMC: mint has not started yet");

        uint256 _nextTokenId = nextTokenId;
        require(_nextTokenId + 1 <= MAX_SUPPLY, "BAMC: max supply exceeded");
        require(
            allowListMinted[_msgSender()] + amount <= allowList[_msgSender()],
            "BAMC: you cant mint this many"
        );

        allowListMinted[_msgSender()] += amount;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), _nextTokenId);
            _nextTokenId += 1;
        }

        nextTokenId = _nextTokenId;
        emit Mint(_msgSender(), amount);
    }

    // todo bug
    // https://polygonscan.com/tx/0x3af32f7ad2ee86185d9161d323db3fe3fcf8c69a1484337ba99435cbba8aa642
    // mint 2 只失败
    // 挂单失败～
    function mint(uint256 amount) external payable {
        require(mintStarted, "BAMC: mint has not started yet");

        uint256 _nextTokenId = nextTokenId;
        require(_nextTokenId + 1 <= MAX_SUPPLY, "BAMC: max supply exceeded");
        require(
            msg.value == PRICE * amount,
            "BAMC: ether sent is less than the price"
        );

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), _nextTokenId);
            _nextTokenId += 1;
        }

        nextTokenId = _nextTokenId;
        emit Mint(_msgSender(), amount);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_artist).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
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
