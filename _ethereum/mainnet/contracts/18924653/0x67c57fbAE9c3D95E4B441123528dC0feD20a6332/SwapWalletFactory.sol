// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./Initializable.sol";
import "./SwapWallet.sol";
import "./SwapWalletBeaconProxy.sol";




contract SwapWalletFactory is Initializable, ReentrancyGuardUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _owner;
    address private _pendingOwner;

    address public WETH;

    mapping(address => uint256) public whitelistAddressToIndex;
    address[] public whitelistAddresses;

    mapping(address => uint256) public walletToIndex;
    address[] public wallets;
    mapping(address => uint256) public walletOwnerToIndex;
    address[] public walletOwners;
    mapping(address => address) public walletOwnerToWallet;
    mapping(address => address) public walletToWalletOwner;

    mapping(address => mapping(address => mapping(address => uint256))) public whitelistPairToIndex;
    address[3][] public whitelistPairs;

    mapping(address => uint256) public applyGasTime;
    uint256 public applyGasLimit;
    uint256 public applyGasInterval;

    address private beaconAddress;

    address public curveFactory;

    address private _onchainlp;

    event SwapWalletCreated(address indexed wallet, address indexed walletOwner);
    event SwapWalletAdded(address indexed wallet, address indexed walletOwner);
    event SwapWalletDeleted(address indexed wallet, address indexed walletOwner);
    event SwapWalletUpdated(address indexed wallet, address indexed oldWalletOwner, address indexed newWalletOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);
    event WithdrawWhiteListAdded(address indexed addedAddress);
    event WithdrawWhiteListDeleted(address indexed deletedAddress);
    event PairWhiteListAdded(address indexed router, address indexed token0, address indexed token1);
    event PairWhiteListDeleted(address indexed router, address indexed token0, address indexed token1);
    event WithdrawHappened(address indexed assetAddress, uint256 amount, address indexed toAddress);
    event ApplyGasLimitUpdated(uint256 oldLimit, uint256 newLimit);
    event ApplyGasIntervalUpdated(uint256 oldInterval, uint256 newInterval);
    event BeaconAddressUpdated(address indexed previousImplementation, address indexed newImplementation);
    event CurveFactoryUpdated(address indexed previousFactory, address indexed newFactory);
    event OnchainLPSet(address indexed onchainlp);

    function initialize(address owner_, address WETH_, uint applyGasLimit_, uint applyGasInterval_) public initializer{
        __SwapWalletFactory_init(owner_, WETH_, applyGasLimit_, applyGasInterval_);
    }

    function __SwapWalletFactory_init(address owner_, address WETH_, uint applyGasLimit_, uint applyGasInterval_) internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
        __SwapWalletFactory_init_unchained(owner_, WETH_, applyGasLimit_, applyGasInterval_);
    }

    function __SwapWalletFactory_init_unchained(address owner_, address WETH_, uint applyGasLimit_, uint applyGasInterval_) internal onlyInitializing {
        require(owner_ != address(0), "SwapWalletFactory: owner is the zero address");
        require(WETH_ != address(0), "SwapWalletFactory: weth is the zero address");
        _owner = owner_;
        WETH = WETH_;
        applyGasLimit = applyGasLimit_;
        applyGasInterval = applyGasInterval_;
    }


    receive() external payable {
            // React to receiving ether
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function whitelistAddressesLength() external view returns (uint) {
        return whitelistAddresses.length;
    }

    function whitelistPairsLength() external view returns (uint) {
        return whitelistPairs.length;
    }

    function walletsLength() external view returns (uint) {
        return wallets.length;
    }

    function walletOwnersLength() external view returns (uint) {
        return walletOwners.length;
    }

    function onchainlp() external view returns (address) {
        return _onchainlp;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "SwapWalletFactory: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "SwapWalletFactory: new owner is the zero address");
        require(newOwner != _owner, "SwapWalletFactory: new owner is the same as the current owner");

        emit OwnershipTransferred(_owner, newOwner);
        _pendingOwner = newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == _pendingOwner, "SwapWalletFactory: invalid new owner");
        emit OwnershipAccepted(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }

    function createWallet(address walletOwner) external onlyOwner returns (address) {
        require(walletOwner != address(0), "SwapWalletFactory: wallet owner is the zero address");
        require(walletOwnerToIndex[walletOwner] == 0, "SwapWalletFactory: wallet owner already exists");
        SwapWallet wallet = SwapWallet(payable(new SwapWalletBeaconProxy(beaconAddress, "")));
        wallet.initialize(walletOwner, this);
        wallets.push(address(wallet));
        walletToIndex[address(wallet)] = wallets.length;
        walletOwners.push(walletOwner);
        walletOwnerToIndex[walletOwner] = walletOwners.length;
        walletOwnerToWallet[walletOwner] = address(wallet);
        walletToWalletOwner[address(wallet)] = walletOwner;
        emit SwapWalletCreated(address(wallet), walletOwner);
        return address(wallet);
    }

    function addWallet(address payable wallet, address walletOwner) external onlyOwner {
        require(walletOwner != address(0), "SwapWalletFactory: wallet owner is the zero address");
        require(wallet != address(0), "SwapWalletFactory: wallet is the zero address");
        require(walletToIndex[wallet] == 0, "SwapWalletFactory: wallet already exist");
        require(walletOwnerToIndex[walletOwner] == 0, "SwapWalletFactory: wallet owner already exist");
    
        SwapWallet walletContract = SwapWallet(wallet);
        require(walletContract.getFactory() == address(this), "SwapWalletFactory: wallet is not created from this factory");

        wallets.push(wallet);
        walletToIndex[wallet] = wallets.length;
        walletOwners.push(walletOwner);
        walletOwnerToIndex[walletOwner] = walletOwners.length;
        walletToWalletOwner[wallet] = walletOwner;
        walletOwnerToWallet[walletOwner] = wallet;
        emit SwapWalletAdded(address(wallet), walletOwner);
    }

    function  deleteWallet(address payable wallet) external onlyOwner {
        uint256 index = walletToIndex[wallet];
        require(index != 0, "SwapWalletFactory: wallet is not in the walletList");
        if (index != wallets.length) {
            wallets[index - 1] = wallets[wallets.length - 1];
            walletToIndex[wallets[index - 1]] = index;
        }
        wallets.pop();
        delete(walletToIndex[wallet]);
        address walletOwner = walletToWalletOwner[wallet];
        uint256 ownerIndex = walletOwnerToIndex[walletOwner];
        if (ownerIndex != walletOwners.length) {
            walletOwners[ownerIndex - 1] = walletOwners[walletOwners.length - 1];
            walletOwnerToIndex[walletOwners[ownerIndex - 1]] = ownerIndex;
        }
        walletOwners.pop();
        delete(walletOwnerToIndex[walletOwner]);
        delete(walletToWalletOwner[wallet]);
        delete(walletOwnerToWallet[walletOwner]);
        emit SwapWalletDeleted(wallet, walletOwner);
    }

    function updateWallet(address payable wallet, address newWalletOwner) external onlyOwner {
        require(newWalletOwner != address(0), "SwapWalletFactory: newWalletOwner is the zero address");
        require(walletOwnerToIndex[newWalletOwner] == 0, "SwapWalletFactory: newWalletOwner already exists");
        address oldWalletOwner = walletToWalletOwner[wallet];
        require(oldWalletOwner != address(0), "SwapWalletFactory: wallet doesn't exist");
        delete(walletOwnerToWallet[oldWalletOwner]);

        uint oldOwnerIndex = walletOwnerToIndex[oldWalletOwner];
        walletOwners[oldOwnerIndex - 1] = newWalletOwner;
        walletOwnerToIndex[newWalletOwner] = oldOwnerIndex;

        walletToWalletOwner[wallet] = newWalletOwner;
        walletOwnerToWallet[newWalletOwner] = wallet;
        emit SwapWalletUpdated(wallet, oldWalletOwner, newWalletOwner);
    }

    function addWithdrawWhitelist(address addressToAdd) external onlyOwner returns(uint256) {
        require(addressToAdd != address(0), "SwapWalletFactory: new address is the zero address");
        uint256 index = whitelistAddressToIndex[addressToAdd];
        require(index == 0, "SwapWalletFactory: address is already in the whitelist");
        whitelistAddresses.push(addressToAdd);
        whitelistAddressToIndex[addressToAdd] = whitelistAddresses.length;
        emit WithdrawWhiteListAdded(addressToAdd);
        return whitelistAddresses.length;
    }

    function deleteWithdrawWhitelist(address addressToDelete) external onlyOwner returns(uint256) {
        uint256 index = whitelistAddressToIndex[addressToDelete];
        require(index != 0, "SwapWalletFactory: address is not in the whitelist");
        if (index != whitelistAddresses.length) {
            whitelistAddresses[index - 1] = whitelistAddresses[whitelistAddresses.length - 1];
            whitelistAddressToIndex[whitelistAddresses[index - 1]] = index;
        }
        whitelistAddresses.pop();
        delete whitelistAddressToIndex[addressToDelete];
        emit WithdrawWhiteListDeleted(addressToDelete);
        return index;
    }

    function addPairWhitelist(address[3][] calldata pairs) external onlyOwner returns(uint256) {
        uint len = pairs.length;
        for(uint i; i < len; ++i) {
            address router = pairs[i][0];
            address tokenA = pairs[i][1];
            address tokenB = pairs[i][2];
            require(tokenA != tokenB, 'SwapWalletFactory: identical addresses');
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
            require(router != address(0), 'SwapWalletFactory: zero address');
            require(token0 != address(0), 'SwapWalletFactory: zero address');
            require(token1 != address(0), 'SwapWalletFactory: zero address');
            require(whitelistPairToIndex[router][token0][token1] == 0, 'SwapWalletFactory: pair exists'); // single check is sufficient
            
            whitelistPairs.push([router, token0, token1]);
            whitelistPairToIndex[router][token0][token1] = whitelistPairs.length;
            emit PairWhiteListAdded(router, token0, token1);
        }
       
        return whitelistPairs.length;
    }

    function deletePairWhitelist(address[3][] calldata pairs) external onlyOwner returns(uint256) {
        uint len = pairs.length;
        for(uint i; i < len; ++i) {
            address router = pairs[i][0];
            address tokenA = pairs[i][1];
            address tokenB = pairs[i][2];
            require(tokenA != tokenB, 'SwapWalletFactory: identical addresses');
            (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
            uint256 index = whitelistPairToIndex[router][token0][token1];
            require(index != 0, 'SwapWalletFactory: pair not exists'); // single check is sufficient
            
            if (index != whitelistPairs.length) {
                whitelistPairs[index - 1] = whitelistPairs[whitelistPairs.length - 1];
                address router_ =  whitelistPairs[index - 1][0];
                address token0_ =  whitelistPairs[index - 1][1];
                address token1_ =  whitelistPairs[index - 1][2];
                whitelistPairToIndex[router_][token0_][token1_] = index;
            }
            whitelistPairs.pop();
            delete whitelistPairToIndex[router][token0][token1];
            emit PairWhiteListDeleted(router, token0, token1);
        }
        return whitelistPairs.length;
    }

    function withdraw(address assetAddress_, uint256 amount_, address toAddress_) external nonReentrant {
        require(amount_ > 0, "SwapWalletFactory: ZERO_AMOUNT");
        bool isWhitelistAddress = whitelistAddressToIndex[toAddress_] > 0 || walletToIndex[toAddress_] > 0;
        require(isWhitelistAddress, "SwapWalletFactory: withdraw to non whitelist address");
        bool hasPermission = msg.sender == _owner || walletOwnerToWallet[msg.sender] != address(0);
        require(hasPermission, "SwapWalletFactory: withdraw no permission");
        if (assetAddress_ == address(0)) {
            address self = address(this);
            uint256 assetBalance = self.balance;
            require(assetBalance >= amount_, "SwapWalletFactory: not enough balance");
            _safeTransferETH(toAddress_, amount_);
            emit WithdrawHappened(assetAddress_, amount_, toAddress_);
        } else {
            uint256 assetBalance = IERC20Upgradeable(assetAddress_).balanceOf(address(this));
            require(assetBalance >= amount_, "SwapWalletFactory: not enough balance");
            IERC20Upgradeable(assetAddress_).safeTransfer(toAddress_, amount_);
            emit WithdrawHappened(assetAddress_, amount_, toAddress_);
        }
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "SwapWalletFactory: transfer eth failed");
    }

    function applyGas(uint256 amount_) external nonReentrant {
        require(walletOwnerToWallet[msg.sender] != address(0), "SwapWalletFactory: apply gas from non wallet owner");
        require(amount_ <= applyGasLimit, "SwapWalletFactory: apply gas limit");
        require(amount_ > 0, "SwapWalletFactory: ZERO_AMOUNT");
        uint256 lastApplyTime = applyGasTime[msg.sender];
        require(lastApplyTime == 0 || block.timestamp - lastApplyTime > applyGasInterval, "SwapWalletFactory: apply gas interval");
        address self = address(this);
        uint256 assetBalance = self.balance;
        if (assetBalance >= amount_) {
            applyGasTime[msg.sender] = block.timestamp;
            _safeTransferETH(msg.sender, amount_);
            emit WithdrawHappened(address(0), amount_, msg.sender);
        }
    }

    function setApplyGasLimit(uint256 applyGasLimit_) external onlyOwner {
        require(applyGasLimit_ <= 10000000000000000000, "SwapWalletFactory: TOO_LARGE");
        uint256 oldLimit = applyGasLimit;
        applyGasLimit = applyGasLimit_;
        emit ApplyGasLimitUpdated(oldLimit, applyGasLimit_);

    }

    function setApplyGasInterval(uint256 applyGasInterval_) external onlyOwner {
        require(applyGasInterval_ >= 3600, "SwapWalletFactory: TOO_SMALL");
        require(applyGasInterval_ <= 604800, "SwapWalletFactory: TOO_LARGE");
        uint256 oldInterval = applyGasInterval;
        applyGasInterval = applyGasInterval_;
        emit ApplyGasIntervalUpdated(oldInterval, applyGasInterval_);
    }

    function getBeaconAddress() external view returns (address) {
        return beaconAddress;
    }

    function setBeaconAddress(address newBeaconAddress) external onlyOwner {
        require(newBeaconAddress != address(0), "SwapWalletFactory: zero address");
        require(newBeaconAddress != beaconAddress, "SwapWalletFactory: same address");
        emit BeaconAddressUpdated(beaconAddress, newBeaconAddress);
        beaconAddress = newBeaconAddress;
    }

    function setCurveFactory(address factory) external onlyOwner {
        require(factory != address(0), "SwapWalletFactory: zero address");
        curveFactory = factory;
        emit CurveFactoryUpdated(curveFactory, factory);
    }

    function setOnchainLP(address onchainlp) external nonReentrant onlyOwner {
        _onchainlp = onchainlp;
        emit OnchainLPSet(_onchainlp);
    }

}