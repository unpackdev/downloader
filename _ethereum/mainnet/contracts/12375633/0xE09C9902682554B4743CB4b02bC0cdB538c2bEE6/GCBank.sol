//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./Pausable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract GCBankMeta {
    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct MetaTransaction {
        uint256 nonce;
        address from;
    }

    mapping(address => uint256) public nonces;
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));
    bytes32 internal constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,address to,uint256 amount)"));
    bytes32 internal DOMAIN_SEPARATOR;

    constructor(uint256 _chainId) {
        DOMAIN_SEPARATOR= keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("GCBank")),
                keccak256(bytes("1")),
                _chainId,
                address(this)
        ));
    }
}

contract GCBank is Ownable, Pausable, GCBankMeta {

    address GcrAddress;

    event MoneySent(address indexed _beneficiary, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);

    constructor(address _tokenAddress, uint256 _chainId) GCBankMeta(_chainId) {
        GcrAddress = _tokenAddress;
        // addPauser(msg.sender);
    }

    function pauseContract() onlyOwner external {
        _pause();
    }

    function unpauseContract() onlyOwner external {
        _unpause();
    }

    function withdrawFunds(uint256 _amount) onlyOwner external {
        IERC20 GCR = IERC20(GcrAddress);
        GCR.transfer(owner(), _amount);
    }

    function withdrawPoints (
        uint256 _amount, address _receiverAddress, bytes32 r, bytes32 s, uint8 v
    ) whenNotPaused external {

        IERC20 GCR = IERC20(GcrAddress);
        address contractOwner = owner();
        uint256 previousNonce = nonces[contractOwner];

        require(GCR.balanceOf(address(this)) >= _amount, "Contract doesn't have enough GCR");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(META_TRANSACTION_TYPEHASH, previousNonce, contractOwner, _receiverAddress, _amount))
            )
        );

        require(contractOwner == ecrecover(digest, v, r, s), "GCBank:invalid-signature");

        nonces[contractOwner] = previousNonce + 1;

        GCR.transfer(_receiverAddress, _amount);

        emit MoneySent(_receiverAddress, _amount);
    }

    // receive() external payable {
    //     emit MoneyReceived(msg.sender, msg.value);
    // }

    function renounceOwnership () public pure override {
        revert("Can't renounceOwnership here"); //not possible with this smart contract
    }

}
