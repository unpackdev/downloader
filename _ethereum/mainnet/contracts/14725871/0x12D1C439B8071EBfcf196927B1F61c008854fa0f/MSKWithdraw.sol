pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./Context.sol";

contract MSKWithdraw is Context, Ownable {
    using SafeMath for uint256;

    event Withdraw(
        address indexed receiver,
        uint256 indexed amount,
        bytes signature
    );

    address private m_MSK = 0x72D7b17bF63322A943d4A2873310a83DcdBc3c8D;
    address private m_Bank = 0xa058d593265cA3C86114fA506982DA8746f8a16F;
    address private m_Verify1 = 0x27798F382f4eE811B12f79e5E3035fb5134b3Dbf;
    address private m_Verify2 = 0x7f5467Fd11F4C7C7F143b03883Cda5432545dC13;
    uint256 private m_SignatureLifeTime = 1 minutes * 5;

    mapping(address => uint32) private m_CounterList;

    bool private m_WithdrawEnabled = false;

    constructor() {}

    function setWithdrawEnabled(bool _enabled) external onlyOwner {
        m_WithdrawEnabled = _enabled;
    }

    function getWithdrawEnabled() external view returns (bool) {
        return m_WithdrawEnabled;
    }

    function getWithdrawCounter(address _address) public view returns (uint32) {
        return m_CounterList[_address];
    }

    function withdraw(
        uint256 _amount,
        uint256 _time,
        bytes memory signature1,
        bytes memory signature2
    ) external {
        require(m_WithdrawEnabled);
        uint256 counter = getWithdrawCounter(_msgSender());
        bytes32 messageHash = getMessageHash(
            _msgSender(),
            _amount,
            _time,
            counter
        );

        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        require(
            recoverSigner(ethSignedMessageHash, signature1) == m_Verify1,
            "Different signer1"
        );

        require(
            recoverSigner(ethSignedMessageHash, signature2) == m_Verify2,
            "Different signer2"
        );

        require(block.timestamp - _time < m_SignatureLifeTime);

        counter = counter.add(1);

        m_CounterList[_msgSender()] = uint32(counter);

        IERC20 msk = IERC20(m_MSK);
        msk.transferFrom(m_Bank, _msgSender(), _amount);

        emit Withdraw(_msgSender(), _amount, signature1);
    }

    // ######## SIGN #########

    function getMessageHash(
        address _address,
        uint256 _amount,
        uint256 _time,
        uint256 _counter
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address, _amount, _time, _counter));
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function setSignatureLifeTime(uint256 _signatureLifeTime)
        external
        onlyOwner
    {
        m_SignatureLifeTime = _signatureLifeTime;
    }

    function getSignatureLifeTime() external view returns (uint256) {
        return m_SignatureLifeTime;
    }

    // ######## MSK & BANK & VERIFY #########
    function setMskContract(address _address) external onlyOwner {
        m_MSK = _address;
    }

    function getMskContract() external view returns (address) {
        return m_MSK;
    }

    function setBankAddress(address _address) external onlyOwner {
        m_Bank = _address;
    }

    function getBankAddress() external view returns (address) {
        return m_Bank;
    }

    function setVerifyAddress1(address _address) external onlyOwner {
        m_Verify1 = _address;
    }

    function getVerfiyAddress1() external view returns (address) {
        return m_Verify1;
    }

    function setVerifyAddress2(address _address) external onlyOwner {
        m_Verify2 = _address;
    }

    function getVerfiyAddress2() external view returns (address) {
        return m_Verify2;
    }
}
