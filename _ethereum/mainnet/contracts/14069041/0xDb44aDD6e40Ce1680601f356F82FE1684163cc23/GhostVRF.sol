// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./VRFConsumerBase.sol";
import "./ConfirmedOwner.sol";

contract GhostVRF is VRFConsumerBase, ConfirmedOwner(msg.sender) {
    uint256 private constant BIG_PRIME = 200560490131;

    bytes32 private s_keyHash;
    uint256 private s_fee;
    string private ipfsBaseUri;
    uint256 internal GHOST_SUPPLY;

    bytes32 private requestId;
    uint256 private result;

    event DiceRolled(bytes32 indexed requestId, address indexed roller);
    event DiceLanded(bytes32 indexed requestId, uint256 indexed result);

    /**
     * @notice Constructor inherits VRFConsumerBase
     *
     * @dev NETWORK: Rinkeby
     * @dev   Chainlink VRF Coordinator address: 0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B
     * @dev   LINK token address:                0x01BE23585060835E02B77ef475b0Cc51aA1e0709
     * @dev   Key Hash:   0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311
     * @dev   Fee:        0.1 LINK (100000000000000000)
     *
     * @dev NETWORK: Mainnet
     * @dev   Chainlink VRF Coordinator address: 0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * @dev   LINK token address:                0x514910771AF9Ca656af840dff83E8264EcF986CA
     * @dev   Key Hash:   0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     * @dev   Fee:        2 LINK (2000000000000000000)
     *
     * @param _vrfCoordinator address of the VRF Coordinator
     * @param _link address of the LINK token
     * @param _keyHash bytes32 representing the hash of the VRF job
     * @param _fee uint256 fee to pay the VRF oracle
     * @param _totalSupply uint256 total supply of ghosts
     */
    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee, uint256 _totalSupply, string memory _ipfsBaseUri)
    VRFConsumerBase(_vrfCoordinator, _link)
    {
        setKeyHash(_keyHash);
        setFee(_fee);
        setIpfsBaseUri(_ipfsBaseUri);
        GHOST_SUPPLY = _totalSupply;
    }

    /**
     * @notice Requests randomness
     * @dev Warning: if the VRF response is delayed, avoid calling requestRandomness repeatedly
     * as that would give miners/VRF operators latitude about which VRF response arrives first.
     * @dev You must review your implementation details with extreme care.
     *
     * @return bytes32
     */
    function rollDice() public onlyOwner returns (bytes32) {
        require(LINK.balanceOf(address(this)) >= s_fee, "Not enough LINK to pay fee");
        require(result == 0, "Already rolled");
        requestId = requestRandomness(s_keyHash, s_fee);
        result = BIG_PRIME;
        emit DiceRolled(requestId, msg.sender);
        return requestId;
    }

    /**
     * @notice Callback function used by VRF Coordinator to return the random number
     * to this contract.
     * @dev Some action on the contract state should be taken here, like storing the result.
     * @dev WARNING: take care to avoid having multiple VRF requests in flight if their order of arrival would result
     * in contract states with different outcomes. Otherwise miners or the VRF operator would could take advantage
     * by controlling the order.
     * @dev The VRF Coordinator will only send this function verified responses, and the parent VRFConsumerBase
     * contract ensures that this method only receives randomness from the designated VRFCoordinator.
     *
     * @param _requestId bytes32
     * @param _randomness The random result returned by the oracle
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        result = _randomness % BIG_PRIME;
        if (result == 0)
            result += 1;
        emit DiceLanded(_requestId, _randomness);
    }

    /**
     * @notice Get the random number of token with id tokenId
     * @param _tokenId uint256
     * @return random number as a uint256
     */
    function getRandomNumber(uint256 _tokenId) public view returns (uint256) {
        require(result != 0, "Dice not rolled");
        require(result != BIG_PRIME, "Roll in progress");
        return (result * (_tokenId + 1)) % BIG_PRIME;
    }

    /**
     * @notice Get the random number of token with id tokenId
     * @param _offset uint256
     * @param _limit uint256
     * @return array of random number as a uint256[]
     */
    function getBatchRandomNumbers(uint256 _offset, uint256 _limit) public view returns (uint256[] memory) {
        require(_offset + _limit <= GHOST_SUPPLY, "Exceeded total supply");
        uint256[] memory numbers = new uint[](_limit);
        for (uint256 i = 0; i < _limit; i++) {
            numbers[i] = getRandomNumber(_offset + i);
        }
        return numbers;
    }

    /**
     * @notice Withdraw LINK from this contract.
     * @dev this is an example only, and in a real contract withdrawals should
     * happen according to the established withdrawal pattern:
     * https://docs.soliditylang.org/en/v0.4.24/common-patterns.html#withdrawal-from-contracts
     * @param to the address to withdraw LINK to
     * @param value the amount of LINK to withdraw
     */
    function withdrawLINK(address to, uint256 value) public onlyOwner {
        require(LINK.transfer(to, value), "Not enough LINK");
    }

    /**
     * @notice Set the key hash for the oracle
     *
     * @param _keyHash bytes32
     */
    function setKeyHash(bytes32 _keyHash) public onlyOwner {
        s_keyHash = _keyHash;
    }

    /**
     * @notice Get the current key hash
     *
     * @return bytes32
     */
    function keyHash() public view returns (bytes32) {
        return s_keyHash;
    }

    /**
     * @notice Set the oracle fee for requesting randomness
     *
     * @param _fee uint256
     */
    function setFee(uint256 _fee) public onlyOwner {
        s_fee = _fee;
    }

    /**
     * @notice Get the current fee
     *
     * @return uint256
     */
    function fee() public view returns (uint256) {
        return s_fee;
    }

    /**
     * @notice Set the base URI of ipfs for provenance.
     *
     * @param _baseUri string
     */
    function setIpfsBaseUri(string memory _baseUri) private onlyOwner {
        ipfsBaseUri = _baseUri;
    }

    function getIpfsBaseUri() public view returns (string memory) {
        return ipfsBaseUri;
    }
}
