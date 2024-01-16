// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import "./Initializable.sol";
import "./CountersUpgradeable.sol";
import "./ReentrancyGuard.sol";
import "./TimersUpgradeable.sol";
import "./AfterInitializable.sol";
import "./Royalty.sol";
import "./AERC721.sol";

/**
 * @title Controller
 *
 */
contract Controller is
    Initializable,
    Royalty,
    AfterInitializable,
    ReentrancyGuard
{
    using TimersUpgradeable for TimersUpgradeable.Timestamp;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    event UpdateMpercentage(uint256 _mPercentage);

    CountersUpgradeable.Counter private _tokenIdCounter;

    address public platformFeeAddress;
    address public creatorFeeAddress;

    uint256 public price;
    // Percentage of mint revenue allocated to ours,defult 10%
    uint256 public mPercentage;
    AERC721 public tokenaddress;
    TimersUpgradeable.Timestamp public timer;
    uint256 public currenttokenTypeIndex;

    function initialize(
        address payable[] calldata recipients_,
        uint256[] calldata basisPoints_,
        uint256 price_,
        uint64 mintTime_
    ) external initializer {
        // __Royalty_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        platformFeeAddress = recipients_[0];
        creatorFeeAddress = recipients_[1];
        price = price_;
        //defult percentage 10%
        mPercentage = 10;

        // for secondary sale fee

        _setDefaultRoyalties(recipients_, basisPoints_);
        timer.setDeadline(mintTime_);
    }

    function afterInitialize(address tokenaddr)
        external
        afterInitializer
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenaddress = AERC721(tokenaddr);
        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
    }

    function _splitFundsETH() internal {
        if (msg.value > 0) {
            uint256 refund = msg.value - price;
            if (refund > 0) {
                address payable sender = payable(msg.sender);
                sender.transfer(refund);
            }
            uint256 foundationAmount = (price * mPercentage) / 100;
            if (foundationAmount > 0) {
                address payable paddress = payable(platformFeeAddress);
                paddress.transfer(foundationAmount);
            }
            uint256 creatorFunds = price - foundationAmount;
            if (creatorFunds > 0) {
                address payable caddress = payable(creatorFeeAddress);
                caddress.transfer(creatorFunds);
            }
        }
    }

    modifier mintCheck(TimersUpgradeable.Timestamp memory _timer) {
        require(
            _timer.isExpired(),
            "Controller::mintCheck: it's too early to mint"
        );
        require(
            address(platformFeeAddress) != address(0) &&
                address(creatorFeeAddress) != address(0),
            "Controller::mintCheck: platformFeeAddress or creatorFeeAddress should not be address(0)"
        );
        _;
    }

    function mint(address to, uint256 tokenId)
        external
        payable
        nonReentrant
        mintCheck(timer)
        returns (uint256)
    {
        require(msg.value == (price), "must send minimum value to mint");

        tokenaddress.mint(to, tokenId);
        _splitFundsETH();
        return tokenId;
    }

    /**
     * @notice Updates Art Blocks mint revenue percentage to
     * `_mPercentage`.
     */
    function updateMpercentage(uint256 _mPercentage)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_mPercentage <= 25, "max of 25%");
        mPercentage = _mPercentage;
        emit UpdateMpercentage(_mPercentage);
    }
}
