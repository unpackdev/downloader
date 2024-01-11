// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./ECDSA.sol";
import "./IWETH.sol";
import "./IUniswapV2Router02.sol";
import "./UniswapV2Library.sol";
import "./UniswapV2OracleLibrary.sol";
import "./FixedPoint.sol";

interface IRewards {
    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function claim() external;

    function reward() external returns (IERC20);
}

contract LPMatch is AccessControl {
    using SafeMath for uint256;
    using FixedPoint for *;
    using ECDSA for bytes32;

    bytes32 public constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    uint256 public constant PERIOD = 1 minutes;

    address public immutable pair;
    address public immutable WETH;
    address public immutable token;
    IUniswapV2Router02 public immutable router;
    IRewards public immutable rewards;

    bool public enableWhitelist;
    uint256 public accRewardsPerLP;
    uint256 public protocolLP;
    address public priceServer;

    mapping(address => uint256) public userLP;
    mapping(address => uint256) public userClaimed;

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin");
        _;
    }

    modifier onlyWhitelist() {
        if (enableWhitelist) {
            require(hasRole(WHITELISTED_ROLE, msg.sender));
        }
        _;
    }

    constructor(
        IUniswapV2Router02 _router,
        IRewards _rewards,
        address _token
    ) public {
        require(address(_router) != address(0));
        require(address(_rewards) != address(0));
        require(_token != address(0));

        address _WETH = _router.WETH();
        router = _router;
        rewards = _rewards;
        WETH = _WETH;
        token = _token;

        address _pair = UniswapV2Library.pairFor(
            _router.factory(),
            _token,
            _WETH
        );
        pair = _pair;

        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, ) = IUniswapV2Pair(_pair).getReserves();
        require(reserve0 != 0 && reserve1 != 0, "NO_RESERVES");

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WHITELISTED_ROLE, msg.sender);
        IERC20(_WETH).approve(address(_router), uint256(-1));
        IERC20(_token).approve(address(_router), uint256(-1));
        IERC20(_pair).approve(address(_rewards), uint256(-1));

        priceServer = msg.sender;
        // enableWhitelist = true;
    }

    function addLiquidity(
        uint256 amount,
        uint256 price,
        uint256 blockTimestampLast,
        bytes calldata sig
    ) external onlyWhitelist {
        require(
            IERC20(WETH).transferFrom(msg.sender, address(this), amount),
            "transfer failed"
        );
        _addLiquidity(amount, price, blockTimestampLast, sig);
    }

    function addLiquidityETH(
        uint256 price,
        uint256 blockTimestampLast,
        bytes calldata sig
    ) external payable onlyWhitelist {
        IWETH(WETH).deposit{value: msg.value}();
        _addLiquidity(msg.value, price, blockTimestampLast, sig);
    }

    function withdrawLP(uint256 amount) external {
        require(userLP[msg.sender] >= amount, "not enough balance");

        _claim(msg.sender);
        rewards.withdraw(amount);
        userLP[msg.sender] = userLP[msg.sender].sub(amount);
        require(IERC20(pair).transfer(msg.sender, amount));
    }

    function adminWithdraw(address tokenToWithdraw, uint256 amount)
        external
        onlyAdmin
    {
        if (tokenToWithdraw == pair) {
            require(protocolLP >= amount, "not enough balance");
            protocolLP = protocolLP.sub(amount);
        }

        require(IERC20(tokenToWithdraw).transfer(msg.sender, amount));
    }

    function setEnableWhitelist(bool _enableWhitelist) external onlyAdmin {
        enableWhitelist = _enableWhitelist;
    }

    function setPriceServer(address _priceServer) external onlyAdmin {
        priceServer = _priceServer;
    }

    function claimable(address user) external view returns (uint256) {
        return (userLP[user] * accRewardsPerLP) / 1e18 - userClaimed[user];
    }

    function claim() external {
        _claim(msg.sender);
    }

    function _addLiquidity(
        uint256 amount,
        uint256 price,
        uint256 blockTimestampLast,
        bytes memory sig
    ) internal {
        (, , uint256 reservesBlockTimestamp) = IUniswapV2Pair(pair)
            .getReserves();
        require(
            reservesBlockTimestamp == blockTimestampLast,
            "Invalid blockTimestampLast"
        );

        bytes32 priceHash = keccak256(abi.encode(price, blockTimestampLast))
            .toEthSignedMessageHash();
        require(priceHash.recover(sig) == priceServer, "Invalid price");

        uint256 tokenAmount = price.mul(amount) >> 112;
        (, , uint256 liquidity) = router.addLiquidity(
            token,
            WETH,
            tokenAmount,
            amount,
            0,
            0,
            address(this),
            now
        );

        _claim(msg.sender);
        rewards.deposit(liquidity);
        uint256 halfLP = liquidity / 2;
        protocolLP = protocolLP.add(halfLP);
        userLP[msg.sender] = userLP[msg.sender].add(halfLP);
        require(
            IERC20(WETH).transfer(
                msg.sender,
                IERC20(WETH).balanceOf(address(this))
            )
        );
    }

    function _claim(address user) internal {
        if (protocolLP == 0) {
            return;
        }

        IERC20 rewardToken = IERC20(token);
        uint256 rewardBalance = rewardToken.balanceOf(address(this));

        rewards.claim();

        accRewardsPerLP = accRewardsPerLP.add(
            (rewardToken.balanceOf(address(this)).sub(rewardBalance) * 1e18) /
                protocolLP
        );

        uint256 pastUserClaimed = userClaimed[user];
        userClaimed[user] = (userLP[user] * accRewardsPerLP) / 1e18;
        uint256 amount = userClaimed[user].sub(pastUserClaimed);

        if (amount > 0) {
            rewardToken.transfer(user, amount);
        }
    }
}
