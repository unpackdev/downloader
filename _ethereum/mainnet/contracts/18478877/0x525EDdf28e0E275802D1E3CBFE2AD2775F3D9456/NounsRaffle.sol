// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ILightClient {
    function head() external view returns (uint256);

    function headers(uint256 slot) external view returns (bytes32);
}

interface ISuccinctGateway {
    function requestCallback(
        bytes32 _functionId,
        bytes memory _input,
        bytes memory _context,
        bytes4 _callbackSelector,
        uint32 _callbackGasLimit
    ) external payable returns (bytes32);

    function requestCall(
        bytes32 _functionId,
        bytes memory _input,
        address _address,
        bytes memory _data,
        uint32 _gasLimit
    ) external payable;

    function verifiedCall(
        bytes32 _functionId,
        bytes memory _input
    ) external view returns (bytes memory);

    function isCallback() external view returns (bool);
}

contract NounsRaffle {
    /// @notice Number of blocks iterated over per proof.
    uint64 public constant NB_BLOCKS_PER_PROOF = 262144;

    /// @notice Callback gas limit.
    uint32 public constant CALLBACK_GAS_LIMIT = 2000000;

    /// @notice The address of the gateway.
    address public gateway;

    /// @notice The function id of the oracle.
    bytes32 public functionId;

    /// @notice Payout amount for prize.
    uint256 public payoutAmount;

    /// @notice The light client.
    ILightClient public lightClient;

    /// @notice The owner of the contract.
    address payable public owner;

    /// @notice The prover.
    address public prover;

    /// @notice Whether the n'th raffle is completed.
    mapping(uint64 => bool) public raffleCompleted;

    /// @notice The reentrancy status of the contract.
    bool internal locked;

    /// @notice The raffle bounds.
    uint64[19] public raffleBounds = [
        6123599,
        6339599,
        6562799,
        6778799,
        7001999,
        7225199,
        7441199,
        7664399,
        7880399,
        8103599,
        8326799,
        8535599,
        8758799,
        8974799,
        9197999,
        9413999,
        9637199,
        9860399,
        10076399
    ];

    event RaffleRequest(uint64 indexed raffleIdx);
    event RaffleWinnerSkipped(
        uint64 indexed raffleIdx,
        uint256 indexed i,
        bytes32 indexed withdrawalAddress
    );
    event RaffleWinner(
        uint64 indexed raffleIdx,
        uint256 indexed i,
        bytes32 indexed withdrawalAddress
    );
    event RaffleFulfilled(uint64 indexed raffleIdx);

    constructor(
        address _gateway,
        bytes32 _functionId,
        address _lightClient,
        address _owner,
        address _prover,
        uint256 _payoutAmount
    ) {
        gateway = _gateway;
        functionId = _functionId;
        lightClient = ILightClient(_lightClient);
        owner = payable(_owner);
        prover = _prover;
        payoutAmount = _payoutAmount;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    modifier onlyProver() {
        require(msg.sender == prover, "Not the contract prover");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    function readBytes32Array(
        bytes memory input
    ) public pure returns (bytes32[10] memory) {
        require(input.length == 320, "Input must be 320 bytes in length");
        bytes32[10] memory output;
        assembly {
            mstore(add(output, 0), mload(add(input, 32)))
            mstore(add(output, 32), mload(add(input, 64)))
            mstore(add(output, 64), mload(add(input, 96)))
            mstore(add(output, 96), mload(add(input, 128)))
            mstore(add(output, 128), mload(add(input, 160)))
            mstore(add(output, 160), mload(add(input, 192)))
            mstore(add(output, 192), mload(add(input, 224)))
            mstore(add(output, 224), mload(add(input, 256)))
            mstore(add(output, 256), mload(add(input, 288)))
            mstore(add(output, 288), mload(add(input, 320)))
        }
        return output;
    }

    function startRaffle(
        uint64 raffleIdx,
        uint64 targetSlot
    ) external onlyProver {
        // Check that the raffle is not completed.
        require(
            !raffleCompleted[raffleIdx],
            "NounsRaffle: raffle already completed"
        );

        // Grab the start and end slots for the raffle.
        uint64 startSlot = raffleBounds[raffleIdx];
        uint64 endSlot = raffleBounds[raffleIdx + 1];
        require(
            targetSlot - startSlot < NB_BLOCKS_PER_PROOF,
            "NounsRaffle: target slot out of range"
        );

        // In the future, we will grab the latest head from the light client using the code below.
        uint256 head = lightClient.head();
        bytes32 blockRoot = lightClient.headers(head);
        require(blockRoot != bytes32(0), "NounsRaffle: block root is zero");
        require(head >= endSlot, "NounsRaffle: head is before end slot");

        // Compute pseudorandomness. We use the block hash of the previous block as the seed. This
        // is sufficient for our purposes, since we can assume the requester is not adversarial.
        //
        // Gamma is a random element of the cubic extension defined over the Goldilocks field.
        bytes32 seed = keccak256(abi.encode(blockhash(block.number - 1)));
        uint64 gammaA = uint64(uint256(seed)) % 18446744069414584321;
        seed = keccak256(abi.encode(seed));
        uint64 gammaB = uint64(uint256(seed)) % 18446744069414584321;
        seed = keccak256(abi.encode(seed));
        uint64 gammaC = uint64(uint256(seed)) % 18446744069414584321;
        seed = keccak256(abi.encode(seed));
        uint32 shuffleSeed = uint32(uint256(seed));

        // Request for the proof and callback.
        ISuccinctGateway(gateway).requestCallback(
            functionId,
            abi.encodePacked(
                startSlot,
                endSlot,
                targetSlot,
                blockRoot,
                gammaA,
                gammaB,
                gammaC,
                shuffleSeed
            ),
            abi.encode(raffleIdx),
            this.endRaffle.selector,
            CALLBACK_GAS_LIMIT
        );

        emit RaffleRequest(raffleIdx);
    }

    function endRaffle(
        bytes memory output,
        bytes memory context
    ) public noReentrant {
        // Check that the callback is coming from the gateway.
        require(
            tx.origin == prover,
            "NounsRaffle: proof not from approved prover"
        );
        require(
            msg.sender == gateway && ISuccinctGateway(gateway).isCallback()
        );

        // Decode the context and check that the raffle is not yet completed.
        uint64 raffleIdx = abi.decode(context, (uint64));
        require(!raffleCompleted[raffleIdx]);
        raffleCompleted[raffleIdx] = true;

        // The withdrawal address of the winners.
        bytes32[10] memory winners = readBytes32Array(output);

        // Distribute funds.
        require(
            winners.length * payoutAmount <= address(this).balance,
            "NounsRaffle: not enough funds"
        );
        for (uint256 i = 0; i < winners.length; i++) {
            bytes20 withdrawalAddressBytes = bytes20(winners[i] << 96);
            address withdrawalAddress = address(
                uint160(withdrawalAddressBytes)
            );
            if (winners[i] != bytes32(0)) {
                (bool success, ) = withdrawalAddress.call{value: payoutAmount}(
                    ""
                );
                if (!success) {
                    emit RaffleWinnerSkipped(raffleIdx, i, winners[i]);
                } else {
                    emit RaffleWinner(raffleIdx, i, winners[i]);
                }
            }
        }

        emit RaffleFulfilled(raffleIdx);
    }

    /// @notice Restore funds to the owner in case of issue.
    function emergency() external onlyOwner {
        address safe = 0x3200A7c6467F66734B1DE7aC2dAA4365cFDBcCf8;
        (bool success, ) = safe.call{value: address(this).balance}("");
        require(success, "NounsRaffle: emergency failed");
    }

    function upgradeGateway(address _gateway) external onlyOwner {
        gateway = _gateway;
    }

    function upgradeFunctionId(bytes32 _functionId) external onlyOwner {
        functionId = _functionId;
    }

    function upgradeLightClient(address _lightClient) external onlyOwner {
        lightClient = ILightClient(_lightClient);
    }

    function restartRaffle(uint64 raffleIdx) external onlyOwner {
        raffleCompleted[raffleIdx] = false;
    }

    function updatePayoutAmount(uint256 _payoutAmount) external onlyOwner {
        payoutAmount = _payoutAmount;
    }

    fallback() external payable {}

    receive() external payable {}
}
