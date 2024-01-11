//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";

abstract contract NCCoinContract {
    function sendCoins(uint256 _amount, address _to) public virtual;
}

contract NinjaCountry is ERC721A, Ownable, ReentrancyGuard, Pausable {
    NCCoinContract NCCoin;

    event SaleStateChange(uint256 _newState);

    using Strings for uint256;

    bytes32 public presaleMerkleRoot;
    bytes32 public OGSaleMerkleRoot;

    uint256 public maxTokens = 10000;
    uint256 public maxTokensPerWallet = 5;

    uint256 public OGListPrice = 0.05 ether;
    uint256 public presalePrice = 0.1 ether;
    uint256 public price = 0.2 ether;

    string private baseURI;
    string public NC_PROVENANCE =
        "0cf6a0dc9800a97e851e471ce5202b3be2690c6e5c7f701e31021c08047301b8";
    string private notRevealedJson =
        "ipfs://bafybeiect2hnlcga7pnzcjs67tcnyx7knpkcvkhtcbvnyaxzchivvhldmy/";

    bool public revealed;

    enum SaleState {
        NOT_ACTIVE,
        OG_SALE,
        PRESALE,
        PUBLIC_SALE
    }

    SaleState public saleState = SaleState.NOT_ACTIVE;

    mapping(address => uint256) mintedPerWallet;

    constructor() ERC721A("Ninja Country", "NC") {}

    modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
        require(
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "Address does not exist in list"
        );
        _;
    }

    modifier canMint(uint256 _amount) {
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        require(
            _amount > 0 &&
                _amount + mintedPerWallet[msg.sender] <= maxTokensPerWallet,
            "Too many tokens per wallet!"
        );
        _;
    }

    function setNCCoinAddress(address _address) external onlyOwner {
        NCCoin = NCCoinContract(_address);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function startPresale() external onlyOwner {
        saleState = SaleState.PRESALE;
        emit SaleStateChange(uint256(SaleState.PRESALE));
    }

    function startPublicSale() external onlyOwner {
        saleState = SaleState.PUBLIC_SALE;
        emit SaleStateChange(uint256(SaleState.PUBLIC_SALE));
    }

    function startOGSale() external onlyOwner {
        saleState = SaleState.OG_SALE;
        emit SaleStateChange(uint256(SaleState.OG_SALE));
    }

    function setMaxTokensPerWallet(uint256 _amount) external onlyOwner {
        maxTokensPerWallet = _amount;
    }

    function setPresaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        presaleMerkleRoot = _merkleRoot;
    }

    function setOGSaleMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        OGSaleMerkleRoot = _merkleRoot;
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        if (revealed) {
            return
                string(
                    abi.encodePacked(_baseURI(), tokenId.toString(), ".json")
                );
        }
        return
            string(
                abi.encodePacked(notRevealedJson, tokenId.toString(), ".json")
            );
    }

    function presaleMint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        canMint(_amount)
        isValidMerkleProof(_merkleProof, presaleMerkleRoot)
    {
        require(saleState == SaleState.PRESALE, "Presale is not active!");
        require(msg.value >= _amount * presalePrice, "Not enough ETH!");
        mintedPerWallet[msg.sender] += _amount;
        NCCoin.sendCoins(5000 ether * _amount, msg.sender);
        _safeMint(msg.sender, _amount);
    }

    function OGSaleMint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
        nonReentrant
        canMint(_amount)
        isValidMerkleProof(_merkleProof, OGSaleMerkleRoot)
    {
        require(saleState == SaleState.OG_SALE, "OG list sale is not active!");
        require(msg.value >= _amount * OGListPrice, "Not enough ETH!");
        mintedPerWallet[msg.sender] += _amount;
        NCCoin.sendCoins(5000 ether * _amount, msg.sender);
        _safeMint(msg.sender, _amount);
    }

    function mint(uint256 _amount)
        external
        payable
        nonReentrant
        canMint(_amount)
    {
        require(saleState == SaleState.PUBLIC_SALE, "Public sale not active!");
        require(msg.value >= _amount * price, "Not enough ETH!");
        mintedPerWallet[msg.sender] += _amount;
        NCCoin.sendCoins(5000 ether * _amount, msg.sender);
        _safeMint(msg.sender, _amount);
    }

    function revealTokens(string calldata baseURI_) external onlyOwner {
        baseURI = string(abi.encodePacked("ipfs://", baseURI_, "/"));
        revealed = true;
    }

    function withdrawBalance() external onlyOwner {
        (bool success, ) = payable(
            address(0xbCbe782cB54fd2F5D5d02FB31fE4E28c0E62Fe44)
        ).call{value: address(this).balance}("");
        require(success, "Withdrawal failed!");
    }
}
