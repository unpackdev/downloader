pragma solidity ^0.6.12;

import "./ChainlinkClient.sol";
import "./Ownable.sol";

contract ATestnetConsumer is ChainlinkClient, Ownable {
    uint256 private constant ORACLE_PAYMENT = 0;

    struct Winner {
        string winner;
        uint256 resultNow;
        uint256 resultBlock;
    }
    // mapping of state code ("CO", "TN", "US") to Winner
    mapping(string => Winner) public presidentialWinners;
    mapping(bytes32 => string) private requestIdToState;

    constructor() public Ownable() {
        setPublicChainlinkToken();
    }

    function requestPresidentialVotes(
        address _oracle,
        string memory _jobId,
        string memory _state
    ) public onlyOwner {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(_jobId),
            address(this),
            this.fulfillpresidentialWinners.selector
        );
        req.add("copyPath", _state);
        bytes32 requestId = sendChainlinkRequestTo(
            _oracle,
            req,
            ORACLE_PAYMENT
        );
        requestIdToState[requestId] = _state;
    }

    function fulfillpresidentialWinners(bytes32 _requestId, bytes32 _votes)
        public
        recordChainlinkFulfillment(_requestId)
    {
        // quit early if result is blank (avoids setting resultNode and resultBlock)
        require(_votes != 0);
        presidentialWinners[requestIdToState[_requestId]] = Winner({
            winner: bytes32ToString(_votes),
            resultNow: now,
            resultBlock: block.number
        });
    }

    function deleteMappingElement(string memory _key) public onlyOwner {
        delete presidentialWinners[_key];
    }

    function getChainlinkToken() private view returns (address) {
        return chainlinkTokenAddress();
    }

    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner {
        cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
        );
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 _bytes32)
        private
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
