// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

// Uncomment this line to use console.log
// import "./console.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";
import "./Ownable.sol";
import "./IERC165.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./Math.sol";

contract GCM_V3 is VRFConsumerBaseV2, Ownable {

    // contract setting variables
    address s_owner;
    uint256 public s_capsuleCommission = 25; // 2.5%
    bytes4 public constant ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 public constant ERC721_INTERFACE_ID = 0x80ac58cd;

    // Chainlink VRF Variables 
    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private s_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;


    mapping(uint256 => address) public s_requestIdToAddress;
    mapping(uint256 => uint256) public s_requestIdToCapsuleID;
    mapping(uint256 => uint256) public s_CapsuleIDToResult;


    // capsule machines variables
    // storage variables for game logic
    uint256[] public s_finishedCapsuleIDs; 
    uint256 public s_numOfFinishedCapsules; 
    Capsule[] public s_allCapsules;
    // need to make the tickets as a seperated array because memory to storage not yet supported.
    mapping(uint256 => TicketsBought[]) public s_listOfBuyers;


    mapping(uint256 => address) public s_capIdToHost; 
    mapping(address => bool) public s_whitelistedNFTs; 

    // only the people with the NFT can host a capcule machine
    address[] public s_hostPrerequisite; 


    // EVENETS 
    event CapsuleCreated(uint indexed capID, address host, address nftAddr, uint256 nftID);
    event BuyCapsulePartition(uint indexed capID, address player, uint256 requestAmt);
    event CapsuleWon(uint indexed capID, address winner, address nftAddr, uint256 nftID);
    event RequestIdForDebug(uint256 indexed requestId);


    struct Capsule { 
        uint256 startTime;
        uint256 endTime;
        
        address host;
        address nftAddr; 
        uint256 nftId;
        uint256 partition; 
        uint256 eachPrice;
        uint256 soldPartition;

        uint256 betPool; 
        uint256 nftType; // 721 or 1155

        address winner;
    }

    struct TicketsBought {
        uint256 toIndexPosition; // position of the buyer, this minus the position of the previous buyer will get the number fo ticket being bought for this purchase
        address buyer; // buyer address, can have more than 1 entry
    }
    // every raffle has a sorted array of EntriesBought. Each element is created when calling
    // either buyEntry or giveBatchEntriesForFree



    constructor(
        address vrfCoordinatorV2,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint32 callbackGasLimit) VRFConsumerBaseV2(vrfCoordinatorV2) {
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        s_callbackGasLimit = callbackGasLimit;
    }

    function getInterfaceType(address _nft) public view returns (uint256 id) {
        IERC165 _thisNFT = IERC165(_nft);
        if (_thisNFT.supportsInterface(ERC1155_INTERFACE_ID)) 
            return 1155;
        else if (_thisNFT.supportsInterface(ERC721_INTERFACE_ID))
            return 721;
        else 
            return 0;
    } 

    
    function setupMachine(address _assetAddress, uint256 _tokenId, uint256 _partition, uint256 _price, uint256 _duration) 
        external
        returns (uint256 capID)
    {   
        // check whitelisted nft
        require(isNFTWhitelisted(_assetAddress) == true, "NFT not whitelisted");

        uint256 _nftType = getInterfaceType(_assetAddress);
        require(_nftType > 0, "Asset is not a recognizable type of NFT");

        // check valid host
        require(isHostValid(msg.sender), "Not valid host.");

        // check duplicate setup
        // deposit nft
        if (_nftType == 721) {
            IERC721 _thisNFT = IERC721(_assetAddress);
            _thisNFT.transferFrom(msg.sender, address(this), _tokenId);
        } else if (_nftType == 1155) {
            IERC1155 _thisNFT = IERC1155(_assetAddress);
            _thisNFT.safeTransferFrom(msg.sender, address(this), _tokenId, 1, '');
        }

        // setup capsule info
        uint256 _newCapID = s_allCapsules.length;

        Capsule memory c;  
        c.startTime = block.timestamp;
        c.host = msg.sender;
        c.nftAddr = _assetAddress;
        c.nftId = _tokenId;
        c.partition = _partition;
        c.eachPrice = _price;
        c.endTime = block.timestamp + _duration;
        c.nftType = _nftType;

        s_capIdToHost[_newCapID] = msg.sender;
        s_allCapsules.push(c);

        emit CapsuleCreated(_newCapID, msg.sender, _assetAddress, _tokenId);

        return _newCapID;
    }

    

    // player buys capsule partition
    function buyCapsulePartition(uint256 _capId, uint256 _requestAmt) public payable
    {
        require(_requestAmt > 0, "request amount cannot be zero");
        require(isCapsuleEnded(_capId) != true, "Capsule is ended.");
        Capsule storage c = s_allCapsules[_capId];

        require(block.timestamp <= c.endTime, "Purchase period ended.");
        require(_requestAmt <= (c.partition - c.soldPartition), "Insufficient remaining partition");

        uint256 checkValue = _requestAmt * c.eachPrice;
        require(msg.value >= checkValue, "Insufficient fund");

        // update buyer position
        uint256 buyerPosition = c.soldPartition + _requestAmt;
        TicketsBought memory ticketsBought = TicketsBought({
            toIndexPosition: buyerPosition,
            buyer: msg.sender
        });
        s_listOfBuyers[_capId].push(ticketsBought);
        
        c.betPool += checkValue; 
        c.soldPartition += _requestAmt;
        
        emit BuyCapsulePartition(_capId, msg.sender, _requestAmt);
    }

    function hostClaim(uint256 _capId) external {
        // check if host
        Capsule storage c = s_allCapsules[_capId];
        require(msg.sender == c.host, "Host only.");

        require(block.timestamp > c.endTime, "Time not end.");
        require(c.soldPartition == 0, "Cannot claim once started.");

        // withdraw nft
        if (c.nftType == 721) {
            IERC721 _thisNft = IERC721(c.nftAddr);
            _thisNft.transferFrom(address(this), msg.sender, c.nftId);
        } else if (c.nftType == 1155) {
            IERC1155 _thisNft = IERC1155(c.nftAddr);
            _thisNft.safeTransferFrom(address(this), msg.sender, c.nftId, 1, '');
        }
        

        c.winner = msg.sender;
        // isNFTinCapsule[c.nftAddr][c.nftId] = false;
        s_finishedCapsuleIDs.push(_capId);
        s_numOfFinishedCapsules++;

        emit CapsuleWon(_capId, c.winner, c.nftAddr, c.nftId); 
    }

    // host or owner to execute
    function selectWinner(uint256 _capId) external {
        require(isCapsuleEnded(_capId) != true, "Capsule is ended.");
        Capsule storage c = s_allCapsules[_capId];

        bool onlyAdminOrHost = (msg.sender == owner()) || (msg.sender == c.host);
        require(onlyAdminOrHost, "only for admin or host");

        bool eitherSoldoutOrTimeout = (block.timestamp > c.endTime) || (c.soldPartition == c.partition);
        require(eitherSoldoutOrTimeout, "Its not sold-out or time-out yet");

        requestRandomWords(_capId);
    }

    function requestRandomWords(uint256 _capId) internal 
    {
        uint256 _requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            s_callbackGasLimit,
            NUM_WORDS
        );
        
        // s_requestIdToAddress[_requestId] = msg.sender;
        s_requestIdToCapsuleID[_requestId] = _capId;
        emit RequestIdForDebug(_requestId);
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {


        uint256 _capId = s_requestIdToCapsuleID[requestId];
        Capsule storage c = s_allCapsules[_capId];
        uint256 resultIndex = randomWords[0] % c.soldPartition + 1;
        s_CapsuleIDToResult[_capId] = resultIndex;
        

        if (c.winner == address(0)) {
            

            uint256 position = findUpperBound(s_listOfBuyers[_capId], resultIndex);
            address winner = s_listOfBuyers[_capId][position].buyer;
            
            c.winner = winner;
            
            // transfer nft
            if (c.nftType == 721) {
                IERC721 _thisNft = IERC721(c.nftAddr);
                _thisNft.transferFrom(address(this), winner, c.nftId);
            } else if (c.nftType == 1155) {
                IERC1155 _thisNft = IERC1155(c.nftAddr);
                _thisNft.safeTransferFrom(address(this), winner, c.nftId, 1, "");
            }
            

            // transfer fund
            uint256 commission = c.betPool * s_capsuleCommission / 1000;
            uint256 transferAmt = 0;
            if (c.betPool - commission > 0)
                transferAmt = c.betPool - commission ;

            if (transferAmt > 0) {
                (bool success1, ) = (address(c.host)).call{value: transferAmt }("");
                require(success1, "transfer failed.");
            }
            if (c.betPool - transferAmt > 0) {
                (bool success2, ) = owner().call{value: (c.betPool - transferAmt) }("");
                require(success2, "transfer failed.");
            }
            

            // c.ended = true; 
            c.betPool = 0;
            // isNFTinCapsule[c.nftAddr][c.nftId] = false;

            // delete allActiveCapsules[_capId];
            s_finishedCapsuleIDs.push(_capId);
            s_numOfFinishedCapsules++;

            emit CapsuleWon(_capId, c.winner, c.nftAddr, c.nftId);  
        }
        
    }


    //code taken from openzeppelin-contracts
    //dev can check out the original code at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/utils/Arrays.sol
    function findUpperBound(TicketsBought[] storage array, uint256 randomNumber) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid].toIndexPosition > randomNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1].toIndexPosition == randomNumber) {
            return low - 1;
        } else {
            return low;
        }
    }


    function isCapsuleExist(uint256 _capId) public view returns (bool) {
        if (_capId < 0 || _capId >= s_allCapsules.length) 
            return false;

        return true;
    }

    function isCapsuleEnded(uint256 _capId) public view returns (bool) {
        require(isCapsuleExist(_capId), "capsule not exist.");
        Capsule memory c = s_allCapsules[_capId];
        if (c.winner != address(0))
            return true;

        return false;
    }

    function getCapsuleDetail(uint _capId) public view
    returns(uint256, uint256, address, address, uint256, uint256, uint256, uint256, uint256, uint256, address)
    {
        require(isCapsuleExist(_capId), "capsule not exist.");
        Capsule memory c = s_allCapsules[_capId];
        return (
            c.startTime, 
            c.endTime,

            c.host,
            c.nftAddr,
            c.nftId,
            c.partition,
            c.eachPrice,
            c.soldPartition,

            c.betPool,
            c.nftType,
            c.winner
        );
    }


    function getCapsuleNum() public view returns (uint256) 
    {
        return s_allCapsules.length;
    }

    function isNFTWhitelisted(address _whitelistedAddress) public view returns(bool) {
        return s_whitelistedNFTs[_whitelistedAddress] == true;
    }

    function addNftToWhitelist(address[] memory _addressesToWhitelist) public onlyOwner {
        for (uint256 index = 0; index < _addressesToWhitelist.length; index++) {
            require(s_whitelistedNFTs[_addressesToWhitelist[index]] != true, "Address is already whitlisted");
            s_whitelistedNFTs[_addressesToWhitelist[index]] = true;
        }        
    }

    function removeNftFromWhitelist(address[] memory _addressesToRemove) public onlyOwner {
        for (uint256 index = 0; index < _addressesToRemove.length; index++) {
            require(s_whitelistedNFTs[_addressesToRemove[index]] == true, "Address isn't whitelisted");
            s_whitelistedNFTs[_addressesToRemove[index]] = false;
        }
    }

    function isHostValid(address _hostWallet) public view returns(bool) {
        for (uint256 index = 0; index < s_hostPrerequisite.length; index++) {
            address _nft = s_hostPrerequisite[index];

            if (_nft != address(0)) {
                uint256 _nftType = getInterfaceType(_nft);
                if (_nftType == 721) {
                    IERC721 _thisNFT = IERC721(_nft);
                    if (IERC721(_thisNFT).balanceOf(_hostWallet) > 0)
                        return true;
                }                 
            }
        }

        return false;
    }

    function addHostPrerequisite(address _addr) public onlyOwner {
        s_hostPrerequisite.push(_addr);
    }

    function removeHostPrerequisite(uint256 _index) public onlyOwner {
        if (_index < s_hostPrerequisite.length) 
            delete s_hostPrerequisite[_index];
    }
    
    function editCapsuleCommission(uint256 _newAmt) external onlyOwner {
        s_capsuleCommission = _newAmt;
    }

    function kill() external onlyOwner {
        selfdestruct(payable(address(owner())));
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function setCallbackGasLimit (uint32 callbackGasLimit) public onlyOwner{
        s_callbackGasLimit = callbackGasLimit;
    }

}
