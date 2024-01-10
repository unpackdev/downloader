pragma solidity ^0.8.12;

import "./IAPMReservoir.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Signature.sol";

contract APMReservoir is Ownable, IAPMReservoir {
    using SafeMath for uint256;

    address[] public signers;
    mapping(address => uint256) public signerIndex;
    uint256 public signingNonce;
    uint256 public quorum;

    IFeeDB public feeDB;
    IERC20 public token;

    constructor(
        IERC20 _token,
        uint256 _quorum,
        address[] memory _signers
    ) {
        require(address(_token) != address(0));
        token = _token;

        require(_quorum > 0);
        quorum = _quorum;
        emit UpdateQuorum(_quorum);

        require(_signers.length >= _quorum);
        signers = _signers;

        for (uint256 i = 0; i < _signers.length; i++) {
            address signer = _signers[i];
            require(signer != address(0));
            require(signerIndex[signer] == 0);

            if (i > 0) require(signer != _signers[0]);

            signerIndex[signer] = i;
            emit AddSigner(signer);
        }
    }

    function signersLength() public view returns (uint256) {
        return signers.length;
    }

    function isSigner(address signer) public view returns (bool) {
        return (signerIndex[signer] > 0) || (signers[0] == signer);
    }

    function _checkSigners(
        bytes32 message,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) private view {
        uint256 length = vs.length;
        require(length == rs.length && length == ss.length);
        require(length >= quorum);

        for (uint256 i = 0; i < length; i++) {
            require(isSigner(Signature.recover(message, vs[i], rs[i], ss[i])));
        }
    }

    function addSigner(
        address signer,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) public {
        require(signer != address(0));
        require(!isSigner(signer));

        bytes32 hash = keccak256(abi.encodePacked("addSigner", block.chainid, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        signerIndex[signer] = signersLength();
        signers.push(signer);
        emit AddSigner(signer);
    }

    function removeSigner(
        address signer,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) public {
        require(signer != address(0));
        require(isSigner(signer));

        bytes32 hash = keccak256(abi.encodePacked("removeSigner", block.chainid, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        uint256 lastIndex = signersLength().sub(1);
        require(lastIndex >= quorum);

        uint256 targetIndex = signerIndex[signer];
        if (targetIndex != lastIndex) {
            address lastSigner = signers[lastIndex];
            signers[targetIndex] = lastSigner;
            signerIndex[lastSigner] = targetIndex;
        }

        signers.pop();
        delete signerIndex[signer];

        emit RemoveSigner(signer);
    }

    function updateQuorum(
        uint256 newQuorum,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) public {
        require(newQuorum > 0);

        bytes32 hash = keccak256(abi.encodePacked("updateQuorum", block.chainid, signingNonce++));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        quorum = newQuorum;
        emit UpdateQuorum(newQuorum);
    }

    function updateFeeDB(IFeeDB newDB) public onlyOwner {
        feeDB = newDB;
        emit UpdateFeeDB(newDB);
    }

    mapping(address => mapping(uint256 => mapping(address => uint256[]))) public sendedAmounts;
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => bool)))) public isTokenReceived;

    function sendingCounts(
        address sender,
        uint256 toChainId,
        address receiver
    ) public view returns (uint256) {
        return sendedAmounts[sender][toChainId][receiver].length;
    }

    function sendToken(
        uint256 toChainId,
        address receiver,
        uint256 amount
    ) public returns (uint256 sendingId) {
        sendingId = sendingCounts(msg.sender, toChainId, receiver);
        sendedAmounts[msg.sender][toChainId][receiver].push(amount);

        bool paysFee = feeDB.paysFeeWhenSending();
        _takeAmount(msg.sender, amount, paysFee);
        emit SendToken(msg.sender, toChainId, receiver, amount, sendingId, paysFee);
    }

    function receiveToken(
        address sender,
        uint256 fromChainId,
        address receiver,
        uint256 amount,
        uint256 sendingId,
        bool isFeePayed,
        uint8[] memory vs,
        bytes32[] memory rs,
        bytes32[] memory ss
    ) public {
        require(!isTokenReceived[sender][fromChainId][receiver][sendingId]);

        bytes32 hash = keccak256(
            abi.encodePacked(fromChainId, sender, block.chainid, receiver, amount, sendingId, isFeePayed)
        );
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        _checkSigners(message, vs, rs, ss);

        isTokenReceived[sender][fromChainId][receiver][sendingId] = true;
        _giveAmount(receiver, amount, isFeePayed);

        emit ReceiveToken(sender, fromChainId, receiver, amount, sendingId);
    }

    function _takeAmount(
        address user,
        uint256 amount,
        bool paysFee
    ) private {
        uint256 fee;
        if (paysFee) {
            address feeRecipient;
            (fee, feeRecipient) = _getFeeData(user, amount);
            if (fee != 0 && feeRecipient != address(0)) token.transferFrom(user, feeRecipient, fee);
        }
        token.transferFrom(user, address(this), amount);
    }

    function _giveAmount(
        address user,
        uint256 amount,
        bool isFeePayed
    ) private {
        uint256 fee;
        if (!isFeePayed) {
            address feeRecipient;
            (fee, feeRecipient) = _getFeeData(user, amount);
            if (fee != 0 && feeRecipient != address(0)) token.transfer(feeRecipient, fee);
        }
        token.transfer(user, amount.sub(fee));
    }

    function _getFeeData(address user, uint256 amount) private view returns (uint256 fee, address feeRecipient) {
        fee = feeDB.userFee(user, amount);
        feeRecipient = feeDB.protocolFeeRecipient();
    }
}
