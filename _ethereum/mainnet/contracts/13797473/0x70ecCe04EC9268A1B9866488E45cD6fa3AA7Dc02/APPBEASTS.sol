// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC721.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./ECDSA.sol";

contract APPBEASTS is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using ECDSA for bytes32;

    string private _baseTokenURI = "ipfs://bafybeifxt4xjig2jydeokozzicvhrls74t66prd7fmbh2orbw4y45ach7e/";
    string private _contractURI =
        "ipfs://bafkreigkbofnj2eq2nnjt7przuhyqn2hdsjp7wlkjcayoolxxh7r7bdzva";

    uint256 public maxSupply = 3100;
    uint256 public maxPresale = 3100;

    uint256 public maxPresaleMintQty = 2;
    uint256 public maxPublicsaleMintQty = 2;

    mapping(address => uint256) public mintedPresaleAddresses;
    mapping(address => uint256) public mintedPublicsaleAddresses;

    address private _internalSignerAddress;
    
    address private _withdrawalAddress;

    uint256 public pricePerToken = 80000000000000000;

    bool public metadataIsLocked = false;
    bool public publicSaleLive = false;
    bool public presaleLive = false;

    constructor(address internalSignerAddress, address withdrawalAddress) ERC721("Appropriated Beasts", "APPBEASTS") {
        _internalSignerAddress = internalSignerAddress;
        _withdrawalAddress = withdrawalAddress;
    }

    // public sale mint
    function mint(uint256 qty) external payable nonReentrant {
        uint256 mintedAmount = mintedPublicsaleAddresses[msg.sender];

        require(publicSaleLive, "Public sale not live");
        require(
            mintedAmount + qty <= maxPublicsaleMintQty,
            "Exceeded maximum public sale quantity"
        );
        require(totalSupply() + qty <= maxSupply, "Out of stock");
        require(pricePerToken * qty == msg.value, "Invalid value");

        for (uint256 i = 0; i < qty; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
        }
        mintedPublicsaleAddresses[msg.sender] = mintedAmount + qty;
    }

    // presale mint
    function presaleMint(
        bytes32 hash,
        bytes memory sig,
        uint256 qty
    ) external payable nonReentrant {
        uint256 mintedAmount = mintedPresaleAddresses[msg.sender];

        require(presaleLive, "Presale not live");
        require(hashSender(msg.sender) == hash, "hash check failed");
        require(
            mintedAmount + qty <= maxPresaleMintQty,
            "Exceeded maximum pre sale quantity"
        );
        require(isInternalSigner(hash, sig), "Direct mint unavailable");
        require(totalSupply() + qty <= maxPresale, "Presale out of stock");
        require(pricePerToken * qty == msg.value, "Invalid value");

        for (uint256 i = 0; i < qty; i++) {
            uint256 tokenId = totalSupply() + 1;
            _safeMint(msg.sender, tokenId);
        }
        mintedPresaleAddresses[msg.sender] = mintedAmount + qty;
    }

    // admin can mint them for giveaways, airdrops etc
	function adminMint(uint256 qty, address to) external payable onlyOwner {
		require(qty > 0, "minimum 1 token");
		require(totalSupply() + qty <= maxSupply, "out of stock");
		for (uint256 i = 0; i < qty; i++) {
			_safeMint(to, totalSupply() + 1);
		}
	}

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function tokenExists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(_baseTokenURI, _tokenId.toString(), ".json")
            );
    }

    function withdrawEarnings() external onlyOwner {
        payable(_withdrawalAddress).transfer(address(this).balance);
    }

    function reclaimERC20(IERC20 erc20Token) external onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    function changePrice(uint256 newPrice) external onlyOwner {
        pricePerToken = newPrice;
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function togglePublicSaleStatus() external onlyOwner {
        publicSaleLive = !publicSaleLive;
    }

    function changeMaxPresale(uint256 _newMaxPresale) external onlyOwner {
        maxPresale = _newMaxPresale;
    }

    function changeMaxPresaleMintQty(uint256 _maxPresaleMintQty)
        external
        onlyOwner
    {
        maxPresaleMintQty = _maxPresaleMintQty;
    }

    function changeMaxPublicsaleMintQty(uint256 _maxPublicsaleMintQty)
        external
        onlyOwner
    {
        maxPublicsaleMintQty = _maxPublicsaleMintQty;
    }

    function setNewMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(newMaxSupply < maxSupply, "you can only decrease it");
        maxSupply = newMaxSupply;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        require(!metadataIsLocked, "Metadata is locked");
        _baseTokenURI = newBaseURI;
    }

    function setContractURI(string memory newuri) external onlyOwner {
        require(!metadataIsLocked, "Metadata is locked");
        _contractURI = newuri;
    }

    function hashSender(address sender) private pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(sender))
            )
        );
        return hash;
    }

    function isInternalSigner(bytes32 hash, bytes memory signature)
        private
        view
        returns (bool)
    {
        return _internalSignerAddress == hash.recover(signature);
    }

    function setInternalSigner(address addr) external onlyOwner {
        _internalSignerAddress = addr;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function lockMetaData() external onlyOwner {
        metadataIsLocked = true;
    }
}
