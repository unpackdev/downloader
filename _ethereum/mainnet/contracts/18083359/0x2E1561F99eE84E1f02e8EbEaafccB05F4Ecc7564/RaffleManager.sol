//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./RrpRequesterV0.sol";
import "./IWaveFactory.sol";
import "./IWaveContract.sol";
import "./Ownable.sol";

contract RaffleManager is RrpRequesterV0, Ownable {
    event RequestedUint256Array(bytes32 indexed requestId, uint256 size);
    event ReceivedUint256Array(bytes32 indexed requestId, uint256[] response);

    address public airnode;
    bytes32 public endpointIdUint256Array;
    address public sponsor;
    address public sponsorWallet;

    IWaveFactory public waveFactory;

    mapping(bytes32 => bool) public expectingRequestWithIdToBeFulfilled;
    mapping(bytes32 => address) public requestToRequester;

    error OnlyRaffleWave();

    modifier onlyRaffleWave() {
        if (!waveFactory.isRaffleWave(msg.sender)) revert OnlyRaffleWave();
        _;
    }

    /// @dev RrpRequester sponsors itself, meaning that it can make requests
    /// that will be fulfilled by its sponsor wallet. See the Airnode protocol
    /// docs about sponsorship for more information.
    /// @param _airnodeRrp Airnode RRP contract address
    constructor(address _airnodeRrp, IWaveFactory _waveFactory) RrpRequesterV0(_airnodeRrp) Ownable() {
        waveFactory = _waveFactory;
    }

    /// @notice Sets parameters used in requesting QRNG services
    /// @param _airnode Airnode address
    /// @param _endpointIdUint256Array Endpoint ID used to request a `uint256[]`
    /// @param _sponsor address used to sponsor this requester
    /// @param _sponsorWallet Sponsor wallet address, used for gas by Airnode
    function setRequestParameters(
        address _airnode,
        bytes32 _endpointIdUint256Array,
        address _sponsor,
        address _sponsorWallet
    ) external onlyOwner {
        airnode = _airnode;
        endpointIdUint256Array = _endpointIdUint256Array;
        sponsor = _sponsor;
        sponsorWallet = _sponsorWallet;
    }

    /// @notice Requests a `uint256[]`
    /// @param size Size of the requested array
    function makeRequestUint256Array(uint256 size) external onlyRaffleWave() returns (bytes32 requestId) {
        requestId = airnodeRrp.makeFullRequest(
            airnode,
            endpointIdUint256Array,
            sponsor,
            sponsorWallet,
            address(this),
            this.fulfillUint256Array.selector,
            // @dev Using Airnode ABI to encode the parameters
            abi.encode(bytes32("1u"), bytes32("size"), size)
        );
        expectingRequestWithIdToBeFulfilled[requestId] = true;
        requestToRequester[requestId] = msg.sender;
        emit RequestedUint256Array(requestId, size);
    }

    /// @notice Called by the Airnode through the AirnodeRrp contract to
    /// fulfill the request
    /// @param requestId Request ID
    /// @param data ABI-encoded response
    function fulfillUint256Array(bytes32 requestId, bytes calldata data) external onlyAirnodeRrp {
        require(expectingRequestWithIdToBeFulfilled[requestId], "Request ID not known");
        expectingRequestWithIdToBeFulfilled[requestId] = false;
        uint256[] memory _qrngUint256Array = abi.decode(data, (uint256[]));
        emit ReceivedUint256Array(requestId, _qrngUint256Array);

        IWaveContract(requestToRequester[requestId]).fulfillRaffle(_qrngUint256Array);
    }
}
