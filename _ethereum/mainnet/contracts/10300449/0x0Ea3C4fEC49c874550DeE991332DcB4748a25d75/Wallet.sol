pragma solidity ^0.6.0;

import "./ERC1820Implementer.sol";
import "./IERC1820Registry.sol";
import "./IERC777Recipient.sol";
import "./IERC777Sender.sol";
import "./IERC777.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./Address.sol";
import "./Helpers.sol";

contract Wallet is Context, IERC777Recipient, IERC777Sender, ERC1820Implementer, OnlyDeployer, OnlyOnce  {
    IERC777 tokenContract;
    bool tokenContractSet;

    event ImtyTransaction(address operator, address from, address to, uint256 amount, bytes userData, bytes operatorData);
    event EthTransaction(address from, address to, uint amount);

    IERC1820Registry private _erc1820 = IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    bytes32 constant private _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 constant private _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    constructor () OnlyDeployer() public {
        _erc1820.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        registerRecipient(address(this));
        registerSender(address(this));
    }
    modifier senderIsImty () {
        require(address(_msgSender()) == address(tokenContract), "Caller is not IMTY token");
        _;
    }

    function senderFor(address account) public {
        _registerInterfaceForAddress(_TOKENS_SENDER_INTERFACE_HASH, account);

        address self = address(this);
        if (account == self) {
            registerSender(self);
        }
    }

    function recipientFor(address account) public {
        _registerInterfaceForAddress(_TOKENS_RECIPIENT_INTERFACE_HASH, account);

        address self = address(this);
        if (account == self) {
            registerRecipient(self);
        }
    }

    function registerRecipient(address recipient) internal {
        _erc1820.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, recipient);
    }

    function registerSender(address sender) public {
        _erc1820.setInterfaceImplementer(address(this), _TOKENS_SENDER_INTERFACE_HASH, sender);
    }

    receive () external payable {
        emit EthTransaction(msg.sender, address(this), msg.value);
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) senderIsImty external override(IERC777Recipient) {
        emit ImtyTransaction(operator, from, to, amount, userData, operatorData);
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) senderIsImty external override {
        emit ImtyTransaction(operator, from, to, amount, userData, operatorData);
    }

    function setTokenContract (address _tokenAddress) onlyDeployer onlyOnce("setTokenContract") external {
        require(!tokenContractSet, "Current token contract is not null");
        tokenContract = IERC777(_tokenAddress);
        tokenContractSet = true;
    }

    function getImtyBalance () public view returns (uint) {
        return tokenContract.balanceOf(address(this));
    }

    function getEthBalance () public view returns (uint) {
        address payable self = payable(address(this));
        return self.balance;
    }

    function _ethTransfer (address payable to, uint amount) internal {
        Address.sendValue(to, amount);
        emit EthTransaction(address(this), to, amount);
    }

    function _imtyTransfer (address payable to, uint amount) internal {
        tokenContract.send(to, amount, "");
    }

    function crowdsaleAllowance (address _crowdsaleAddress) onlyDeployer onlyOnce("crowdsaleAllowance") external returns (bool) {
        return IERC20(address(tokenContract)).approve(_crowdsaleAddress, 780000000 * (10 ** 18));
    }
}
