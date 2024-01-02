// SPDX-License-Identifier: CHAMCHA
pragma solidity ^0.8.17;

import "./UUPSUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "./ERC20BurnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./SafeTransferLib.sol";
import "./MerkleProof.sol";

contract ChaxPair is
    UUPSUpgradeable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeTransferLib for address payable;
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)")));
    address public token0;
    address public token1;
    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public swapToken0Fee;
    uint256 public swapToken1Fee;
    address public receiveFee;
    bool private initLiquidityed;
    bytes32 public merkleRoot;
    bool public isEnableMerkle;

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        uint fee0,
        uint fee1,
        address indexed to
    );
    event Withdraw(address token, address to, uint256 amount);

    constructor() {
        _disableInitializers();
    }

    // ensures this can be called only once per *proxy* contract deployed
    function initialize(address _token0, address _token1) public initializer {
        __Pausable_init();
        __Ownable_init();
        __ERC20_init("Chax Bridge LP", "CBLP");
        __UUPSUpgradeable_init();
        token0 = _token0;
        token1 = _token1;
        initLiquidityed = false;
        // init fee receive owner
        receiveFee = msg.sender;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    receive() external payable {}

    modifier onlyWhitelist(bytes32[] calldata merkleProof) {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "Merkle: Invalid proof"
        );
        _;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "ChaxPair: TRANSFER_FAILED"
        );
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getReserves()
        public
        view
        returns (uint256 _reserve0, uint256 _reserve1)
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function getReserve(address token) public view returns (uint256 _reserve) {
        if (token == token0) _reserve = reserve0;
        if (token == token1) _reserve = reserve1;
    }

    function setReceiveFee(address addr) public onlyOwner {
        require(addr != address(0), "ChaxPool: ZERO_ADDRESS_IS_NOT_ALLOWED");
        receiveFee = addr;
    }

    function setSwapFee(
        uint256 _swapToken0Fee,
        uint256 _swapToken1Fee
    ) public onlyOwner {
        require(
            _swapToken0Fee <= 10000 && _swapToken1Fee <= 10000,
            "ChaxPool: NOT_MORE_THAN_10000"
        );
        swapToken0Fee = _swapToken0Fee;
        swapToken1Fee = _swapToken1Fee;
    }

    function increaseLiquidity(
        uint256 _amount0In,
        uint256 _amount1In
    ) external onlyOwner {
        IERC20(token0).transferFrom(msg.sender, address(this), _amount0In);
        IERC20(token1).transferFrom(msg.sender, address(this), _amount1In);
        reserve0 = reserve0 + _amount0In;
        reserve1 = reserve1 + _amount1In;
        _mint(msg.sender, _amount0In + _amount1In);
    }

    function decreaseLiquidity(
        uint256 amount0Out,
        uint256 amount1Out
    ) external onlyOwner nonReentrant {
        uint256 burnLpAmount = amount0Out.add(amount1Out);
        require(
            burnLpAmount <= balanceOf(msg.sender),
            "ChaxPair: INSUFFICIENT_LP_BALANCE_AMOUNT"
        );
        _safeTransfer(token0, msg.sender, amount0Out);
        _safeTransfer(token1, msg.sender, amount1Out);
        burn(burnLpAmount);
        reserve0 = reserve0 - amount0Out;
        reserve1 = reserve1 - amount1Out;
    }

    function _calcSwapFee(
        uint256 amount0Out,
        uint256 amount1Out
    ) private view returns (uint256 _fee0, uint256 _fee1) {
        _fee0 = amount0Out.mul(swapToken0Fee).div(10000);
        _fee1 = amount1Out.mul(swapToken1Fee).div(10000);
    }

    function _swap(
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) internal {
        (uint256 _fee0, uint256 _fee1) = _calcSwapFee(amount0Out, amount1Out);
        uint256 actualAmount0Out = amount0Out.sub(_fee0);
        uint256 actualAmount1Out = amount1Out.sub(_fee1);
        if (amount0In > 0)
            IERC20(token0).transferFrom(msg.sender, address(this), amount0In);
        if (amount1In > 0)
            IERC20(token1).transferFrom(msg.sender, address(this), amount1In);
        if (actualAmount0Out > 0) _safeTransfer(token0, to, actualAmount0Out);
        if (actualAmount1Out > 0) _safeTransfer(token1, to, actualAmount1Out);
        if (_fee0 > 0) _safeTransfer(token0, receiveFee, _fee0);
        if (_fee1 > 0) _safeTransfer(token1, receiveFee, _fee1);
        reserve0 = reserve0.add(amount0In).sub(amount0Out);
        reserve1 = reserve1.add(amount1In).sub(amount1Out);
        emit Swap(
            msg.sender,
            amount0In,
            amount1In,
            amount0Out,
            amount1Out,
            _fee0,
            _fee1,
            to
        );
    }

    function swap(
        uint256 amount0In,
        uint256 amount1In,
        address to,
        bytes32[] calldata merkleProof
    ) public whenNotPaused onlyWhitelist(merkleProof) {
        require(to != address(0), "ChaxPair: ZERO_ADDRESS_IS_NOT_ALLOWED");
        require(
            amount0In > 0 || amount1In > 0,
            "ChaxPair: INSUFFICIENT_INPUT_AMOUNT"
        );
        (uint256 _reserve0, uint256 _reserve1) = getReserves(); // gas savings
        uint256 amount0Out = amount1In;
        uint256 amount1Out = amount0In;
        require(
            amount0Out <= _reserve0 && amount1Out <= _reserve1,
            "ChaxPair: INSUFFICIENT_LIQUIDITY"
        );

        _swap(amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function withdrawETH(uint256 amount, address to) public onlyOwner {
        require(to != address(0), "ChaxPair: ZERO_ADDRESS_IS_NOT_ALLOWED");
        payable(to).safeTransferETH(amount);
    }

    function withdraw(
        address token,
        uint256 amount,
        address to
    ) public onlyOwner {
        require(to != address(0), "ChaxPair: ZERO_ADDRESS_IS_NOT_ALLOWED");
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 reserve = getReserve(token);
        require(
            amount <= (balance - reserve),
            "ChaxPair: INSUFFICIENT_BALANCE"
        );
        _safeTransfer(token, to, amount);
        emit Withdraw(token, to, amount);
    }
}
