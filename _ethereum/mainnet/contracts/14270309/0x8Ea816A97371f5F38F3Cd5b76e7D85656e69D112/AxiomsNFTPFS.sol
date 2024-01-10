// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Strings.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./ERC721Min.sol";

contract AxiomsNFTPFS is Ownable, ERC721Min, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    mapping(address => bool) proxyToApproved; // proxy allowance for interaction with future contract
    uint256 public MAX_MINT; // total mint + 1
    uint256 public MAX_MINT_FOR_ONE; // total mint; precomputed for gas
    uint256 public MAX_MINT_FOR_THREE; // total mint; precomputed for gas
    uint256 public PRICE;
    uint256 public INCREASE_VALUE;
    string private _contractURI;
    string private _tokenBaseURI = "https://defimagic.mypinata.cloud/ipfs/QmQGyRGiCa3mV2F6r57EHicXvSytU1ymmVFh914V2WaGkb";
    string private _redeemedURI = "https://defimagic.mypinata.cloud/ipfs/QmQGyRGiCa3mV2F6r57EHicXvSytU1ymmVFh914V2WaGkb";
    address private _vaultAddress = 0x66e11Dc99B8f8e350e30d4Ec3EA480EC01D7a360;
    address private _dmAddress = 0x75f5B78015D79B2f96BD6f24F77EF22ec829D7D0;
    bool useBaseUriOnly = true;
    bool public saleLive;
    
    constructor(uint256 price, uint256 maxMint, uint256 increaseVal) 
        ERC721Min("AXIOMS Price Floor Stabilizer", "AXI-PFS") 
    {
        PRICE = price;
        MAX_MINT = maxMint + 1;
        MAX_MINT_FOR_ONE = maxMint;
        MAX_MINT_FOR_THREE = maxMint - 2;
        INCREASE_VALUE = increaseVal;
    }

    // ** - CORE - ** //

    function buyOne() external payable {
        require(saleLive, "SALE_CLOSED");
        require(PRICE + INCREASE_VALUE * (_owners.length) == msg.value, "INCORRECT_ETH");
        require(MAX_MINT_FOR_ONE > _owners.length, "EXCEED_MAX_SUPPLY");
        _mintMin();
    }

    function buyThree() external payable {
        require(saleLive, "SALE_CLOSED");
        require((PRICE + INCREASE_VALUE * (_owners.length) +
            INCREASE_VALUE) * 3 == msg.value, "INCORRECT_ETH");
        require(MAX_MINT_FOR_THREE > _owners.length, "EXCEED_MAX_SUPPLY");
        _mintMin();
        _mintMin();
        _mintMin();
    }    

    function getPrice() external view returns(uint256) {
        return PRICE + INCREASE_VALUE * (_owners.length);
    }

    function getPriceForThree() external view returns(uint256) {
        return (PRICE + INCREASE_VALUE * (_owners.length) +
            INCREASE_VALUE) * 3;
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

    function gift(address[] calldata receivers, uint256[] memory amounts) external onlyOwner {
        require(MAX_MINT > _owners.length + receivers.length, "EXCEED_MAX_SUPPLY");
        for (uint256 x = 0; x < receivers.length; x++) {
            require(receivers[x] != address(0), "MINT_TO_ZERO");
            require(MAX_MINT > _owners.length + amounts[x], "EXCEED_MAX_SUPPLY");
            for (uint256 i = 0; i < amounts[x]; i++) {
                _mintMin2(receivers[x]);
            }
        }
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    // to avoid opensea listing costs
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        if (proxyToApproved[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function flipProxyState(address proxyAddress) public onlyOwner {
        proxyToApproved[proxyAddress] = !proxyToApproved[proxyAddress];
    }

    // ** - SETTERS - ** //

    function setIncreaseValue(uint256 increaseValue) external onlyOwner {
        INCREASE_VALUE = increaseValue;
    }   

    function setMaxMint(uint8 maxMint) external onlyOwner {
        MAX_MINT = maxMint + 1;
        MAX_MINT_FOR_ONE = maxMint;
    }

    function setDMAddress(address dmAddress) external onlyOwner {
        _dmAddress = dmAddress;
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
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function toggleUseBaseUri() external onlyOwner {
        useBaseUriOnly = !useBaseUriOnly;
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (useBaseUriOnly) return _tokenBaseURI;
        return bytes(_tokenBaseURI).length > 0
                ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString()))
                : "";
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool) {
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
