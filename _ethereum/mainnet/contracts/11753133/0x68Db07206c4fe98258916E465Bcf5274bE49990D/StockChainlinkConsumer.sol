// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ChainlinkClient.sol";
import "./Ownable.sol";

interface GameForthInterface {
    function pushReport(uint256 payload) external;

    function purgeReports() external;
}

/**
 * LEVERAGED FROM https://etherscan.io/address/0xfc4b1Ce32ed7310028DCC0d94C7B3D96dCd880e0#code
 * kthxbai.
 * @title GameForthChainlinkConsumer is a contract which requests data from
 * the Chainlink network
 * @dev This contract is designed to work on multiple networks, including
 * local test networks
 */
contract StockChainlinkConsumer is ChainlinkClient, Ownable {
    string public id;
    uint256 public payment;
    int256 public currentAnswer;
    uint256 public updatedHeight;
    string private alphaApiKey;
    GameForthInterface public gameForth;
    mapping(address => bool) public authorizedRequesters;

    /**
     * @notice Deploy the contract with a specified address for the LINK
     * and Oracle contract addresses
     * @dev Sets the storage for the specified addresses
     * @param _link The address of the LINK token contract
     * @param _oracle The Oracle contract address to send the request to
     * @param _gameforth The Ampleforth contract to call
     * @param _id The bytes32 JobID to be executed
     * @param _payment The payment to send to the oracle, specified in 0.1 LINK
     * @param _alphaApiKey API Key for alphavantage.co
     */
    constructor(
        address _link,
        address _oracle,
        address _gameforth,
        string memory _id,
        uint256 _payment,
        string memory _alphaApiKey
    ) public {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        _updateRequestDetails(_gameforth, _oracle, _id, _payment, _alphaApiKey);
    }

    function updateRequestDetails(
        address _gameforth,
        address _oracle,
        string memory _id,
        uint256 _payment,
        string memory _alphaApiKey
    ) external onlyOwner() {
        _updateRequestDetails(_gameforth, _oracle, _id, _payment, _alphaApiKey);
    }

    function _updateRequestDetails(
        address _gameforth,
        address _oracle,
        string memory _id,
        uint256 _payment,
        string memory _alphaApiKey
    ) private {
        require(
            _gameforth != address(0) && _oracle != address(0),
            "Cannot use zero address"
        );
        require(!authorizedRequesters[_oracle], "Requester cannot be oracle");
        setChainlinkOracle(_oracle);
        id = _id;
        payment = _payment;
        gameForth = GameForthInterface(_gameforth);
        alphaApiKey = _alphaApiKey;
    }

    /*
     * @notice Creates a request to the stored Oracle contract address
     */
    function requestPushReport()
        external
        ensureAuthorizedRequester()
        returns (bytes32 requestId)
    {
        Chainlink.Request memory req =
            buildChainlinkRequest(
                stringToBytes32(id),
                address(this),
                this.fulfillPushReport.selector
            );
        req.add(
            "get",
            string(
                abi.encodePacked(
                    "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=GME&apikey=",
                    alphaApiKey
                )
            )
        );

        string[] memory path = new string[](2);
        path[0] = "Global Quote";
        path[1] = "05. price";
        req.addStringArray("path", path);

        req.addInt("times", 10**9);

        requestId = sendChainlinkRequest(req, (payment * LINK) / 10); // means that payment = 0.1 LINK units, as specified in constructor
    }

    /**
     * @notice Calls the Ampleforth contract's pushReport method with the response
     * from the oracle
     * @param _requestId The ID that was generated for the request
     * @param _data The answer provided by the oracle
     */
    function fulfillPushReport(bytes32 _requestId, int256 _data)
        external
        recordChainlinkFulfillment(_requestId)
    {
        currentAnswer = _data;
        updatedHeight = block.number;
        gameForth.pushReport(uint256(_data));
    }

    /**
     * @notice Calls Ampleforth contract's purge function
     */
    function purgeReports() external onlyOwner() {
        gameForth.purgeReports();
    }

    /**
     * @notice Called by the owner to permission other addresses to generate new
     * requests to oracles.
     * @param _requester the address whose permissions are being set
     * @param _allowed boolean that determines whether the requester is
     * permissioned or not
     */
    function setAuthorization(address _requester, bool _allowed)
        public
        onlyOwner()
    {
        require(
            _requester != getChainlinkOracle(),
            "Requester cannot be oracle"
        );
        authorizedRequesters[_requester] = _allowed;
    }

    /**
     * @notice Returns the address of the LINK token
     * @dev This is the public implementation for chainlinkTokenAddress, which is
     * an internal method of the ChainlinkClient contract
     */
    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }

    /**
     * @notice Returns the address of the stored oracle contract address
     */
    function getChainlinkOracle() public view returns (address) {
        return chainlinkOracleAddress();
    }

    /**
     * @notice Allows the owner to withdraw any LINK balance on the contract
     */
    function withdrawLink() public onlyOwner() {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }

    /**
     * @notice Call this method if no response is received within 5 minutes
     * @param _requestId The ID that was generated for the request to cancel
     * @param _payment The payment specified for the request to cancel
     * @param _callbackFunctionId The bytes4 callback function ID specified for
     * the request to cancel
     * @param _expiration The expiration generated for the request to cancel
     */
    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    ) public onlyOwner() {
        cancelChainlinkRequest(
            _requestId,
            _payment,
            _callbackFunctionId,
            _expiration
        );
    }

    /**
     * @dev Reverts if `msg.sender` is not authorized to make requests.
     */
    modifier ensureAuthorizedRequester() {
        require(
            authorizedRequesters[msg.sender] || msg.sender == owner(),
            "Unauthorized to create requests"
        );
        _;
    }

    // A helper funciton to make the string a bytes32
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
}
