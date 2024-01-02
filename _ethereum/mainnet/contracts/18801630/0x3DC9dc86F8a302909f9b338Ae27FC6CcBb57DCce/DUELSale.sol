// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.20;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";

interface IVesting {
    function allocateDUEL(address, uint256) external;

    function allocateDUEL(address, uint256, uint256) external;

    function claimDUEL() external;
}

/// @title Main DUEL token ICO contract
/// @author Haider
contract DUELSale is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public usdtToken;
    IERC20 public duelToken;
    uint256 public constant maxSupply = 500_000_000 * (10 ** 18);
    uint256 public tokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public constant rateFactor = 3; // 3/1000 = $0.003
    address public _privateSaleVesting;
    mapping(address => bool) public referrers;

    event TokensPurchase(
        address indexed buyer,
        uint256 usdtAmount,
        uint256 duelAmount,
        address indexed referrer
    );

    modifier afterICO() {
        require(block.timestamp > endTime, "Sale is still active");
        _;
    }

    constructor(
        address _usdtToken,
        address _duelToken,
        uint256 _startTime,
        uint256 _durationInDays
    ) Ownable(msg.sender) {
        usdtToken = IERC20(_usdtToken);
        duelToken = IERC20(_duelToken);
        startTime = _startTime;
        endTime = _startTime + _durationInDays * 1 days;

        // By default allow address(0) as referrer
        referrers[address(0)] = true;
    }

    function setVestingContract(address staticVesting) external onlyOwner {
        _privateSaleVesting = staticVesting;
    }

    function purchaseTokens(uint256 usdtAmount, address referrer) external {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Sale is not active"
        );
        require(referrers[referrer], "Referrer not eligible to refer");
        require(referrer != _msgSender(), "Cannot self-refer");

        usdtToken.safeTransferFrom(_msgSender(), owner(), usdtAmount);

        uint256 duelTokensToPurchase = 0;
        unchecked {
            duelTokensToPurchase = (usdtAmount * 10 ** 15) / rateFactor;
        }
        require(
            tokensSold + duelTokensToPurchase <= maxSupply,
            "Exceeds maximum supply"
        );

        IVesting(_privateSaleVesting).allocateDUEL(
            _msgSender(),
            duelTokensToPurchase
        );
        tokensSold += duelTokensToPurchase;

        referrers[_msgSender()] = true;
        emit TokensPurchase(
            _msgSender(),
            usdtAmount,
            duelTokensToPurchase,
            referrer
        );
    }

    function withdrawUSDT(uint256 amount) external onlyOwner afterICO {
        require(amount > 0, "Insufficient amount");
        usdtToken.safeTransfer(owner(), amount);
    }
}
