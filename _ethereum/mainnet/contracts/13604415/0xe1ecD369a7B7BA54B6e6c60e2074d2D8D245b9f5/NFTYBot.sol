// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./NFTYPass.sol";
import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./ERC721Enumerable.sol";

contract NFTYBot is ERC721, ERC721Enumerable, Ownable {
    uint256 public initialPrice = 2 ether;
    uint256 public renewalPrice = 0.5 ether;
    uint256 public constant TOKEN_MAXIMUM = 256;

    bool public migration;
    bool public purchasable;

    string public baseURI;

    address private constant A = 0xc57112FB1872130A85ecF29877DD96042572a027;
    address private constant B = 0x69827Bf658898541380f78e0FBaF920ff020203b;

    mapping(uint256 => bool) public migrated;
    mapping(uint256 => uint256) public tokenExpiry;

    NFTYPass public legacyToken =
        NFTYPass(0x46C1d006e1f6611825cD448E1D49Cf660a2b79a1);

    constructor(string memory uri) ERC721("NFTYPass", "NFTY") {
        baseURI = uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _isExpired(uint256 tokenId) internal view returns (bool) {
        return block.timestamp > tokenExpiry[tokenId];
    }

    function _isTransferrable(uint256 tokenId) internal view returns (bool) {
        return
            (!_isExpired(tokenId) &&
                (tokenExpiry[tokenId] - block.timestamp > 1 weeks)) ||
            msg.sender == owner();
    }

    function setURI(string calldata newuri) external onlyOwner {
        baseURI = newuri;
    }

    function setInitialPrice(uint256 price) external onlyOwner {
        initialPrice = price;
    }

    function setRenewalPrice(uint256 price) external onlyOwner {
        renewalPrice = price;
    }

    function toggleSale() external onlyOwner {
        purchasable = !purchasable;
    }

    function toggleMigration() external onlyOwner {
        migration = !migration;
    }

    function updateExpiryTime(uint256 tokenId, uint256 expiry)
        external
        onlyOwner
    {
        require(_exists(tokenId), "NFTYPass: Token does not exist");

        tokenExpiry[tokenId] = expiry;
    }

    function transferLegacyOwnership(address newOwner) external onlyOwner {
        legacyToken.transferOwnership(newOwner);
    }

    function setExpiryTime(uint256 tokenId, uint256 time) external onlyOwner {
        require(_exists(tokenId), "NFTYBot: Token does not exist");

        tokenExpiry[tokenId] = time;
    }

    function issueToken(address to) external onlyOwner {
        uint256 supply = totalSupply();

        require(supply + 1 <= TOKEN_MAXIMUM, "NFTYBot: Exceeds supply maximum");
        uint256 tokenId = supply + 1;
        tokenExpiry[tokenId] = block.timestamp + 30 days;

        _safeMint(to, tokenId);
    }

    function purchase() external payable {
        uint256 supply = totalSupply();

        require(purchasable, "NFTYBot: Sale is not live");
        require(msg.value >= initialPrice, "NFTYBot: Invalid ether amount");
        require(supply + 1 <= TOKEN_MAXIMUM, "NFTYBot: Exceeds supply maximum");

        uint256 tokenId = supply + 1;
        tokenExpiry[tokenId] = block.timestamp + 30 days;
        _safeMint(msg.sender, tokenId);
    }

    function migrate() external {
        require(migration, "NFTYBot: Migration must be enabled");
        uint256 balance = legacyToken.balanceOf(msg.sender);

        while (balance > 0) {
            uint256 tokenId = legacyToken.tokenOfOwnerByIndex(
                msg.sender,
                balance - 1
            );

            require(!migrated[tokenId], "NFTYPass must not be migrated");

            balance--;
            migrated[tokenId] = true;
            tokenExpiry[tokenId] = legacyToken.tokenExpiry(tokenId) + 1 weeks;

            legacyToken.setExpiryTime(tokenId, block.timestamp + 2 weeks);
            legacyToken.transferFrom(msg.sender, address(this), tokenId);
            legacyToken.setExpiryTime(tokenId, 0);

            _safeMint(msg.sender, tokenId);
        }
    }

    function renew(uint256 tokenId) external payable {
        require(_exists(tokenId), "NFTYBot: Token does not exist");
        require(msg.value >= renewalPrice, "NFTYPass: Invalid ether amount");

        if (_isExpired(tokenId)) {
            tokenExpiry[tokenId] = block.timestamp + 30 days;
        } else {
            tokenExpiry[tokenId] += 30 days;
        }
    }

    function expiryTime(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "NFTYBot: Token does not exist");

        return tokenExpiry[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(
            _isTransferrable(tokenId),
            "NFTYBot: Token must have at least 1 week remaining"
        );

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function withdrawBalance() external onlyOwner {
        if (address(legacyToken).balance > 0) {
            legacyToken.withdrawBalance();
        }

        uint256 share = address(this).balance / 2;

        (bool a, ) = A.call{value: share}("");
        (bool b, ) = B.call{value: share}("");

        require(a && b, "NFTYBot: Failed to withdraw");
    }
}
