// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// unused imports; required for a forced contract compilation
import "./TransparentUpgradeableProxy.sol";
import "./ProxyAdmin.sol";

import "./IERC20.sol";
import "./Initializable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";

import "./ERC20Interface.sol";
import "./IOpyn.sol";

import "./IOpeth.sol";
import "./OP20.sol";

/**
 * @title Opeth coins based on Opyn oTokens
 * @notice Contract that let's one enter tokenized hedged positions
 */
contract Opeth is Initializable, ReentrancyGuard, IOpeth {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    uint internal constant OTOKEN_PRECISION = 8;
    uint constant FEE_PRECISION = 10000;

    AddressBookInterface immutable addressBook;
    ControllerInterface immutable controller;

    uint mintFee;
    address governance;
    address feeSink;
    bool flashMintAllowed;

    /// @dev Metadata for a whitelisted oToken
    struct OP20MetaData {
        IERC20 underlyingAsset;
        IERC20 collateralAsset;
        OP20 op20;
        uint underlyingDecimals;
        uint unitPayout;
        bool proceedsClaimed;
    }

    /// @dev oToken => MetaData
    mapping(address => OP20MetaData) public op20s;

    uint[20] private _gap;

    /// Events
    event OtokenWhitelisted(address oToken, address op20);
    event ClaimedProceeds(address oToken);
    event Mint(address oToken, uint amount, address destination);
    event Redeem(address oToken, uint amount, address source);
    event EmergencyRedeem(address oToken, uint amount, address source);

    constructor(AddressBookInterface _addressBook) public {
        controller = ControllerInterface(_addressBook.getController());
        addressBook = _addressBook;
    }

    function init(address _feeSink, address _governance) initializer external {
        _setGovernance(_governance);
        _setConfig(_feeSink, 0, false);
    }

    function mint(address oToken, uint amount) external {
        mintFor(msg.sender, oToken, amount);
    }

    /**
     * @notice Mint Opeth tokens. Pulls oToken and underlying asset from msg.sender
     * @param amount Amount of Opeth to mint. Scaled by 10**OTOKEN_PRECISION = 1e8
     */
    function mintFor(address destination, address oToken, uint amount) override public {
        OP20MetaData memory _op = op20s[oToken];

        // will revert if unsupported oToken is passed
        _op.underlyingAsset.safeTransferFrom(
            msg.sender,
            address(this),
            _oTokenToUnderlyingQuantity(_op.underlyingDecimals, amount)
        );
        IERC20(oToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        _mint(_op, destination, oToken, amount);
    }

    function flashMint(address receiver, address oToken, uint amount, bytes memory params) override external nonReentrant {
        require(flashMintAllowed, "FLASH_MINT_NOT_ALLOWED");

        OP20MetaData memory _op = op20s[oToken];

        // someone could have sent oTokens to the contract. Exclude those.
        uint _oTokenBefore = IERC20(oToken).balanceOf(address(this));

        // underlying asset across several opeth tokens would be same.
        uint _underlyingBefore = _op.underlyingAsset.balanceOf(address(this));

        _mint(_op, receiver, oToken, amount);
        IReceiver(receiver).executeOperation(oToken, amount, params);

        require(IERC20(oToken).balanceOf(address(this)).sub(_oTokenBefore) == amount, "OTOKEN_VALIDATION_FAILED");
        require(_op.underlyingAsset.balanceOf(address(this)).sub(_underlyingBefore) == _oTokenToUnderlyingQuantity(_op.underlyingDecimals, amount), "UNDERLYING_ASSET_VALIDATION_FAILED");
    }

    function _mint(OP20MetaData memory _op, address destination, address oToken, uint amount) internal {
        // since new op20s are being minted, we'll need to reset the flag, so that proceeds can be claimed again
        if (_op.proceedsClaimed) {
            op20s[oToken].proceedsClaimed = false; // since _op is a memory variable, write to storage directly
        }
        if (mintFee > 0) {
            uint fee = amount.mul(mintFee).div(FEE_PRECISION);
            _op.op20.mint(feeSink, fee);
            amount = amount.sub(fee);
        }
        _op.op20.mint(destination, amount);
        emit Mint(oToken, amount, destination);
    }

    /**
     * @notice redeem Opeth tokens
     * @param amount Amount of Opeth to redeem
     */
    function redeem(address oToken, uint amount) external {
        OP20MetaData storage _op = op20s[oToken];
        if (_op.proceedsClaimed) {
            _processPayout(_op.collateralAsset, _op.unitPayout, amount);
        } else if (isSettlementAllowed(oToken)) {
            claimProceeds(oToken);
            _processPayout(_op.collateralAsset, _op.unitPayout, amount);
        } else {
            // send back vanilla OTokens, because it is not yet time for settlement
            IERC20(oToken).safeTransfer(
                msg.sender,
                amount
            );
        }

        // will revert if unsupported oToken is passed
        _op.op20.burn(msg.sender, amount);

        _op.underlyingAsset.safeTransfer(
            msg.sender,
            _oTokenToUnderlyingQuantity(_op.underlyingDecimals, amount)
        );
        emit Redeem(oToken, amount, msg.sender);
    }

    function emergencyRedeem(address oToken) external {
        OP20MetaData memory _op = op20s[oToken];
        // will revert if unsupported oToken is passed
        uint amount = _op.op20.balanceOf(msg.sender);
        _op.op20.burn(msg.sender, amount);

        _op.underlyingAsset.safeTransfer(
            msg.sender,
            _oTokenToUnderlyingQuantity(_op.underlyingDecimals, amount)
        );
        emit EmergencyRedeem(oToken, amount, msg.sender);
    }

    /**
     * @notice Redeem OTokens for payout, if any
     */
    function claimProceeds(address oToken) public nonReentrant {
        OP20MetaData storage _op = op20s[oToken];
        require(address(_op.op20) != address(0), "OTOKEN_NOT_WHITELISTED");

        Actions.ActionArgs[] memory _actions = new Actions.ActionArgs[](1);
        _actions[0].actionType = Actions.ActionType.Redeem;
        _actions[0].secondAddress = address(this);
        _actions[0].asset = oToken;
        _actions[0].amount = IERC20(oToken).balanceOf(address(this));

        controller.operate(_actions);

        _op.unitPayout = MarginCalculatorInterface(addressBook.getMarginCalculator()).getExpiredPayoutRate(oToken);
        _op.proceedsClaimed = true;
        emit ClaimedProceeds(oToken);
    }

    function isSettlementAllowed(address oToken) public view virtual returns (bool) {
        return controller.isSettlementAllowed(oToken);
    }

    function getOpethDetails(address oToken, uint _oTokenAmount) override external view returns(address, address, uint) {
        OP20MetaData memory _op = op20s[oToken];
        require(address(_op.op20) != address(0), "OTOKEN_NOT_WHITELISTED");
        return (address(_op.underlyingAsset), address(_op.op20), _oTokenToUnderlyingQuantity(_op.underlyingDecimals, _oTokenAmount));
    }

    function vars() external view
        returns(
            address _addressBook,
            address _controller,
            address _governance,
            address _feeSink,
            uint _mintFee,
            bool _flashMintAllowed
        )
    {
        return (
            address(addressBook),
            address(controller),
            address(governance),
            address(feeSink),
            mintFee,
            flashMintAllowed
        );
    }

    /** Internal */

    /**
     * @notice Opeth to underlying asset amount
     * @dev _underlyingDecimals >= OTOKEN_PRECISION was asserted during spawn
     * @param amount Amount of Opeth to determine underlying asset amount for
     */
    function _oTokenToUnderlyingQuantity(uint _decimals, uint amount)
        internal
        pure
        returns (uint)
    {
        if (_decimals > OTOKEN_PRECISION) {
            return amount.mul(10 ** (_decimals - OTOKEN_PRECISION));
        }
        return amount;
    }

    /**
     * @notice Process collateralAsset payout
     * @param amount Amount of oTokens to process payout for.
     */
    function _processPayout(IERC20 _collateralAsset, uint _unitPayout, uint amount) internal {
        uint payout = _unitPayout.mul(amount).div(10**OTOKEN_PRECISION);
        if (payout > 0) {
            _collateralAsset.safeTransfer(msg.sender, payout);
        }
    }

    /**
    * @dev Required for testing in a mock contract
    */
    function _isNotExpired(uint _expiryTimestamp) virtual internal view returns(bool) {
        return now < _expiryTimestamp;
    }

    /** Governance */

    modifier onlyGovernance() {
        require(msg.sender == governance, "ONLY_GOVERNANCE");
        _;
    }

    /**
    * @param _oToken oToken contract address
    * @param _name OP20 token name
    * @param _symbol OP20 token symbol
    */
    function spawn(
        OtokenInterface _oToken,
        string memory _name,
        string memory _symbol
    )
        external
        onlyGovernance
    {
        (
            address _collateralAsset,
            address _underlyingAsset,
            /* address _strikeAsset */,
            /* uint _strikePrice */,
            uint _expiryTimestamp,
            bool isPut
        ) = _oToken.getOtokenDetails();
        require(_isNotExpired(_expiryTimestamp), "OTOKEN_EXPIRED");
        require(isPut, "NOT_PUT");
        uint _underlyingDecimals = uint(ERC20Interface(_underlyingAsset).decimals());
        require(_underlyingDecimals >= OTOKEN_PRECISION, "ASSET_INCOMPATIBLE");
        OP20 op20 = new OP20(address(_oToken), _name, _symbol);
        op20s[address(_oToken)] = OP20MetaData(IERC20(_underlyingAsset), IERC20(_collateralAsset), op20, _underlyingDecimals, 0, false);
        emit OtokenWhitelisted(address(_oToken), address(op20));
    }

    function setGovernance(address _governance) external onlyGovernance {
        _setGovernance(_governance);
    }

    function _setGovernance(address _governance) internal {
        require(_governance != address(0), "NULL_ADDRESS");
        governance = _governance;
    }

    function setConfig(address _feeSink, uint _mintFee, bool _flashMintAllowed) external onlyGovernance {
        _setConfig(_feeSink, _mintFee, _flashMintAllowed);
    }

    function _setConfig(address _feeSink, uint _mintFee, bool _flashMintAllowed) internal {
        require(_feeSink != address(0), "NULL_ADDRESS");
        require(_mintFee <= FEE_PRECISION, "INVALID_FEE");
        feeSink = _feeSink;
        mintFee = _mintFee;
        flashMintAllowed = _flashMintAllowed;
    }
}

interface IReceiver {
    function executeOperation(address oToken, uint amount, bytes memory params) external;
}
