pragma solidity >=0.5.6;

import "./IFeeDB.sol";

interface IGaiaBridge {
    event AddSigner(address signer);
    event RemoveSigner(address signer);
    event UpdateFeeDB(IFeeDB newFeeDB);
    event UpdateQuorum(uint256 newQuorum);
    event SendToken(
        address indexed sender,
        uint256 indexed toChainId,
        address indexed receiver,
        uint256 amount,
        uint256 sendingId,
        bool isFeeCollected
    );
    event ReceiveToken(
        address indexed sender,
        uint256 indexed fromChainId,
        address indexed receiver,
        uint256 amount,
        uint256 sendingId
    );

    function signers(uint256 id) external view returns (address);

    function signerIndex(address signer) external view returns (uint256);

    function quorum() external view returns (uint256);

    function feeDB() external view returns (IFeeDB);

    function signersLength() external view returns (uint256);

    function isSigner(address signer) external view returns (bool);

    function sendedAmounts(
        address sender,
        uint256 toChainId,
        address receiver,
        uint256 sendingId
    ) external view returns (uint256);

    function isTokenReceived(
        address sender,
        uint256 fromChainId,
        address receiver,
        uint256 sendingId
    ) external view returns (bool);

    function sendingCounts(
        address sender,
        uint256 toChainId,
        address receiver
    ) external view returns (uint256);

    function sendToken(
        uint256 toChainId,
        address receiver,
        uint256 amount
    ) external returns (uint256 sendingId);

    function receiveToken(
        address sender,
        uint256 fromChainId,
        address receiver,
        uint256 amount,
        uint256 sendingId,
        bool isFeePayed,
        uint8[] calldata vs,
        bytes32[] calldata rs,
        bytes32[] calldata ss
    ) external;
}
