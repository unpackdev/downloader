// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./FactoryInterface.sol";
import "./IERC20.sol";

contract UserRedemption is Ownable {
    event UserBurn(address indexed who, uint256 indexed amount, uint256 indexed nonce);

    event Finalize(address indexed who, uint256 indexed amount, bool indexed completed);

    struct Req {
        uint256 amount;
        address requester;
        string _ipfsHash;
        bool completed;
    }

    FactoryInterface public immutable factory;
    IERC20 public immutable token;
    address public signer;
    address public approver;
    address public feeReceiver;
    uint256 public fee;
    mapping(bytes32 => bool) public used;
    mapping(address => uint256) public user_req_nonce;
    Req[] public req;

    string public constant version = "0";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version)");
    bytes32 public constant WHITELIST_TYPEHASH = keccak256("Whitelist(address addr,uint256 amount,uint256 nonce)");

    modifier only(address who) {
        require(msg.sender == who, "incorrect permissions");
        _;
    }

    constructor(
        address _approver,
        address _signer,
        address _factory,
        address _token,
        address _feeReceiver,
        uint256 _fee
    ) {
        approver = _approver;
        signer = _signer;
        factory = FactoryInterface(_factory);
        token = IERC20(_token);
        feeReceiver = _feeReceiver;
        fee = _fee;
    }

    function burn(
        uint256 amount,
        string calldata ipfsHash,
        bytes calldata signature
    ) external {
        require(amount >= fee, "invalid amount");

        bytes32 _hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender, amount, user_req_nonce[msg.sender]))
            )
        );

        require(signer == recoverSigner(_hash, signature), "invalid signer");

        user_req_nonce[msg.sender]++;

        req.push(Req({amount: amount, requester: msg.sender, completed: false, _ipfsHash: ipfsHash}));

        token.transferFrom(msg.sender, address(this), amount);

        emit UserBurn(msg.sender, amount, req.length - 1);
    }

    function finalizeBurn(uint256 nonce, bool completed) external only(approver) {
        Req memory _req = req[nonce];

        require(!_req.completed, "Nonce Already Used");

        if (completed) {
            req[nonce].completed = true;

            token.approve(address(factory), _req.amount);

            factory.burn(_req.amount - fee, _req._ipfsHash);

            token.transfer(feeReceiver, fee);
        } else {
            req[nonce].completed = true;

            token.transfer(_req.requester, _req.amount);
        }

        emit Finalize(msg.sender, _req.amount, completed);
    }

    function changeApprover(address _approver) external onlyOwner {
        approver = _approver;
    }

    function changeSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function changeFeeReciever(address _receiver) external onlyOwner {
        feeReceiver = _receiver;
    }

    function changeFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function recoverSigner(bytes32 messageHash, bytes memory _signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_signature, 32))
            // second 32 bytes
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(messageHash, v, r, s);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256("User Redemption Contract"), keccak256(bytes(version))));
    }
}
