// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./Ownable.sol";
import "./Strings.sol";
import "./IERC20.sol";
import "./IERC165.sol";
import "./IERC2981.sol";
import "./IERC721Metadata.sol";
import "./ERC721.sol";
import "./MerkleProof.sol";

contract CryptoBabyLions is Ownable, ERC721, IERC2981 {
    using Strings for uint256;

    struct WhitelistInfo {
        bytes32 merkleRoot;
        uint256 quantity;
        uint256 price;
    }

    uint16 internal royalty = 500; // base 10000, 5%
    uint16 public constant BASE = 10000;
    uint16 public constant MAX_TOKENS = 3333;
    uint16 public constant MAX_MINT = 3;
    uint256 public constant MINT_PRICE = 0.05 ether;
    uint256 public startBlock = type(uint256).max - 1;

    string private baseURI;
    string private centralizedURI;
    string private contractMetadata;
    address public withdrawAccount;
    uint256 public totalSupply;
    uint256 public totalPreMinted;

    bool public prvContractMinted;
    bool public whitelistMinting = true;
    uint8 public whitelistPlansCounter;
    mapping(uint8 => WhitelistInfo) public whitelistPlans;
    mapping(address => mapping(uint8 => uint256)) public mintedCount;

    modifier onlyWhitdrawable() {
        require(_msgSender() == withdrawAccount, 'CBL: Not authorzed to withdraw');
        _;
    }

    constructor(
        string memory _contractMetadata,
        string memory ipfsURI,
        string memory _centralizedURI
    ) ERC721('Crypto Baby Lions', 'CBL') {
        contractMetadata = _contractMetadata;
        baseURI = ipfsURI;
        centralizedURI = _centralizedURI;
        whitelistPlansCounter++; // index 0 is reserved for public mint so start from 1
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'CBL: URI query for nonexistent token');

        string memory baseContractURI = _baseURI();

        // for viewing NFTs in minting duration we reveal minteds metadata
        if (totalSupply < MAX_TOKENS) {
            baseContractURI = centralizedURI;
        }

        return string(abi.encodePacked(baseContractURI, tokenId.toString()));
    }

    function contractURI() public view returns (string memory) {
        return contractMetadata;
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (_salePrice * royalty) / BASE);
    }

    function whitelistMint(
        uint256 quantity,
        uint8 whitelistIndex,
        bytes32[] calldata proof
    ) public payable {
        require(whitelistMinting, 'CBL: Whitelist Minting is not allowed');
        require(totalSupply + quantity <= MAX_TOKENS, 'CBL: That many tokens are not available');
        address msgSender = _msgSender();
        uint256 accountNewMintCount = mintedCount[msgSender][whitelistIndex] + quantity;

        WhitelistInfo memory whitelistInfo = whitelistPlans[whitelistIndex];

        require(accountNewMintCount <= whitelistInfo.quantity, 'CBL: That many tokens are not available this account');

        bytes32 leaf = keccak256(abi.encodePacked(msgSender));
        require(MerkleProof.verify(proof, whitelistInfo.merkleRoot, leaf), 'CBL: Invalid proof');

        uint256 totalPrice = quantity * whitelistInfo.price;
        require(msg.value >= totalPrice, 'CBL: Not enough ethers');
        if (msg.value > totalPrice) {
            payable(msgSender).transfer(msg.value - totalPrice);
        }

        mintedCount[msgSender][whitelistIndex] = accountNewMintCount;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msgSender, totalSupply);
            totalSupply++;
        }
    }

    function mint(uint256 quantity) public payable {
        require(startBlock <= block.number, 'CBL: Minting time is not started');
        require(totalSupply + quantity <= MAX_TOKENS, 'CBL: That many tokens are not available');
        address msgSender = _msgSender();
        uint256 accountNewMintCount = mintedCount[msgSender][0] + quantity;

        require(accountNewMintCount <= MAX_MINT, 'CBL: That many tokens are not available this account');

        uint256 totalPrice = quantity * MINT_PRICE;
        require(msg.value >= totalPrice, 'CBL: Not enough ethers');
        if (msg.value > totalPrice) {
            payable(msgSender).transfer(msg.value - totalPrice);
        }

        mintedCount[msgSender][0] = accountNewMintCount;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msgSender, totalSupply);
            totalSupply++;
        }
    }

    function mintOldContract(address prvContract, uint256[] calldata ascendingSkippingTokens) public onlyOwner {
        require(!prvContractMinted, 'CBL: Already minted');
        CryptoBabyLions prvContractInstance = CryptoBabyLions(prvContract);
        uint256 prvContractTotalSupply = prvContractInstance.totalSupply();

        uint256 skipTokenIndex;
        uint256 maxAllowedIndex = ascendingSkippingTokens.length - 1;
        for (uint256 i = 0; i < prvContractTotalSupply; i++) {
            if (i != ascendingSkippingTokens[skipTokenIndex]) {
                address prvOwner = prvContractInstance.ownerOf(i);
                _safeMint(prvOwner, totalSupply);
                totalSupply++;
            } else if (skipTokenIndex < maxAllowedIndex) {
                skipTokenIndex++;
            }
        }
        prvContractMinted = true;
    }

    function addWhitelist(
        bytes32 merkleRoot,
        uint256 quantity,
        uint256 price
    ) public onlyOwner {
        require(whitelistPlansCounter < type(uint8).max, 'CBL: Cant add more whitelists');
        uint8 whiteListPlanIndex = whitelistPlansCounter;
        whitelistPlans[whiteListPlanIndex] = WhitelistInfo(merkleRoot, quantity, price);
        whitelistPlansCounter++;
        emit WhitelistAdded(whiteListPlanIndex, merkleRoot, quantity, price);
    }

    function editWhitelist(uint8 whiteListPlanIndex, bytes32 merkleRoot) public onlyOwner {
        require(whiteListPlanIndex < whitelistPlansCounter, 'CBL: Whitelist plan index is out of range');
        require(whiteListPlanIndex != 0, 'CBL: Whitelist plan is more than zero');
        whitelistPlans[whiteListPlanIndex].merkleRoot = merkleRoot;
        emit WhitelistUpdated(whiteListPlanIndex, merkleRoot);
    }

    function setContractMetadata(string memory _contractMetadata) public onlyOwner {
        contractMetadata = _contractMetadata;
    }

    function setStartBlock(uint256 _block) public onlyOwner {
        startBlock = _block;
        emit StartTimeUpdated(_block);
    }

    function setRoyalty(uint16 _royalty) public onlyOwner {
        require(_royalty >= 0 && _royalty <= 1000, 'CBL: Royalty must be between 0% and 10%');

        royalty = _royalty;
    }

    function setWhitelistMinting(bool isActive) public onlyOwner {
        require(isActive != whitelistMinting, 'CBL: Whitelist minting is already set to this value');

        whitelistMinting = isActive;
        emit WhitelistMintingStatusUpdated(isActive);
    }

    function setWithdrawAccount(address account) public onlyOwner {
        require(withdrawAccount != account, 'CBL: Already set');
        withdrawAccount = account;
    }

    function withdraw(uint256 _amount) public onlyWhitdrawable {
        uint256 balance = address(this).balance;
        require(_amount <= balance, 'CBL: Insufficient funds');

        bool success;
        (success, ) = payable(_msgSender()).call{value: _amount}('');
        require(success, 'CBL: Withdraw failed');

        emit ContractWithdraw(_msgSender(), _amount);
    }

    function withdrawTokens(address _tokenContract, uint256 _amount) public onlyWhitdrawable {
        IERC20 tokenContract = IERC20(_tokenContract);

        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance >= _amount, 'CBL: Not enough balance');
        tokenContract.transfer(_msgSender(), _amount);

        emit ContractWithdrawToken(_msgSender(), _tokenContract, _amount);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _exists(uint256 tokenId) internal view override returns (bool) {
        return tokenId < totalSupply;
    }

    event ContractWithdraw(address indexed withdrawAddress, uint256 amount);
    event ContractWithdrawToken(address indexed withdrawAddress, address indexed token, uint256 amount);
    event WhitelistAdded(uint256 index, bytes32 merkleRoot, uint256 quantity, uint256 price);
    event WhitelistUpdated(uint256 index, bytes32 merkleRoot);
    event StartTimeUpdated(uint256 blockNumber);
    event WhitelistMintingStatusUpdated(bool isActive);
}
