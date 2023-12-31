//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Initializable.sol";
import "./StringsUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ProxyableUpgradeable.sol";
import "./WithdrawableUpgradeable.sol";
import "./ERC721BaseUpgradeable.sol";

// Nfts are purchaseable with Native

contract ColrFilmsNFT is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ProxyableUpgradeable,
    WithdrawableUpgradeable,
    ERC721BaseUpgradeable
{
    using StringsUpgradeable for uint256;

    struct Series {
        uint32 startID;
        uint32 endID;
        string uri;
    }
    mapping(uint256 => Series) public series;

    address public treasury;

    bool public saleActive;

    uint256 public maxSupply;
    uint256 public paymentAmount;
    uint256 public seriesCount;

    event Buy(address indexed sender, uint256 indexed amount);
    event WithdrawRevenue(address indexed sender, uint256 indexed amount);

    error ExceedsMaxSupply();
    error InsufficientPayment(uint256 sent, uint256 required);
    error SaleIsClosed();
    error ZeroAddress();

    modifier saleIsActive() {
        if (!saleActive) revert SaleIsClosed();
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        address _treasury,
        uint256 _paymentAmount,
        string calldata tokenBaseURI
    ) public initializer notZeroAddress(_treasury) {
        treasury = _treasury;
        paymentAmount = _paymentAmount;
        _tokenBaseURI = tokenBaseURI;
        OwnableUpgradeable.__Ownable_init();
        ERC721BaseUpgradeable.__ERC721BaseUpgradeable_init(name, symbol);
        series[0] = Series(
            0,
            1110,
            "https://blue-selective-anaconda-677.mypinata.cloud/ipfs/Qmc8upny4S4g6sQz5vriELA1HMHxDNxyZMT5dm68nbrrK5/1"
        );
        series[1] = Series(
            1111,
            2221,
            "https://blue-selective-anaconda-677.mypinata.cloud/ipfs/Qmc8upny4S4g6sQz5vriELA1HMHxDNxyZMT5dm68nbrrK5/2"
        );
        seriesCount = 2;
        maxSupply = 2222;
    }

    receive() external payable onlyOwner {}

    function addSeries(uint32 supply, string calldata uri) external onlyOwner {
        Series memory s = series[seriesCount - 1];
        series[seriesCount] = Series(s.endID + 1, s.endID + supply, uri);
        ++seriesCount;
        maxSupply += supply;
    }

    function buy(uint256 amount) external payable saleIsActive nonReentrant {
        if (totalSupply + amount > maxSupply) revert ExceedsMaxSupply();
        uint256 requiredAmount = paymentAmount * amount;
        _checkSufficientNativePayment(requiredAmount);
        emit Buy(_msgSender(), amount);
        return _batchMint(_msgSender(), amount);
    }

    function burn(uint32 tokenId) external {
        _burn(tokenId);
    }

    function buyOne() external payable saleIsActive nonReentrant {
        if (totalSupply + 1 > maxSupply) revert ExceedsMaxSupply();
        _checkSufficientNativePayment(paymentAmount);
        emit Buy(_msgSender(), 1);
        _mint(_msgSender());
    }

    function mint(address receiver) external onlyProxy {
        _mint(receiver);
    }

    function seriesURI(uint256 seriesID) external view returns (string memory) {
        return series[seriesID].uri;
    }

    function setMaxSupply(uint256 value) external onlyOwner {
        maxSupply = value;
    }

    function setPaymentAmount(uint256 value) external onlyOwner {
        paymentAmount = value;
    }

    function setSaleActive(bool value) external onlyOwner {
        saleActive = value;
    }

    function setSeriesURI(
        uint256 seriesID,
        string calldata uri
    ) external onlyOwner {
        series[seriesID].uri = uri;
    }

    function setTreasury(
        address _treasury
    ) external onlyOwner notZeroAddress(_treasury) {
        treasury = _treasury;
    }

    function tokenURI(
        uint256 tokenId
    ) external view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert NonexistentToken(tokenId);
        if (bytes(tokenURIs[uint32(tokenId)]).length != 0)
            return tokenURIs[uint32(tokenId)];
        for (uint256 x; x < seriesCount; ) {
            if (tokenId >= series[x].startID && tokenId <= series[x].endID) {
                return series[x].uri;
            }
            unchecked {
                ++x;
            }
        }
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    function updateConfig(
        bool _saleActive,
        string calldata tokenBaseURI //,
    ) external onlyOwner {
        saleActive = _saleActive;
        _tokenBaseURI = tokenBaseURI;
    }

    function withdrawNativeToTreasury() external onlyOwner {
        _withdrawNativeToTreasury(treasury);
    }

    function withdrawTokensToTreasury(address tokenAddress) external onlyOwner {
        _withdrawTokensToTreasury(treasury, tokenAddress);
    }

    function batchSafeTransferFromSmallInt(
        address from,
        address to,
        uint32[] memory tokenIds,
        bytes memory data
    ) public {
        for (uint32 i; i < tokenIds.length; i++) {
            safeTransferFrom(from, to, tokenIds[i], data);
        }
    }

    function batchTransferFromSmallInt(
        address from,
        address to,
        uint32[] memory tokenIds
    ) public {
        for (uint32 i; i < tokenIds.length; i++) {
            transferFrom(from, to, tokenIds[i]);
        }
    }

    function isApprovedForAll(
        address _owner,
        address operator
    ) public view override returns (bool) {
        return
            proxyToApproved[operator] ||
            super.isApprovedForAll(_owner, operator);
    }

    function _checkSufficientNativePayment(uint256 amount) private view {
        if (amount != msg.value)
            revert InsufficientPayment({sent: msg.value, required: amount});
    }
}
