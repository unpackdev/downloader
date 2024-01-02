pragma solidity =0.8.7;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./TransferHelper.sol";
import "./IDropV2.sol";

contract Drop is IDropV2, AccessControl, ReentrancyGuard, Initializable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant PRICE_MULTIPLE = 1E8;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IERC20 public constant TOKEN = IERC20(address(0));

    struct TokenInfo {
        uint256 maxAmount;
        uint256 minAmountEachDeposit;
        uint256 maxAmountEachDeposit;
        uint256 amount;
        uint256 usdAmount;
        uint256 usdPrice;
        uint256 tokenPowerPrice;
    }

    // The block number when Drop starts
    uint256 public startTime;
    // The block number when white list drop timeout
    uint256 public whiteListTimeOutTime;
    // The block number when Drop ends
    uint256 public endTime;
    uint256 public maxTotalDropUSDAmount;
    uint256 public currentTotalDropUSDAmount;
    uint256 public maxDropUSDAmountEachUser;
    address public finAddr;
    // address => amount
    mapping(address => uint256) public userInfoMap;
    // tokenAddress => info
    mapping(address => TokenInfo) public tokenInfoMap;
    // participators
    address[] public addresses;
    EnumerableSet.AddressSet private _whiteList;

    constructor() public {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Ownable: caller is not the owner');
        _;
    }

    function initialize(
        uint256 _startTime,
        uint256 _whiteListTimeOutTime,
        uint256 _endTime,
        uint256 _maxTotalDropUSDAmount,
        uint256 _maxDropUSDAmountEachUser,
        address _finAddr,
        address _ownerAddress
    ) external override initializer onlyOwner {
        startTime = _startTime;
        whiteListTimeOutTime = _whiteListTimeOutTime;
        endTime = _endTime;
        maxTotalDropUSDAmount = _maxTotalDropUSDAmount;
        maxDropUSDAmountEachUser = _maxDropUSDAmountEachUser;
        finAddr = _finAddr;
        emit FinAddressTransferred(address(0), finAddr);
        if (_ownerAddress != address(0)) {
            transferOwnership(_ownerAddress);
        }
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        if (newOwner != _msgSender()) {
            _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
            _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        }
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        startTime = _startTime;
    }

    function setWhiteListTimeOutTime(uint256 _whiteListTimeOutTime) public onlyOwner {
        whiteListTimeOutTime = _whiteListTimeOutTime;
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        endTime = _endTime;
    }

    function setMaxTotalDropUSDAmount(uint256 _maxTotalDropUSDAmount) public onlyOwner {
        maxTotalDropUSDAmount = _maxTotalDropUSDAmount;
    }

    function setMaxDropUSDAmountEachUser(uint256 _maxDropUSDAmountEachUser) public onlyOwner {
        maxDropUSDAmountEachUser = _maxDropUSDAmountEachUser;
    }

    function setTokenInfo(
        address _token,
        uint256 _maxAmount,
        uint256 _minAmountEachDeposit,
        uint256 _maxAmountEachDeposit,
        uint256 _usdPrice,
        uint256 _tokenPowerPrice
    ) external override onlyOwner {
        TokenInfo storage tokenInfo = tokenInfoMap[_token];
        if (tokenInfo.maxAmount != _maxAmount) {
            tokenInfo.maxAmount = _maxAmount;
        }
        if (tokenInfo.minAmountEachDeposit != _minAmountEachDeposit) {
            tokenInfo.minAmountEachDeposit = _minAmountEachDeposit;
        }
        if (tokenInfo.maxAmountEachDeposit != _maxAmountEachDeposit) {
            tokenInfo.maxAmountEachDeposit = _maxAmountEachDeposit;
        }
        if (tokenInfo.usdPrice != _usdPrice) {
            tokenInfo.usdPrice = _usdPrice;
        }
        if (tokenInfo.tokenPowerPrice != _tokenPowerPrice) {
            tokenInfo.tokenPowerPrice = _tokenPowerPrice;
        }
        emit SetTokenInfo(_token, _maxAmount, _minAmountEachDeposit, _maxAmountEachDeposit, _usdPrice, _tokenPowerPrice);
    }

    function addToWhiteList(address _address) public onlyOwner {
        _whiteList.add(_address);
    }

    function removeFromWhiteList(address _address) public onlyOwner {
        _whiteList.remove(_address);
    }

    function addAllToWhiteList(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addToWhiteList(_addresses[i]);
        }
    }

    function removeAllFromWhiteList(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            removeFromWhiteList(_addresses[i]);
        }
    }

    function whiteList() public view override returns (address[] memory _addresses) {
        _addresses = new address[](_whiteList.length());
        for (uint256 i = 0; i < _whiteList.length(); ++i) {
            _addresses[i] = _whiteList.at(i);
        }
    }

    function _deposit(address _token, uint256 _amount) internal virtual returns (uint256 amount) {
        require(_amount > 0, 'need _amount > 0');
        TokenInfo storage tokenInfo = tokenInfoMap[_token];
        require(tokenInfo.usdPrice != 0, 'Drop NOT SUPPORT THIS TOKEN');
        uint256 maxDropUSDAmount = maxTotalDropUSDAmount.sub(currentTotalDropUSDAmount);
        require(maxDropUSDAmount != 0, 'Drop IS STOP');
        uint256 maxDropAmount = tokenInfo.maxAmount.sub(tokenInfo.amount);
        require(maxDropAmount != 0, 'Token STOP');
        if (block.timestamp > whiteListTimeOutTime && tokenInfo.tokenPowerPrice != 0 && address(TOKEN) != address(0)) {
            uint256 maxDropAmountByTokenPower = TOKEN.balanceOf(_msgSender()).mul(PRICE_MULTIPLE).div(
                tokenInfo.tokenPowerPrice
            );
            maxDropAmount = maxDropAmountByTokenPower > maxDropAmount ? maxDropAmount : maxDropAmountByTokenPower;
            require(maxDropAmount != 0, 'Not Token');
        }
        maxDropAmount = tokenInfo.maxAmountEachDeposit > maxDropAmount ? maxDropAmount : tokenInfo.maxAmountEachDeposit;
        uint256 userRemainDropUSDAmount = maxDropUSDAmountEachUser.sub(userInfoMap[_msgSender()]);
        maxDropUSDAmount = userRemainDropUSDAmount > maxDropUSDAmount ? maxDropUSDAmount : userRemainDropUSDAmount;
        require(maxDropUSDAmount != 0, 'User STOP');

        _amount = maxDropAmount > _amount ? _amount : maxDropAmount;
        uint256 usdAmount = _amount.mul(tokenInfo.usdPrice).div(PRICE_MULTIPLE);

        if (usdAmount > maxDropUSDAmount) {
            usdAmount = maxDropUSDAmount;
            amount = usdAmount.mul(PRICE_MULTIPLE).div(tokenInfo.usdPrice);
        } else {
            amount = _amount;
            if (userInfoMap[_msgSender()] == 0) {
                require(amount >= tokenInfo.minAmountEachDeposit, 'MIN Drop AMOUNT');
            }
        }
        currentTotalDropUSDAmount = currentTotalDropUSDAmount.add(usdAmount);
        tokenInfo.usdAmount = tokenInfo.usdAmount.add(usdAmount);
        tokenInfo.amount = tokenInfo.amount.add(amount);
        if (userInfoMap[_msgSender()] == 0) {
            addresses.push(_msgSender());
        }
        userInfoMap[_msgSender()] = userInfoMap[_msgSender()].add(usdAmount);
        if (currentTotalDropUSDAmount >= maxTotalDropUSDAmount) {
            endTime = block.timestamp;
        }
        emit Deposit(_token, _msgSender(), amount, usdAmount);
    }

    function getRemainDropAmount(address _token, address _user) external view override returns (uint256) {
        if (block.timestamp >= startTime && block.timestamp <= whiteListTimeOutTime && !_whiteList.contains(_user)) {
            return 0;
        }
        TokenInfo memory tokenInfo = tokenInfoMap[_token];
        if (tokenInfo.usdPrice == 0) {
            return 0;
        }
        uint256 maxDropUSDAmount = maxTotalDropUSDAmount.sub(currentTotalDropUSDAmount);
        if (maxDropUSDAmount == 0) {
            return 0;
        }
        uint256 maxDropAmount = tokenInfo.maxAmount.sub(tokenInfo.amount);
        if (maxDropAmount == 0) {
            return 0;
        }
        if ((!_whiteList.contains(_user) || block.timestamp > whiteListTimeOutTime) && tokenInfo.tokenPowerPrice != 0) {
            uint256 maxDropAmountByTokenPower = TOKEN.balanceOf(_msgSender()).mul(PRICE_MULTIPLE).div(
                tokenInfo.tokenPowerPrice
            );
            maxDropAmount = maxDropAmountByTokenPower > maxDropAmount ? maxDropAmount : maxDropAmountByTokenPower;
            if (maxDropAmount == 0) {
                return 0;
            }
        }
        maxDropAmount = tokenInfo.maxAmountEachDeposit > maxDropAmount ? maxDropAmount : tokenInfo.maxAmountEachDeposit;
        uint256 userRemainDropUSDAmount = maxDropUSDAmountEachUser.sub(userInfoMap[_user]);
        maxDropUSDAmount = userRemainDropUSDAmount > maxDropUSDAmount ? maxDropUSDAmount : userRemainDropUSDAmount;
        if (maxDropUSDAmount == 0) {
            return 0;
        }
        uint256 amount = maxDropUSDAmount.mul(PRICE_MULTIPLE).div(tokenInfo.usdPrice);
        return maxDropAmount > amount ? amount : maxDropAmount;
    }

    function deposit(address _token, uint256 _amount)
    external
    payable
    override
    nonReentrant
    returns (uint256 amount, uint256 ethAmount)
    {
        require(block.timestamp >= startTime, 'not Drop time');
        require(endTime == 0 || block.timestamp <= endTime, 'not Drop time');
        require(block.timestamp > whiteListTimeOutTime || _whiteList.contains(_msgSender()), 'Drop white list time');
        if ((address(0)) != _token) {
            amount = _deposit(_token, _amount);
            IERC20(_token).safeTransferFrom(address(_msgSender()), finAddr, amount);
        }
        if (msg.value != 0) {
            ethAmount = _deposit(WETH, msg.value);
            TransferHelper.safeTransferETH(finAddr, ethAmount);
            if (msg.value > ethAmount) TransferHelper.safeTransferETH(_msgSender(), msg.value - ethAmount);
        }
    }

    function transferDropFinAddress(address _finAddr) external override {
        require(_msgSender() == finAddr, ' FORBIDDEN');
        finAddr = _finAddr;
        emit FinAddressTransferred(_msgSender(), finAddr);
    }

    function getAddressesLength() external view returns (uint256) {
        return addresses.length;
    }

    function getAddresses() public view returns (address[] memory) {
        return addresses;
    }

    function emergencyWithdrawEther() public onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function emergencyWithdrawErc20(address tokenAddress) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }
}
