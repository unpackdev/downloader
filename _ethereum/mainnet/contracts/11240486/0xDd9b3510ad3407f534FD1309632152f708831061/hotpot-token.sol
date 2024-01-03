pragma solidity ^0.6.0;

import "./hotpotinterface.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./EnumerableSet.sol";


contract NFTokenHotPot is ERC721, IHotPot, Ownable {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(uint256 => uint8) internal grades;
    mapping(uint256 => uint256) internal useTimes;
    mapping(uint8 => uint256) internal gradeCount;

    EnumerableSet.AddressSet internal poolContractSet;

    address public rewardContract;
    address public exchangeContract;
    address public gachaContract;

    uint constant public MAX_NUM = 1000;

    event UseTicket(
        address indexed owner,
        uint256 indexed useTime,
        uint256 indexed tokenId
    );

    event TicketUpdate(
        address indexed owner,
        uint8 indexed grade,
        uint256 indexed tokenId
    );

    constructor(string memory name, string memory symbol)
        public
        ERC721(name, symbol)
    {
        
    }

    modifier validNFToken(uint256 _tokenId) {
        require(_exists(_tokenId), "It is not a NFT token!");
        _;
    }

    modifier onlyCanUse() {
        address sender = msg.sender;

        bool canUse = false;

        if (sender == rewardContract) {
            canUse = true;
        }else{
            canUse = poolContractSet.contains(sender);
        }

        require(canUse, "No permission!");
        _;
    }

    modifier onlyCanMint() {
        require(msg.sender == gachaContract, "Only gacha contract can mint!");
        _;
    }

    /**
     * @dev Mints a new NFT.
     * @param _to The address that will own the minted NFT.
     * @param _tokenId of the NFT to be minted by the msg.sender.
     * @param _uri String representing RFC 3986 URI.
     */
    function mint(
        address _to,
        uint256 _tokenId,
        uint8 _grade,
        string calldata _uri
    ) external override onlyCanMint {
        require(totalSupply()<=MAX_NUM,"The max supply is 1000!");
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
        grades[_tokenId] = _grade;
        uint256 count = gradeCount[_grade] + 1;
        gradeCount[_grade] = count;
    }

    function getGradeCount(uint8 _grade)
        external
        override
        view
        returns (uint256)
    {
        return gradeCount[_grade];
    }

    function getGrade(uint256 _tokenId)
        external
        override
        view
        validNFToken(_tokenId)
        returns (uint8)
    {
        return grades[_tokenId];
    }

    function update(uint256 _tokenId, uint8 _grade)
        external
        override
        validNFToken(_tokenId)
    {
        require(
            msg.sender == exchangeContract,
            "Only exchange can update NFT!"
        );
        require(_grade > this.getGrade(_tokenId), "Update fail!");
        grades[_tokenId] = _grade;
        emit TicketUpdate(ownerOf(_tokenId),_grade,_tokenId);
    }

    function getUseTime(uint256 _tokenId)
        external
        override
        view
        validNFToken(_tokenId)
        returns (uint256)
    {
        return useTimes[_tokenId];
    }

    function setExchange(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        exchangeContract = _addr;
    }

    function setGacha(address _addr) external onlyOwner {
        require(_addr.isContract(), "It's not contract address!");
        gachaContract = _addr;
    }

    function setReward(address reward) external onlyOwner {
        require(reward.isContract(), "It's not contract address!");
        rewardContract = reward;
    }

    function addPool(address pool) external onlyOwner {
        require(pool.isContract(), "It's not contract address!");
        poolContractSet.add(pool);
    }

    function removePool(address pool) external onlyOwner {
        require(pool.isContract(), "It's not contract address!");

        require(poolContractSet.remove(pool),"This pool is not exist!");
    }

    function setUse(uint256 _tokenId)
        external
        override
        onlyCanUse
        validNFToken(_tokenId)
    {
        useTimes[_tokenId] = now;
        // address _owner = ownerOf(_tokenId);
        emit UseTicket(ownerOf(_tokenId), now, _tokenId);
    }

    function setUse(uint256 _tokenId, uint256 timestamp)
        external
        override
        onlyCanUse
        validNFToken(_tokenId)
    {
        require(timestamp > now);
        useTimes[_tokenId] = timestamp;
        // address _owner = ownerOf(_tokenId);
        emit UseTicket(ownerOf(_tokenId), timestamp, _tokenId);
    }
}
