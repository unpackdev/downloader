pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IWeth.sol";
import "./Ownable.sol";
import "./LibDecoder.sol";

interface IIMBTC {
    function burn(uint256 amount, bytes calldata data) external;
}

interface IWBTC {
    function burn(uint256 value) external;
}

contract MarketMakerProxy is 
    Ownable,
    LibDecoder
{
    using SafeERC20 for IERC20;

    string public constant version = "5.0.0";
    uint256 constant MAX_UINT = 2**256 - 1;
    address public SIGNER;

    // auto withdraw weth to eth
    address public WETH_ADDR;
    address public withdrawer;
    mapping (address => bool) public isWithdrawWhitelist;

    modifier onlyWithdrawer() {
        require(
            msg.sender == withdrawer,
            "MarketMakerProxy: only contract withdrawer"
        );
        _;
    }

    constructor () public {
        owner = msg.sender;
        operator = msg.sender;
    }

    receive() external payable {}

    // Manage
    function setSigner(address _signer) public onlyOperator {
        SIGNER = _signer;
    }

    function setConfig(address _weth) public onlyOperator {
        WETH_ADDR = _weth;
    }

    function setWithdrawer(address _withdrawer) public onlyOperator {
        withdrawer = _withdrawer;
    }

    function setAllowance(address[] memory token_addrs, address spender) public onlyOperator {
        for (uint i = 0; i < token_addrs.length; i++) {
            address token = token_addrs[i];
            IERC20(token).safeApprove(spender, MAX_UINT);
        }
    }

    function closeAllowance(address[] memory token_addrs, address spender) public onlyOperator {
        for (uint i = 0; i < token_addrs.length; i++) {
            address token = token_addrs[i];
            IERC20(token).safeApprove(spender, 0);
        }
    }

    function registerWithdrawWhitelist(address _addr, bool _add) public onlyOperator {
        isWithdrawWhitelist[_addr] = _add;
    }

    function withdraw(address token, address payable to, uint256 amount) public onlyWithdrawer {
        require(
            isWithdrawWhitelist[to],
            "MarketMakerProxy: not in withdraw whitelist"
        );
        if(token == WETH_ADDR) {
            IWETH(WETH_ADDR).withdraw(amount);
            to.transfer(amount);
        } else {
            IERC20(token).safeTransfer(to , amount);
        }
    }

    function withdrawETH(address payable to, uint256 amount) public onlyWithdrawer {
        require(
            isWithdrawWhitelist[to],
            "MarketMakerProxy: not in withdraw whitelist"
        );
        to.transfer(amount);
    }


    function isValidSignature(bytes32 orderHash, bytes memory signature) public view returns (bytes32) {
        require(
            SIGNER == _ecrecoverAddress(orderHash, signature),
            "MarketMakerProxy: invalid signature"
        );
        return keccak256("isValidWalletSignature(bytes32,address,bytes)");
    }

    function _ecrecoverAddress(bytes32 orderHash, bytes memory signature) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = decodeMmSignature(signature);
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    orderHash
                )),
            v, r, s
        );
    }
}
