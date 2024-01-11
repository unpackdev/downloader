// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


import "./ERC721A.sol";  
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";
import "./IERC20.sol";

error NotAdmin();
error MintExceedLimit();
error AlreadyMinted();

contract ETHYKYK is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 public maxTokens = 500;
    uint256 public saleLimit = 1;
    uint256 public PRICE = 1000 * 10 ** 6; // 1000 USDC

    address public erc20TokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // mainnet
    
    address public projectWallet = 0x36FE04d3700fB91491C0A18aD3D16D9De15283B9; // for project mints mainnet

    mapping(address => bool) private addressMinted;

    string public baseTokenURI = "https://gateway.pinata.cloud/ipfs/QmSWFbACLx68ENHEdeodQ1bLYThZ8EU818GDGE1rwdSrdL";

    constructor() ERC721A("ETH YKYK", "EYKYK") {}

    function mintToken() public nonReentrant {
        if (addressMinted[msg.sender]) revert AlreadyMinted();
        if (totalSupply() + 1 > maxTokens) revert MintExceedLimit();

        IERC20 USDC_Contract = IERC20(erc20TokenAddress);
        bool transferred = USDC_Contract.transferFrom(msg.sender, projectWallet, PRICE);
        require(transferred, "ERC20 tokens failed to transfer");

        addressMinted[msg.sender] = true;
        _mint(msg.sender, 1);
    }

    function adminMint(uint256 _amount) public nonReentrant {
        if (msg.sender != projectWallet) revert NotAdmin();
        if (totalSupply() + _amount > maxTokens) revert MintExceedLimit();
        if (_amount > 100) revert MintExceedLimit(); // not more than 100 per tx

        _mint(msg.sender, _amount);
    }

    function setProjectWalletAddress(address _address) public onlyOwner {
        projectWallet = _address;
    }

    function setPrice(uint256 _priceInUSDC) public onlyOwner {
        PRICE = _priceInUSDC * 10 ** 6;
    }

    function setMaxLimit(uint256 _limit) public onlyOwner {
        maxTokens = _limit;
    }

    function setUSDCAddress(address _address) public onlyOwner {
        erc20TokenAddress = _address;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return _baseURI();
    }

    function setTokenURI(string calldata _tokenURI) public onlyOwner {
        baseTokenURI = _tokenURI;
    }
}