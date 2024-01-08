// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./GenSymbol.sol";

import "./IOilerCollateral.sol";

import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./ERC20PermitUpgradeable.sol";

abstract contract OilerOption is ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PermitUpgradeable {
    using SafeMath for uint256;

    event Created(address indexed _optionAddress, string _symbol);
    event Exercised(uint256 _value);

    uint256 private constant MAX_UINT256 = type(uint256).max;

    // Added compatibility function below:
    function holderBalances(address holder_) public view returns (uint256) {
        return balanceOf(holder_);
    }

    mapping(address => uint256) public writerBalances;
    mapping(address => mapping(address => uint256)) public allowed;

    // OilerOption variables
    uint256 public startTS;
    uint256 public startBlock;
    uint256 public strikePrice;
    uint256 public expiryTS;
    bool public put; // put if true, call if false
    bool public exercised = false;

    IERC20 public collateralInstance;

    // Writes an option, locking the collateral
    function write(uint256 _amount) external {
        _write(_amount, msg.sender, msg.sender);
    }

    function write(uint256 _amount, address _writer) external {
        _write(_amount, _writer, _writer);
    }

    function write(
        uint256 _amount,
        address _writer,
        address _holder
    ) external {
        _write(_amount, _writer, _holder);
    }

    // Check if option's Expiration date has already passed
    function isAfterExpirationDate() public view returns (bool expired) {
        return (expiryTS <= block.timestamp);
    }

    function withdraw(uint256 _amount) external {
        if (isActive()) {
            // If the option is still Active - one can only release options that he wrote and still holds
            writerBalances[msg.sender] = writerBalances[msg.sender].sub(
                _amount,
                "Option.withdraw: Release amount exceeds options written"
            );
            _burn(msg.sender, _amount);
        } else {
            if (hasBeenExercised()) {
                // If the option was exercised - only holders can withdraw the collateral
                _burn(msg.sender, _amount);
            } else {
                // If the option wasn't exercised, but it's not active - this means it expired - and only writers can withdraw the collateral
                writerBalances[msg.sender] = writerBalances[msg.sender].sub(
                    _amount,
                    "Option.withdraw: Withdraw amount exceeds options written"
                );
            }
        }
        // If none of the above failed - then we succesfully withdrew the amount and we're good to burn tokens and release the collateral
        bool success = collateralInstance.transfer(msg.sender, _amount);
        require(success, "Option.withdraw: collateral transfer failed");
    }

    // Get withdrawable collateral
    function getWithdrawable(address _owner) external view returns (uint256 amount) {
        if (isActive()) {
            // If the option is still Active - one can only withdraw options that he wrote and still holds
            return min(holderBalances(_owner), writerBalances[_owner]);
        } else {
            if (hasBeenExercised()) {
                // If the option was exercised - only holders can withdraw the collateral
                return holderBalances(_owner);
            } else {
                // If the option wasn't exercised, but it's not active - this means it expired - and only writers can withdraw the collateral
                return writerBalances[_owner];
            }
        }
    }

    // Get amount of collateral locked in options
    function getLocked(address _address) external view returns (uint256 amount) {
        if (isActive()) {
            return writerBalances[_address];
        } else {
            return 0;
        }
    }

    function name() public view virtual override returns (string memory) {}

    // Option is Active (can still be written or exercised) - if it hasn't expired nor hasn't been exercised.
    // Option is not Active (and the collateral can be withdrawn) - if it has expired or has been exercised.
    function isActive() public view returns (bool active) {
        return (!isAfterExpirationDate() && !hasBeenExercised());
    }

    // Option is Expired if its Expiration Date has already passed and it wasn't exercised
    function hasExpired() public view returns (bool) {
        return isAfterExpirationDate() && !hasBeenExercised();
    }

    // Additional getter to make it more readable
    function hasBeenExercised() public view returns (bool) {
        return exercised;
    }

    function optionType() external view virtual returns (string memory) {}

    function _init(
        uint256 _strikePrice,
        uint256 _expiryTS,
        bool _put,
        address _collateralAddress
    ) internal initializer {
        startTS = block.timestamp;
        require(_expiryTS > startTS, "OilerOptionBase.init: expiry TS must be above start TS");
        expiryTS = _expiryTS;
        startBlock = block.number;
        strikePrice = _strikePrice;
        put = _put;
        string memory _symbol = GenSymbol.genOptionSymbol(_expiryTS, this.optionType(), _put, _strikePrice);

        __Context_init_unchained();
        __ERC20_init_unchained(this.name(), _symbol);
        __ERC20Burnable_init_unchained();
        __EIP712_init_unchained(this.name(), "1");
        __ERC20Permit_init_unchained(this.name());

        collateralInstance = IOilerCollateral(_collateralAddress);
        _setupDecimals(IOilerCollateral(_collateralAddress).decimals());
        emit Created(address(this), this.symbol());
    }

    function _write(
        uint256 _amount,
        address _writer,
        address _holder
    ) internal {
        require(isActive(), "Option.write: not active, cannot mint");
        _mint(_holder, _amount);
        writerBalances[_writer] = writerBalances[_writer].add(_amount);
        bool success = collateralInstance.transferFrom(msg.sender, address(this), _amount);
        require(success, "Option.write: collateral transfer failed");
    }

    function _exercise(uint256 price) internal {
        // (from vanilla option lingo) if it is a PUT then I can sell it at a higher (strike) price than the current price - I have a right to PUT it on the market
        // (from vanilla option lingo) if it is a CALL then I can buy it at a lower (strike) price than the current price - I have a right to CALL it from the market
        if ((put && strikePrice >= price) || (!put && strikePrice <= price)) {
            exercised = true;
            emit Exercised(price);
        } else {
            revert("Option.exercise: exercise conditions aren't met");
        }
    }

    /// @dev Returns the smallest of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
