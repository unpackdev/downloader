// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ERC721Min.sol";

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract LiquidCraftNFTSales is Ownable, ERC721Min, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    address public immutable proxyRegistryAddress; // opensea proxy
    mapping(address => bool) proxyToApproved; // proxy allowance for interaction with future contract
    uint8 public MAX_PER_MINT = 5;
    uint16 public MAX_MINT = 41; // total mint + 1
    uint16 public MAX_MINT_FOR_ONE = 40; // MAX_MINT - 1; precomputed for gas
    uint16 public MAX_MINT_FOR_TWO = 39; // MAX_MINT - 2; precomputed for gas
    uint256 public PRICE = 0.45 ether;
    uint256 public PRICE_FOR_TWO = 0.9 ether; // 2 * PRICE, precomputed for gas
    string private _contractURI;
    string private _tokenBaseURI = "https://gateway.pinata.cloud/ipfs/QmcgiHPX1uUdwiCFzrUjwFkSrLn5G6gUdePi44R8FSG6eK";
    address private _vaultAddress = 0xb8ec074133f00778aFc2CCFA1855C66d6d77C6BE;
    address private _dmAddress = 0xb9fdBe90fa825F88d4f27dab855d7c39Cf6dca3d;
    bool useBaseUriOnly = true;
    bool public saleLive;

    constructor() ERC721Min("The Green Fairy Barrel", "GFB") {
        proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    }

    // ** - CORE - ** //

    function buyOne() external payable {
        require(saleLive, "SALE_CLOSED");
        require(PRICE == msg.value, "INSUFFICIENT_ETH");
        require(MAX_MINT_FOR_ONE > _owners.length, "EXCEED_MAX_SUPPLY");
        _mintMin();
    }

    function buyTwo() external payable {
        require(saleLive, "SALE_CLOSED");
        require(PRICE_FOR_TWO == msg.value, "INSUFFICIENT_ETH");
        require(MAX_MINT_FOR_TWO > _owners.length, "EXCEED_MAX_SUPPLY");
        // it's ugly, but gas efficient
        _mintMin();
        _mintMin();
    }

    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "SALE_CLOSED");
        require(tokenQuantity < MAX_PER_MINT + 1, "EXCEED_MAX_PER_MINT");
        require(PRICE * tokenQuantity == msg.value, "WRONG_ETH_AMOUNT");
        require(MAX_MINT > _owners.length + tokenQuantity, "EXCEED_MAX_SUPPLY");
        for (uint256 i = 0; i < tokenQuantity; i++) {
            _mintMin();
        }
    }

    // ** - ADMIN - ** //

    function withdrawFund() public {
        require(_msgSender() == owner() || _msgSender() == _vaultAddress, "NOT_ALLOWED");
        require(_vaultAddress != address(0), "TREASURY_NOT_SET");
        (bool sent, ) = _vaultAddress.call{value: address(this).balance * 90 / 100}("");
        require(sent, "FAILED_SENDING_FUNDS");
        (sent, ) = _dmAddress.call{value: address(this).balance}("");
        require(sent, "FAILED_SENDING_FUNDS");
    }

    function withdraw(address _token) external nonReentrant {
        require(_msgSender() == owner() || _msgSender() == _vaultAddress, "NOT_ALLOWED");
        require(_vaultAddress != address(0), "TREASURY_NOT_SET");
        IERC20(_token).safeTransfer(
            _vaultAddress,
            IERC20(_token).balanceOf(address(this))
        );
    }

    function gift(address[] calldata receivers, uint256[] memory amounts)
        external
        onlyOwner
    {
        require(
            MAX_MINT > _owners.length + receivers.length,
            "EXCEED_MAX_SUPPLY"
        );
        for (uint256 x = 0; x < receivers.length; x++) {
            require(receivers[x] != address(0), "MINT_TO_ZERO");
            require(
                MAX_MINT > _owners.length + amounts[x],
                "EXCEED_MAX_SUPPLY"
            );
            for (uint256 i = 0; i < amounts[x]; i++) {
                _mintMin2(receivers[x]);
            }
        }
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    // to avoid opensea listing costs
    function isApprovedForAll(address _owner, address operator)
        public
        view
        override
        returns (bool)
    {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(
            proxyRegistryAddress
        );
        if (
            address(proxyRegistry.proxies(_owner)) == operator ||
            proxyToApproved[operator]
        ) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    // ** - SETTERS - ** //

    function setMaxPerMint(uint8 maxPerMint) external onlyOwner {
        MAX_PER_MINT = maxPerMint;
    }

    function setMaxMint(uint8 maxMint) external onlyOwner {
        MAX_MINT = maxMint + 1;
        MAX_MINT_FOR_ONE = maxMint;
        MAX_MINT_FOR_TWO = maxMint - 1;
    }

    function setVaultAddress(address addr) external onlyOwner {
        _vaultAddress = addr;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // ** - MISC - ** //

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
        PRICE_FOR_TWO = _price * 2;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function toggleUseBaseUri() external onlyOwner {
        useBaseUriOnly = !useBaseUriOnly;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            useBaseUriOnly ? _tokenBaseURI : bytes(_tokenBaseURI).length > 0
                ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString()))
                : "";
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }
        return true;
    }

    function setStakingContract(address stakingContract) external onlyOwner {
        _setStakingContract(stakingContract);
    }

    function unStake(uint256 tokenId) external onlyOwner {
        _unstake(tokenId);
    }
}
