// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.3;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ECDSA.sol";
import "./MerkleProof.sol";

contract LevxStreaming is Ownable, MerkleProof {
    using SafeERC20 for IERC20;

    uint256 constant STREAMING_PERIOD = 180 days;

    enum AuthType {
        ETHEREUM,
        SIGNED_ID
    }

    struct Distribution {
        AuthType authType;
        uint32 deadline;
        address wallet;
    }

    struct Streaming {
        address recipient;
        uint32 startedAt;
        uint256 amountTotal;
        uint256 amountStreamed;
    }

    address public immutable levx;
    address public signer;
    mapping(bytes32 => Distribution) public distributionOf;
    mapping(bytes32 => Streaming) public streamingOf;

    event ChangeSigner(address indexed signer);
    event Add(bytes32 indexed merkleRoot, AuthType authType, uint32 deadline, address indexed wallet);
    event Start(
        bytes32 indexed hash,
        bytes32 indexed merkleRoot,
        bytes32 indexed id,
        address recipient,
        uint256 amount
    );
    event Claim(bytes32 indexed hash, address indexed recipient, uint256 amount);

    constructor(
        address _owner,
        address _levx,
        address _signer
    ) {
        levx = _levx;
        signer = _signer;
        _transferOwnership(_owner);

        emit ChangeSigner(_signer);
    }

    function changeSigner(address _signer) external onlyOwner {
        signer = _signer;

        emit ChangeSigner(_signer);
    }

    function add(
        bytes32 merkleRoot,
        AuthType authType,
        uint32 deadline,
        address wallet
    ) external onlyOwner {
        require(block.timestamp < deadline, "LEVX: INVALID_DEADLINE");
        require(wallet != address(0), "LEVX: INVALID_WALLET");

        Distribution storage distribution = distributionOf[merkleRoot];
        require(distribution.wallet == address(0), "LEVX: DUPLICATE_ROOT");
        distribution.authType = authType;
        distribution.deadline = deadline;
        distribution.wallet = wallet;

        emit Add(merkleRoot, authType, deadline, wallet);
    }

    function start(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        bytes memory authData
    ) external {
        Distribution storage distribution = distributionOf[merkleRoot];
        address wallet = distribution.wallet;
        require(wallet != address(0), "LEVX: INVALID_ROOT");

        uint32 _now = uint32(block.timestamp);
        require(_now < distribution.deadline, "LEVX: EXPIRED");

        (bytes32 id, uint256 amount, bytes32 leaf) = _parseAuthData(distribution.authType, authData);
        require(amount > 0, "LEVX: INVALID_AMOUNT");
        require(verify(merkleRoot, leaf, merkleProof), "LEVX: INVALID_PROOF");

        bytes32 hash = keccak256(abi.encodePacked(merkleRoot, leaf));
        Streaming storage streaming = streamingOf[hash];
        require(streaming.startedAt == 0, "LEVX: ALREADY_STARTED");
        streaming.startedAt = _now;
        streaming.recipient = msg.sender;
        streaming.amountTotal = amount;

        IERC20(levx).safeTransferFrom(wallet, address(this), amount);

        emit Start(hash, merkleRoot, id, msg.sender, amount);
    }

    function _parseAuthData(AuthType authType, bytes memory data)
        internal
        view
        returns (
            bytes32 id,
            uint256 amount,
            bytes32 leaf
        )
    {
        if (authType == AuthType.ETHEREUM) {
            id = bytes32(uint256(uint160(msg.sender)));
            amount = abi.decode(data, (uint256));
            leaf = keccak256(abi.encodePacked(msg.sender, amount));
        } else {
            (bytes32 _id, uint256 _amount, uint8 v, bytes32 r, bytes32 s) = abi.decode(
                data,
                (bytes32, uint256, uint8, bytes32, bytes32)
            );
            require(_id > 0, "LEVX: INVALID_ID");

            id = _id;
            amount = _amount;
            leaf = keccak256(abi.encodePacked(id, amount));
            require(ECDSA.recover(ECDSA.toEthSignedMessageHash(leaf), v, r, s) == signer, "LEVX: UNAUTHORIZED");
        }
    }

    function claim(bytes32 hash) external {
        Streaming storage streaming = streamingOf[hash];
        require(streaming.recipient == msg.sender, "LEVX: FORBIDDEN");

        uint256 amount = _amountStreamed(streaming);
        uint256 pending = amount - streaming.amountStreamed;
        streaming.amountStreamed = amount;

        IERC20(levx).safeTransfer(msg.sender, pending);

        emit Claim(hash, msg.sender, pending);
    }

    function pendingAmount(bytes32 hash) external view returns (uint256) {
        Streaming storage streaming = streamingOf[hash];
        return _amountStreamed(streaming) - streaming.amountStreamed;
    }

    function _amountStreamed(Streaming storage streaming) internal view returns (uint256) {
        uint256 duration = block.timestamp - streaming.startedAt;
        if (duration > STREAMING_PERIOD) duration = STREAMING_PERIOD;
        return (streaming.amountTotal * duration) / STREAMING_PERIOD;
    }
}
