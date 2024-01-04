// File contracts/interfaces/IChainLinkOracle.sol

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IChainLinkOracle {
    function latestAnswer() external view returns (uint256);
}


// File contracts/interfaces/IKeeperOracle.sol

pragma solidity ^0.8.0;

interface IKeeperOracle {
    function current(address, uint, address) external view returns (uint);
    function pairFor(address, address) external view returns (address);
    function pairs() external view returns (address[] memory);
}


// File contracts/ERC20/IERC20.sol

pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}


// File contracts/utils/Initializable.sol

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}


// File contracts/utils/Ownable.sol

pragma solidity ^0.8.0;
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author crypto-pumpkin
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Ruler: Initializes the contract setting the deployer as the initial owner.
     */
    function initializeOwner() internal initializer {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File contracts/Oracle.sol

pragma solidity ^0.8.0;
contract Oracle is Ownable {
    mapping(address => address) public assetsUSD;
    mapping(address => address) public assetsETH;

    address constant public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IKeeperOracle public keeperOracle = IKeeperOracle(0xf67Ab1c914deE06Ba0F264031885Ea7B276a7cDa);

    constructor () {
        assetsUSD[weth] = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // WETH
        assetsUSD[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // wBTC
        assetsUSD[0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D] = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c; // renBTC
        assetsUSD[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 0xAed0c38402a5d19df6E4c03F4E2DceD6e29c1ee9; // DAI
        assetsUSD[0x514910771AF9Ca656af840dff83E8264EcF986CA] = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c; // LINK
        assetsUSD[0x408e41876cCCDC0F92210600ef50372656052a38] = 0x0f59666EDE214281e956cb3b2D0d69415AfF4A01; // REN
        assetsUSD[0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F] = 0xDC3EA94CD0AC27d9A86C180091e7f78C683d3699; // SNX
        assetsUSD[0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9] = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9; // AAVE

        assetsETH[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = 0xdeb288F737066589598e9214E782fa5A8eD689e8; // wBTC
        assetsETH[0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D] = 0xdeb288F737066589598e9214E782fa5A8eD689e8; // renBTC
        assetsETH[0x6B175474E89094C44Da98b954EedeAC495271d0F] = 0x773616E4d11A78F511299002da57A0a94577F1f4; // DAI
        assetsETH[0x514910771AF9Ca656af840dff83E8264EcF986CA] = 0xDC530D9457755926550b59e8ECcdaE7624181557; // LINK
        assetsETH[0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2] = 0x24551a8Fb2A7211A25a17B1481f043A8a8adC7f2; // MKR
        assetsETH[0x408e41876cCCDC0F92210600ef50372656052a38] = 0x3147D7203354Dc06D9fd350c7a2437bcA92387a4; // REN
        assetsETH[0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F] = 0x79291A9d692Df95334B1a0B3B4AE6bC606782f8c; // SNX
        assetsETH[0x57Ab1ec28D129707052df4dF418D58a2D46d5f51] = 0x8e0b7e6062272B5eF4524250bFFF8e5Bd3497757; // SUSD
        assetsETH[0x0000000000085d4780B73119b644AE5ecd22b376] = 0x3886BA987236181D98F2401c507Fb8BeA7871dF2; // TUSD
        assetsETH[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4; // USDC
        assetsETH[0xdAC17F958D2ee523a2206206994597C13D831ec7] = 0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46; // USDT
        assetsETH[0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e] = 0xB7B1C8F4095D819BDAE25e7a63393CDF21fd02Ea; // YFI
        assetsETH[0x6B3595068778DD592e39A122f4f5a5cF09C90fE2] = 0xe572CeF69f43c2E488b33924AF04BDacE19079cf; // SUSHI
        assetsETH[0xD533a949740bb3306d119CC777fa900bA034cd52] = 0x8a12Be339B0cD1829b91Adc01977caa5E9ac121e; // CRV
    }

    /// @notice Returns price in USD multiplied by 1e8
    function getPriceUSD(address _asset) external view returns (uint256) {
        uint256 _price = 0;
        if (assetsUSD[_asset] != address(0)) {
            _price = IChainLinkOracle(assetsUSD[_asset]).latestAnswer();
        } else if (assetsETH[_asset] != address(0)) {
            _price = IChainLinkOracle(assetsETH[_asset]).latestAnswer();
            _price = _price * IChainLinkOracle(assetsUSD[weth]).latestAnswer() / 1e18;
        } else {
            address pair = keeperOracle.pairFor(_asset, weth);
            address[] memory pairs = keeperOracle.pairs();
            for (uint i = 0; i < pairs.length; i++) {
                if (pairs[i] == pair) {
                    _price = keeperOracle.current(_asset, 10 ** IERC20(_asset).decimals(), weth);
                    _price = _price * IChainLinkOracle(assetsUSD[weth]).latestAnswer() / 1e18;
                    break;
                }
            }
        }
        return _price;
    }

    function addFeedETH(address _asset, address _feed) external onlyOwner {
        assetsETH[_asset] = _feed;
    }
    
    function addFeedUSD(address _asset, address _feed) external onlyOwner {
        assetsUSD[_asset] = _feed;
    }
    
    function removeFeedETH(address _asset) external onlyOwner {
        assetsETH[_asset] = address(0);
    }
    
    function removeFeedUSD(address _asset) external onlyOwner {
        assetsUSD[_asset] = address(0);
    }

    function setKeeperOracle(IKeeperOracle _oracle) external onlyOwner {
        keeperOracle = _oracle;
    }
}