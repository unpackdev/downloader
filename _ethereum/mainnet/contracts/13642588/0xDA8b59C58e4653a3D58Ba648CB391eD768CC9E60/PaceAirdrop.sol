// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./PaceArtToken.sol";

import "./console.sol";

contract PaceArtAirdrop is Ownable {
    using SafeMath for uint;

    PaceArtToken public pace;
    address public tokenOwner;
    address public _signer;

    mapping(bytes32 => bool) public executedTxs;
    mapping(address => uint) public claimed;

    event Claimed(address indexed user, uint amount);
    event ClaimedStatsUpdated(address indexed user, uint amount);

    constructor(
        PaceArtToken _pace,
        address _tokenOwner,
        address signer_
    ) {
        pace = _pace;
        tokenOwner = _tokenOwner;
        _signer = signer_;
    }

    function changeTokenOwner(address _newTokenOwner) external onlyOwner {
        require(_newTokenOwner != tokenOwner, "TOKEN_OWNER_IS_THE_SAME!");
        tokenOwner = _newTokenOwner;
    }

    function changeSigner(address signer_) external onlyOwner {
        require(_signer != signer_, "SIGNER_IS_THE_SAME!");
        _signer = signer_;
    }

    function doOverride(address[] memory _users, uint[] memory _values) external onlyOwner {
        require(_users.length == _values.length, "INVALID_USER_VALUE_LENGTH");
        for (uint i = 0; i < _users.length; i++) {
            require(_users[i] != address(0), "INVALID_USER_ADDRESS");
            claimed[_users[i]] = _values[i];

            emit ClaimedStatsUpdated(_users[i], _values[i]);
        }
    }

    function getTxHash(address _to, uint _amount, uint _nonce) private view returns(bytes32) {
        return keccak256(abi.encodePacked(address(this), _to, _amount, _nonce));
    }

    function getMessageHash(address _to, uint _amount, uint _nonce) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _nonce));
    }

    function getEthSignedMessage(address _to, uint _amount, uint _nonce) public pure returns(bytes32) {
        return ECDSA.toEthSignedMessageHash(getMessageHash(_to, _amount, _nonce));
    }

    function claim(bytes memory _signature, address _to, uint _amount, uint _nonce) external {
        bytes32 ethSignedMessage = getEthSignedMessage(_to, _amount, _nonce);
        bytes32 txHash = getTxHash(_to, _amount, _nonce);
        require(ECDSA.recover(ethSignedMessage, _signature) == _signer, "NOT_SIGNED_BY_OWNER!");
        require(!executedTxs[txHash], "TX_IS_ALREADY_EXECUTED!");

        executedTxs[txHash] = true;

        uint toClaim = _amount.sub(claimed[_to]);
        require(toClaim > 0, "NOTHING_TO_CLAIM!");
        require(pace.transferFrom(tokenOwner, _to, toClaim), "TRANFER_PACE_FAILED");
    
        claimed[_to] = claimed[_to].add(toClaim); 

        emit Claimed(_to, toClaim);
    }
}
