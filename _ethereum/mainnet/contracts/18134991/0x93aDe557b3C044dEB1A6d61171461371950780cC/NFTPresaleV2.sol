//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";

interface IOracle {
    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80);
}

interface INFT {
    function batchMint(address _user, uint256 _num) external;

    function tokenIdCounter() external view returns (uint256);
}

interface IPool {
    function slot0()
        external
        view
        returns (uint160, int24, uint16, uint16, uint16, uint8, bool);
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function burn(uint256 amount) external;
}

contract NFTPresaleV2 is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    address public paymentWallet;
    uint256 public totalNFTSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public NFTLevel;

    IOracle public oracle;
    address public USDT;
    address public TAMA;
    IPool public pool;

    struct NFTDetails {
        address NFTContract;
        uint256 NFTToSell;
        uint256 price;
        uint256 NFTSold;
        uint256 UserLimit;
    }

    mapping(uint256 => NFTDetails) public nftDetails;
    mapping(address => bool) public wertWhitelisted;
    mapping(address => mapping(uint256 => uint256)) public userNFTPurchase;
    address public tamaPaymentWallet;

    event SaleTimeUpdated(
        bytes32 indexed key,
        uint256 prevValue,
        uint256 newValue
    );

    event NFTPurchased(
        address user,
        uint256 NFTLevel,
        uint256 startNFTID,
        uint256 endNFTID
    );

    error ZeroAddress();
    error InvalidTime(string reason);
    error ArrayLengthMismatch();
    error ZeroBuyAmount();
    error InvalidNFTLevel();
    error InsufficientQuantity();
    error InsufficientPayment();
    error LowBalance();
    error NativeTokenPaymentFailed();
    error TokenPaymentFailed();
    error UserNotWhitelisted();
    error MaxBuyLimitReached();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _oracle,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentWallet,
        address _usdt,
        address _tama,
        address _pool
    ) external initializer {
        if (
            _oracle == address(0) ||
            _paymentWallet == address(0) ||
            _usdt == address(0) ||
            _tama == address(0)
        ) revert ZeroAddress();
        if (_startTime < block.timestamp || _endTime < _startTime) {
            revert InvalidTime("Invalid start and end times");
        }

        __Pausable_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();

        startTime = _startTime;
        endTime = _endTime;
        paymentWallet = _paymentWallet;

        oracle = IOracle(_oracle);
        USDT = _usdt;
        TAMA = _tama;
        pool = IPool(_pool);
        tamaPaymentWallet = address(this);
    }

    function setNFTDetails(
        address[] calldata _NFTAddresses,
        uint256[] calldata _NFTToSell,
        uint256[] calldata _price,
        uint256[] calldata _userLimit
    ) external onlyOwner {
        if (
            _NFTAddresses.length != _NFTToSell.length ||
            _NFTAddresses.length != _price.length ||
            _NFTAddresses.length != _userLimit.length
        ) {
            revert ArrayLengthMismatch();
        }

        for (uint256 i; i < _NFTAddresses.length; ) {
            nftDetails[NFTLevel] = NFTDetails(
                _NFTAddresses[i],
                _NFTToSell[i],
                _price[i],
                0,
                _userLimit[i]
            );
            unchecked {
                ++NFTLevel;
                ++i;
            }
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function changeSaleTimes(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner returns (bool) {
        if (_startTime == 0 && _endTime == 0) {
            revert InvalidTime("Invalid parameters");
        }

        if (_startTime > 0) {
            if (block.timestamp >= startTime) {
                revert InvalidTime("Sale already started");
            }

            if (block.timestamp >= _startTime) {
                revert InvalidTime("New sale start time in past");
            }

            uint256 prevValue = startTime;
            startTime = _startTime;

            emit SaleTimeUpdated(bytes32("START"), prevValue, _startTime);
        }

        if (_endTime > 0) {
            if (block.timestamp >= endTime) {
                revert InvalidTime("Sale already ended");
            }

            if (startTime >= _endTime) revert InvalidTime("Invalid end time");

            uint256 prevValue = endTime;
            endTime = _endTime;
            emit SaleTimeUpdated(bytes32("END"), prevValue, _endTime);
        }
        return true;
    }

    modifier checkSaleState(uint256 _nftLevel, uint256 _num) {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            revert InvalidTime("Invalid time for buying");
        }
        if (_num == 0) revert ZeroBuyAmount();
        if (_nftLevel > NFTLevel) revert InvalidNFTLevel();
        if (
            _num >
            (nftDetails[_nftLevel].NFTToSell - nftDetails[_nftLevel].NFTSold)
        ) revert InsufficientQuantity();
        _;
    }

    function buyWithNative(
        uint256 _nftLevel,
        uint256 _num
    )
        external
        payable
        checkSaleState(_nftLevel, _num)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        return _buyWithNative(_msgSender(), _nftLevel, _num);
    }

    function _buyWithNative(
        address user,
        uint256 _nftLevel,
        uint256 _num
    ) internal returns (bool) {
        NFTDetails memory _nftDetails = nftDetails[_nftLevel];
        if (
            userNFTPurchase[_msgSender()][_nftLevel] + _num >
            _nftDetails.UserLimit
        ) revert MaxBuyLimitReached();
        uint256 nativePrice = (_nftDetails.price * _num);
        if (msg.value < nativePrice) revert InsufficientPayment();
        uint256 excess = msg.value - nativePrice;

        nftDetails[_nftLevel].NFTSold += _num;
        totalNFTSold += _num;

        sendValue(paymentWallet, nativePrice, address(0));
        if (excess > 0) sendValue(user, excess, address(0));

        uint256 _before = INFT(_nftDetails.NFTContract).tokenIdCounter();
        INFT(_nftDetails.NFTContract).batchMint(user, _num);
        userNFTPurchase[_msgSender()][_nftLevel] += _num;
        emit NFTPurchased(user, _nftLevel, _before, _before + _num - 1);
        return true;
    }

    function buyWithNativeWert(
        address _user,
        uint256 _nftLevel,
        uint256 _num
    )
        external
        payable
        checkSaleState(_nftLevel, _num)
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        if (!wertWhitelisted[_msgSender()]) revert UserNotWhitelisted();
        return _buyWithNative(_user, _nftLevel, _num);
    }

    function sendValue(
        address recipient,
        uint256 _price,
        address _paymentToken
    ) internal {
        if (_paymentToken == address(0)) {
            if (_price > address(this).balance) revert LowBalance();
            (bool success, ) = payable(recipient).call{value: _price}("");
            if (!success) revert NativeTokenPaymentFailed();
        } else {
            (bool response, ) = (_paymentToken).call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _msgSender(),
                    recipient,
                    _price
                )
            );
            if (!response) revert TokenPaymentFailed();
        }
    }

    function getNativeTokenLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = oracle.latestRoundData();
        price = (price * (10 ** 10));
        return uint256(price);
    }

    function buyWithUSDT(
        uint256 _nftLevel,
        uint256 _num
    ) external checkSaleState(_nftLevel, _num) whenNotPaused returns (bool) {
        NFTDetails memory _nftDetails = nftDetails[_nftLevel];
        if (
            userNFTPurchase[_msgSender()][_nftLevel] + _num >
            _nftDetails.UserLimit
        ) revert MaxBuyLimitReached();
        uint256 usdPrice = (getNativeTokenLatestPrice() *
            _nftDetails.price *
            _num) / (10 ** 12);
        nftDetails[_nftLevel].NFTSold += _num;
        totalNFTSold += _num;

        sendValue(paymentWallet, usdPrice / (10 ** 18), address(USDT));

        uint256 _before = INFT(_nftDetails.NFTContract).tokenIdCounter();
        INFT(_nftDetails.NFTContract).batchMint(_msgSender(), _num);
        userNFTPurchase[_msgSender()][_nftLevel] += _num;
        emit NFTPurchased(_msgSender(), _nftLevel, _before, _before + _num - 1);

        return true;
    }

    function fetchTAMAPrice(uint256 nativePrice) public view returns (uint256) {
        (uint256 sqrtPriceX96, , , , , , ) = pool.slot0();

        uint256 tamaPriceInETH = ((sqrtPriceX96 * 10 ** 9) / (2 ** 96)) ** 2;

        uint256 tamaPrice = (nativePrice * (10 ** 18)) / tamaPriceInETH;

        return tamaPrice;
    }

    function buyWithTAMA(
        uint256 _nftLevel,
        uint256 _num
    ) external checkSaleState(_nftLevel, _num) whenNotPaused returns (bool) {
        NFTDetails memory _nftDetails = nftDetails[_nftLevel];
        uint256 nativePrice = (_nftDetails.price * _num);
        uint256 tamaPrice = fetchTAMAPrice(nativePrice);

        nftDetails[_nftLevel].NFTSold += _num;
        totalNFTSold += _num;

        sendValue(tamaPaymentWallet, tamaPrice, address(TAMA));
        if (tamaPaymentWallet == address(this)) {
            IERC20(TAMA).burn(tamaPrice);
        }
        uint256 _before = INFT(_nftDetails.NFTContract).tokenIdCounter();
        INFT(_nftDetails.NFTContract).batchMint(_msgSender(), _num);

        emit NFTPurchased(_msgSender(), _nftLevel, _before, _before + _num - 1);

        return true;
    }

    function updateWhitelistStatusForWert(
        address[] calldata _addresses,
        bool[] calldata _status
    ) external onlyOwner {
        if (_addresses.length != _status.length) revert ArrayLengthMismatch();

        for (uint256 i; i < _addresses.length; ) {
            wertWhitelisted[_addresses[i]] = _status[i];
            unchecked {
                ++i;
            }
        }
    }

    function changePool(address _pool) public onlyOwner {
        pool = IPool(_pool);
    }

    function changeTamaAddress(address _tokenAddress) public onlyOwner {
        TAMA = _tokenAddress;
    }

    function setTokenPaymentWallet(
        address _tamaPaymentWallet
    ) public onlyOwner {
        tamaPaymentWallet = _tamaPaymentWallet;
    }

    function changePaymentWallet(address _paymentWallet) public onlyOwner {
        paymentWallet = _paymentWallet;
    }
}
