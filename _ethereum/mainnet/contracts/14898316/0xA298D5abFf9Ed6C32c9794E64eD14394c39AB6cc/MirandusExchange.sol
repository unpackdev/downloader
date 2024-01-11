// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./Ownable.sol";
import "./IERC1155.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC1155Holder.sol";
import "./Pausable.sol";
import "./VRFConsumerBaseV2.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./IRandomRewardTable.sol";

contract MirandusExchange is
    Ownable,
    ERC1155Holder,
    Pausable,
    VRFConsumerBaseV2
{  
    event onERC1155ReceivedExecuted(
        uint256 requestId,
        address from,
        uint256 value
    );

    using SafeERC20 for IERC20;

    struct ExchangeRequest {
        address beneficiary;
        uint256 amount;
    }

    VRFCoordinatorV2Interface COORDINATOR;

    uint64 public saleStartTimestamp;

    bytes32 public vrfKeyHash;
    uint64 vrfSubscriptionId;

    address public immutable erc1155Contract;
    uint256 public immutable boxTokenId;
    address public randomRewardAddress;    

    mapping(uint256 => ExchangeRequest) public exchangeRequests;
    mapping(address => uint32) public pendingRequests;

    uint256 public constant maxSupply = 37500;
    uint256 public totalSupply = 0;
    uint256 public MAX_PURCHASE = 1;

    constructor(
        uint64 _saleStartTimestamp,
        address _vrfCoordinator,
        bytes32 _vrfKeyhash,
        uint64 _vrfSubscriptionId,
        address _erc1155Contract,        
        uint256 _boxTokenId,
        address  _randomRewardAddress        
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfKeyHash = _vrfKeyhash;
        vrfSubscriptionId = _vrfSubscriptionId;
        saleStartTimestamp = _saleStartTimestamp;
        erc1155Contract = _erc1155Contract;
        boxTokenId = _boxTokenId;
        randomRewardAddress = _randomRewardAddress;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) public override returns (bytes4) {
        require(block.timestamp >= saleStartTimestamp, "Mirandus Exchange: not started");
        require(
            msg.sender == erc1155Contract,
            "Mirandus Exchange: not Mirandus Exchange contract"
        );
        require(id == boxTokenId, "Mirandus Exchange: not Mirandus Exchange token");
        require(value > 0, "Mirandus Exchange: amount is zero");
        require(from != address(0), "Mirandus Exchange: from is address(0)");
        require(!paused(), "Mirandus Exchange: paused");

        uint256 requestId = COORDINATOR.requestRandomWords(
            vrfKeyHash,
            vrfSubscriptionId,
            3,
            2500000,
            uint32(value)
        );

        exchangeRequests[requestId] = ExchangeRequest(from, value);
        pendingRequests[from] += uint32(value);

        emit onERC1155ReceivedExecuted(requestId, from, value);
        return this.onERC1155Received.selector;
        
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public pure override returns (bytes4) {
        revert("Mirandus Exchange: Batch Transfer is not allowed");
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {        
        ExchangeRequest memory request = exchangeRequests[requestId];
        require(request.beneficiary != address(0), "Mirandus Exchange: Invalid request");       

        for (uint256 i = 0; i < request.amount; i++) {
            uint256 randomNumber = randomWords[i];    
            IRandomRewardTable(randomRewardAddress).rewardRandomOne(
                request.beneficiary,
                randomNumber
            );                 
        }                    

        delete exchangeRequests[requestId];
        pendingRequests[request.beneficiary] -= uint32(request.amount);
        totalSupply += request.amount;        
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setTotalSupply(uint256 _totalSupply) external onlyOwner {
        totalSupply = _totalSupply;
    }

    function updateVrfKeyHash(bytes32 _vrfKeyHash) external onlyOwner {
        vrfKeyHash = _vrfKeyHash;
    }

    function updateVrfSubscriptionId(uint64 _vrfSubscriptionId)
        external
        onlyOwner
    {
        vrfSubscriptionId = _vrfSubscriptionId;
    }

    function getPendingRequests(address addr) public view returns (uint32) {
        return pendingRequests[addr];
    }    

     function setSaleStartDateTime(uint64 _saleStartTimestamp) public onlyOwner {
        saleStartTimestamp = _saleStartTimestamp;
    }

    function setMaxPurchase(uint256 _MAX_PURCHASE) public onlyOwner {
        MAX_PURCHASE = _MAX_PURCHASE;
    }
}
