pragma solidity ^0.5.0;

import "./Ownable.sol";
import "./LibWeth.sol";
import "./ITokenlonExchange.sol";
import "./LibDecoder.sol";
import "./SafeToken.sol";

contract MarketMakerProxy is 
    Ownable,
    LibWeth,
    LibDecoder,
    SafeToken
{
    string public version = "0.0.5";

    uint256 constant MAX_UINT = 2**256 - 1;
    address internal SIGNER;

    // auto withdraw weth to eth
    address internal WETH_ADDR;
    address public withdrawer;
    mapping (address => bool) public isWithdrawWhitelist;

    modifier onlyWithdrawer() {
        require(
            msg.sender == withdrawer,
            "ONLY_CONTRACT_WITHDRAWER"
        );
        _;
    }
    
    constructor () public {
        owner = msg.sender;
        operator = msg.sender;
    }

    function() external payable {}

    // Manage
    function setSigner(address _signer) public onlyOperator {
        SIGNER = _signer;
    }

    function setWeth(address _weth) public onlyOperator {
        WETH_ADDR = _weth;
    }

    function setWithdrawer(address _withdrawer) public onlyOperator {
        withdrawer = _withdrawer;
    }

    function setAllowance(address[] memory token_addrs, address spender) public onlyOperator {
        for (uint i = 0; i < token_addrs.length; i++) {
            address token = token_addrs[i];
            doApprove(token, spender, MAX_UINT);
            doApprove(token, address(this), MAX_UINT);
        }
    }

    function closeAllowance(address[] memory token_addrs, address spender) public onlyOperator {
        for (uint i = 0; i < token_addrs.length; i++) {
            address token = token_addrs[i];
            doApprove(token, spender, 0);
            doApprove(token, address(this), 0);
        }
    }

    function registerWithdrawWhitelist(address _addr, bool _add) public onlyOperator {
        isWithdrawWhitelist[_addr] = _add;
    }

    function withdraw(address token, address payable to, uint256 amount) public onlyWithdrawer {
        require(
            isWithdrawWhitelist[to],
            "NOT_WITHDRAW_WHITELIST"
        );
        if(token == WETH_ADDR) {
            convertWethtoETH(token, amount);
            to.transfer(amount);
        } else {
            doTransferFrom(token, address(this), to , amount);
        }
    }

    function withdrawETH(address payable to, uint256 amount) public onlyWithdrawer {
        require(
            isWithdrawWhitelist[to],
            "NOT_WITHDRAW_WHITELIST"
        );
        to.transfer(amount);
    }

    function isValidSignature(bytes32 orderHash, bytes memory signature) public view returns (bytes32) {
        require(
            SIGNER == ecrecoverAddress(orderHash, signature),
            "INVALID_SIGNATURE"
        );
        return keccak256("isValidWalletSignature(bytes32,address,bytes)");
    }

    function ecrecoverAddress(bytes32 orderHash, bytes memory signature) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s, address user, uint16 feeFactor) = decodeMmSignature(signature);
        
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n54",
                    orderHash,
                    user,
                    feeFactor
                )),
            v, r, s
        );
    }
}
