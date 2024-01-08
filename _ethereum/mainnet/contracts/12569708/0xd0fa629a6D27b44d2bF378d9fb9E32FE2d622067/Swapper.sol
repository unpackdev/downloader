pragma solidity 0.6.4;

import "./Initializable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Auditable.sol";
import "./ITenSetToken.sol";
import "./IERC20Query.sol";
import "./IERC20Cutted.sol";


contract Swapper is Auditable {

    using Address for address payable;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(bytes32 => bool) public finalizedTxs;
    address public token;
    address payable public feeWallet;
    uint256 public swapFee;
    uint256 public minAmount;

    event TokenSet(address indexed tokenAddr, string name, string symbol, uint8 decimals);
    event SwapStarted(address indexed tokenAddr, address indexed fromAddr, uint256 amount, uint256 feeAmount);
    event SwapFinalized(address indexed tokenAddr, bytes32 indexed otherTxHash, address indexed toAddress, uint256 amount);

    constructor(address payable _feeWallet) public {
        feeWallet = _feeWallet;
    }

    modifier notContract() {
        require(!msg.sender.isContract(), "contracts are not allowed to swap");
        require(msg.sender == tx.origin, "proxy contracts are not allowed");
       _;
    }

    function setSwapFee(uint256 fee) onlyOwner external {
        swapFee = fee;
    }

    function setMinAmount(uint256 newMinAmount) onlyOwner external {
        minAmount = newMinAmount;
    }

    function setFeeWallet(address payable newWallet) onlyOwner external {
        feeWallet = newWallet;
    }

    function setToken(address newToken) onlyOwner external returns (bool) {
        require(token != newToken, "already set");

        string memory name = IERC20Query(newToken).name();
        string memory symbol = IERC20Query(newToken).symbol();
        uint8 decimals = IERC20Query(newToken).decimals();

        token = newToken;

        emit TokenSet(token, name, symbol, decimals);
        return true;
    }

    function finalizeSwap(bytes32 otherTxHash, address toAddress, uint256 amount) onlyOwner external returns (bool) {
        require(!finalizedTxs[otherTxHash], "the swap has already been finalized");

        finalizedTxs[otherTxHash] = true;
        IERC20(token).safeTransfer(toAddress, amount);

        emit SwapFinalized(token, otherTxHash, toAddress, amount);
        return true;
    }

    function startSwap(uint256 amount) notContract payable external returns (bool) {
        require(msg.value >= swapFee, "wrong swap fee");
        require(amount >= minAmount, "amount is too small");
        uint256 netAmount = ITenSetToken(token).tokenFromReflection(ITenSetToken(token).reflectionFromToken(amount, true));
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        if (msg.value > 0) {
            uint256 change = msg.value.sub(swapFee);
            if (swapFee > 0) feeWallet.transfer(swapFee);
            if (change > 0) _msgSender().transfer(change);
        }

        emit SwapStarted(token, msg.sender, netAmount, msg.value);
        return true;
    }

    function retrieveTokens(address to, address anotherToken) public onlyOwner() {
        IERC20Cutted alienToken = IERC20Cutted(anotherToken);
        alienToken.transfer(to, alienToken.balanceOf(address(this)));
    }

    function retriveETH(address payable to) public onlyOwner() {
        to.transfer(address(this).balance);
    }
}
