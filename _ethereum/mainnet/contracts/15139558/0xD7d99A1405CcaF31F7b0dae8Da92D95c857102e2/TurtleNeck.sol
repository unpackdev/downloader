// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./MerkleProof.sol";
import "./ReentrancyGuard.sol";

contract TurtleNeck is ERC721A, Ownable, ReentrancyGuard {
    event StateChange(uint256 _newState);

    using Strings for uint256;

    uint256 public maxTokens = 8000;
    uint256 public price = 0.005 ether;
    uint256 public maxPerWallet = 5;

    bytes32 merkleRoot;

    string baseURI;
    string notRevealedUri =
        "ipfs://bafybeialwxpv4g3m4ttjeme6u6jeoa7auqb5cnwcwfjb4phajktgpr7agy/";

    bool revealed;

    enum SaleState {
        NOT_ACTIVE,
        PRESALE,
        PUBLIC
    }

    SaleState public saleState = SaleState.NOT_ACTIVE;

    mapping(address => uint256) public mintedCount;
    mapping(address => uint256) public freeTokens;

    address vaultAddress = address(0x44561C02Af1E15A05f95B4b942D9b8D64039656F);

    constructor() ERC721A("Turtle Necks", "Necks") {
        freeTokens[address(0xfEa83b5023300AeCE5b14e1f278cee3F8De52f9d)] = 20;
        freeTokens[address(0xBb859d36D5a6734E47CDba136D8030D883b18d30)] = 20;
        freeTokens[address(0x978E5D29cC261977A1c9aFC54eb7E7c1e67fa264)] = 20;
        freeTokens[address(0x80F87D5AD1DdE6a230c1fDF75d91322Be6d65c13)] = 20;
        freeTokens[address(0xd29220809DF4e3E84Da811522Abb28898ba0527B)] = 20;
        freeTokens[address(0x6BBc8745ECd7A024456699C5120D605e78d7c2Df)] = 20;
        freeTokens[address(0x64A324Ab761fF12e3777116820F5AA77375Da2c5)] = 20;
        freeTokens[address(0x2FBd36E25E1eB5fC3e58fceaa6477B0D5D33B362)] = 20;
        freeTokens[address(0x243822078885d12b6b243D4d6a5cC4CC1703A95A)] = 20;
        freeTokens[address(0x4839ad1d340c766a33cf59Ba72416F2CfA67A547)] = 20;
        freeTokens[address(0xF0039D287c7230105c4CC0A41CD98760FD7ff2f0)] = 20;
        freeTokens[address(0xe03bd8a293D5391f432825b57960d49ACB13DC91)] = 20;
        freeTokens[address(0x3158c894BA96eC5d0220a3Ba0E1aDE7e65BC08c9)] = 20;
        freeTokens[address(0xaB65122c6876689FB430ecb5b3359a2fC0bdB5E8)] = 20;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root)
        internal
        view
        returns (bool)
    {
        return (
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            )
        );
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
                abi.encodePacked(notRevealedUri, tokenId.toString(), ".json")
            );
    }

    modifier canMint(uint256 _amount, bool _checkMaxTokensPerWallet) {
        require(
            maxTokens >= _amount + totalSupply(),
            "Not enough tokens left!"
        );
        if (_checkMaxTokensPerWallet) {
            require(
                _amount > 0 &&
                    _amount + mintedCount[msg.sender] <= maxPerWallet,
                "Too many tokens per wallet!"
            );
        }
        _;
    }

    function mint(uint256 _amount, bytes32[] calldata _merkleProof)
        external
        payable
        canMint(_amount, true)
        nonReentrant
    {
        require(saleState != SaleState.NOT_ACTIVE, "Sale is not active!");
        if (saleState == SaleState.PRESALE) {
            require(
                isValidMerkleProof(_merkleProof, merkleRoot),
                "Not whitelisted!"
            );
        }
        uint256 finalPrice = _amount * price;
        if (mintedCount[msg.sender] == 0) {
            finalPrice -= price;
        }
        mintedCount[msg.sender] += _amount;
        require(msg.value >= finalPrice, "Not enough ETH!");
        _safeMint(msg.sender, _amount);
    }

    function vaultMint(uint256 _amount) external onlyOwner canMint(_amount, false) {
        _safeMint(vaultAddress, _amount);
    }

    function claimFreeNfts() external canMint(10, false) nonReentrant  {
        require(saleState != SaleState.NOT_ACTIVE, "Sale is not active!");
        require(freeTokens[msg.sender] >= 10, "No free tokens!");
        freeTokens[msg.sender] -= 10;
        _safeMint(msg.sender, 10);
    }

    // Only owner functions

    function setSaleState(uint256 _saleState) external onlyOwner {
        emit StateChange(_saleState);
        if (_saleState == 0) {
            saleState = SaleState.NOT_ACTIVE;
        } else if (_saleState == 1) {
            saleState = SaleState.PRESALE;
        } else if (_saleState == 2) {
            saleState = SaleState.PUBLIC;
        }
    }

    function revealNfts(string calldata _ipfsBaseURI) external onlyOwner {
        baseURI = _ipfsBaseURI;
        revealed = true;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function addFreeTokenClaimer(address _recipent) external onlyOwner {
        freeTokens[_recipent] = 20;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Failure!");
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setVaultAddress(address _address) external onlyOwner {
        vaultAddress = _address;
    }

    receive() external payable {}
}