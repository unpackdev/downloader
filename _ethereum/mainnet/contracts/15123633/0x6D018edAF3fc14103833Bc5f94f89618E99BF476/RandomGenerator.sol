//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";
import "./LinkTokenInterface.sol";
import "./ERC165.sol";
import "./IDestNFT.sol";
import "./IRandomGenerator.sol";


contract RandomGenerator is IRandomGenerator, ERC165, Ownable, VRFConsumerBase {

    /// @notice request id => recipient address
    mapping(bytes32 => address) internal sessions;

    bytes32 internal keyHash;

    uint256 internal fee;

    address public linkedContract;

    event ChainlinkConfigured(bytes32 keyHash, uint256 fee);
    event UpdateLinkedContract(address contractAddress);


    modifier sufficientFee() {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK balance");
        _;
    }

    /**
     * @notice Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     * Fee: 0.1 * 10 ** 18 = 0.1 LINK (varies by network)
     */
    constructor(
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash,
        uint256 _fee
    )
    Ownable()
    VRFConsumerBase(_vrfCoordinator, _link)
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
        interfaceId == type(IRandomGenerator).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @notice Setup linked contract, could be configured once
     * @param _contract DestNFT contract address
     */
    function initLinkedContract(address _contract) public onlyOwner {
        require(linkedContract == address(0), "linked contract already configured");
        require(_contract != address(0), "empty contract address");
        linkedContract = _contract;
        emit UpdateLinkedContract(linkedContract);
    }

    /**
     * @notice adjust chainlink parameters
     * @param _keyHash chainlink key hash
     * @param _fee chainlink fee
     */
    function updateChainlink(bytes32 _keyHash, uint256 _fee) external onlyOwner {
        if (_keyHash != 0) {
            keyHash = _keyHash;
        }
        if (_fee != 0) {
            fee = _fee;
        }
        emit ChainlinkConfigured(keyHash, fee);
    }

    function _saveSession(bytes32 requestId, address recipient) internal {
        sessions[requestId] = recipient;
    }

    function askRandomness(address recipient) virtual override external sufficientFee {
        require(msg.sender == linkedContract, "access denied");
        _saveSession(requestRandomness(keyHash, fee), recipient);
    }

    /**
     * @notice Callback function used by VRF Coordinator
     * @param requestId bytes32
     * @param randomness uint256
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override {
        IDestNFT(linkedContract).randomMintCallback(randomness, sessions[requestId]);
        delete sessions[requestId];
    }
}
