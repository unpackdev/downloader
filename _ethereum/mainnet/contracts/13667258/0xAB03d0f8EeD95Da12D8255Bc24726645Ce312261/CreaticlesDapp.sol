// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// import "./IERC721.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol" ;
// import "./console.sol";

contract CreaticlesDapp is ContextUpgradeable {

    uint256 public CHOOSING_PERIOD;

    struct Request {
        address requester;
        bytes32 detailsHash;
        uint256 value;
        uint128 numberOfWinners;
        uint256 createdAt;
        uint256 expiresAt;
        bool active;
        uint256 numMintPerToken;
    }

    uint256 public cval;

    uint256 public numberOfRequests;

    mapping(uint256 => Request) public requests;

    address public adm;

    address public nftContractAddress;

    bool private initialized;


    //EVENTS
    event RequestCreated(uint256 requestId, address requester, bytes32 detailsHash, uint256 value, uint128 numberOfWinners, uint256 createdAt, uint256 expiresAt, bool active, uint256 numMintPerToken );
    event ProposalAccepted(address to, uint256 requestId, uint256[] _proposalId, uint256[] _tokenIds, string[] _tokenURLs, address[] _winners, uint256 remainingValue, uint256 tokenSupplies);
    event FundsReclaimed(uint256 requestId, address requester, uint256 amount);
    event ChoosingPeriodChanged(uint256 period);

  
    //MODIFIERS
    modifier onlyRequester(uint256 _requestId) {
        require(requests[_requestId].requester == msg.sender);
        _;
    }
    modifier isCreaticlesNFTContract(){
        require(_msgSender() == nftContractAddress, "Only Creaticles NFT Contract has permission to call this function");
        _;
    }
    modifier isAdmin(){
        require(_msgSender() == adm, "This function can only be called by an admin");
        _;
    }

    //INTITIALIZER
    /**
    * 
    * @param choosingPeriod: units DAYS => used to set allowable time period for requester to choose winners
    */
    function initialize(uint256 choosingPeriod) public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
        adm = msg.sender;
        CHOOSING_PERIOD = choosingPeriod * 1 days;
    }

    function setNFTContractAddress(address nftAddress) public isAdmin(){
        nftContractAddress = nftAddress;

    }


    //MUTABLE FUNCTIONS
    /**
    @dev creates a request
    @param _detailsHash => keccak256 hash of the metadata of the request
    @param _numberOfWinners => the initially set number of winners. A request cannot take more winners than specified
    @param _duration => time span of contest in seconds. After this time is up. No more proposals can be taken and the choosing period starts
    */
    function createRequest(bytes32 _detailsHash, uint16 _numberOfWinners, uint32 _duration, uint256 _numMintPerToken) public payable returns(uint256) {
        require(msg.value > 0);
        require(_numberOfWinners > 0);
        require(_numberOfWinners <= 10);
        uint256 _cval = (msg.value * 25) / 1000;    // 2.5% commision
        uint256 _value = msg.value - _cval;
        cval += _cval;
        Request storage _request = requests[numberOfRequests];
        _request.requester = msg.sender;
        _request.detailsHash = _detailsHash;
        _request.value = _value;
        _request.numberOfWinners = _numberOfWinners;
        _request.createdAt = block.timestamp;
        _request.expiresAt = block.timestamp + _duration;
        _request.active = true;
        _request.numMintPerToken = _numMintPerToken;
        numberOfRequests += 1;
        emit RequestCreated(numberOfRequests - 1, msg.sender, _detailsHash, _value, _numberOfWinners, block.timestamp, block.timestamp + _duration, true, _numMintPerToken);
  
        return numberOfRequests;
    }

    

    /**
    @dev can only be called by the CreaticlesNFT contract. Used to pay winners after the CreaticlesNFT contract mints the winning NFTs
    @param _requestId => the requestId of the respective request
    @param _winners => list of the addresses of the chosen winners
    */
    function acceptProposals(address _to, uint256 _requestId, uint256[] memory _proposalId, uint256[] memory _tokenIds, string[] memory _tokenURLs, address[] memory _winners, uint256 _tokenSupplies) public isCreaticlesNFTContract(){
        
        Request storage _request = requests[_requestId];
        require(_winners.length <= _request.numberOfWinners, "Requester cannot claim more winners than intially set");
        uint256 _winnerValue = _request.value / _request.numberOfWinners;
        _request.value -= (_winnerValue * _winners.length);
        _request.active = false;
        //loop through winners and send their ETH
        for(uint256 i = 0; i < _winners.length; i++){
            require(payable(_winners[i]).send(_winnerValue), "Failed to send Ether");
            
        }
        
        _request.active = false;
        emit ProposalAccepted(_to, _requestId, _proposalId, _tokenIds, _tokenURLs,_winners,_winnerValue, _tokenSupplies);
        
    }

    /**
    @dev allows requester to reclaim their funds if they still have funds and the choosing period is over
    */
    function reclaimFunds(uint256 requestId) public {
        Request storage _request = requests[requestId];
        require(_msgSender() == _request.requester, "Sender is not Requester");
        require(block.timestamp >= _request.expiresAt + CHOOSING_PERIOD || !_request.active, "Funds are not available");
  
        payable(msg.sender).transfer(_request.value);
        emit FundsReclaimed(requestId, _request.requester, _request.value);
        _request.value = 0;
        

    }

    /**
    @param duration => (units of days)
    */
    function setChoosingPeriod(uint256 duration) public isAdmin(){ 
        CHOOSING_PERIOD = duration * 1 days;
        emit ChoosingPeriodChanged(CHOOSING_PERIOD);
    }


    //VIEW FUNCTIONS
    /**
    @dev used by CreaticlesNFT contract to determine if the minter is the owner of the specified request
    */
    function isRequester(address _addr, uint256 _requestId) public view returns (bool){
        Request memory _request = requests[_requestId];
        require(_addr ==  _request.requester, "Address is not the requester");
        return true;
    }

    /**
    @dev used by CreaticlesNFT contract to determine if the specified request is not closed
    */
    function isOpenForChoosing(uint256 _requestId) public view returns (bool){
        Request memory _request = requests[_requestId];
        require(block.timestamp >= ((_request.expiresAt * 1 seconds)), "Choosing period has not started");
        require(block.timestamp <= ((_request.expiresAt * 1 seconds) + CHOOSING_PERIOD), "Choosing period is up");
        require(_request.active, "request not active");
        return true;
    }

    /**
    @dev used to set new admin
    */
    function setAdmin(address newAdmin) external isCreaticlesNFTContract() {
        adm = newAdmin;
    }

    function sendValue(uint256 _amount, address payable _dest) public isAdmin(){
        require(_amount <= cval);
        cval -= _amount;
        _dest.transfer(_amount);
    }



}
