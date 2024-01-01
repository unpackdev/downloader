pragma solidity ^0.8.18;

import "./ERC721.sol";

contract PillStore {
    PillSet[] public pillSets;

    struct PillSet {
        address owner; // 0 indicates the set has not been initialized
        address operator; // 0 indicates the contract has not been deployed
        uint price; // 0 indicates free
        uint supplyLimit; // 0 indicates no limit
        address exclusiveBuyer; // 0x0 indicates anyone can buy
        address payable revenueRecipient;
        Pill nftContract;
    }

    function prepPillSet(address _owner, address _operator, address payable _revenueRecipient)
        external
        returns (uint pillSetId)
    {
        require(_operator != address(0), "can't set operator 0x0");

        // implicitly returns
        pillSetId = pillSets.length;

        PillSet memory pillSet;
        pillSet.owner = _owner;
        pillSet.operator = _operator;
        pillSet.revenueRecipient = _revenueRecipient;

        pillSets.push(pillSet);
    }

    // onlyOwner funcs
    function setOwner(uint _pillSetId, address _owner)
        external
        onlyPillSetOwner(_pillSetId)
    {
        _setOwner(_pillSetId, _owner);
    }
    function setOperator(uint _pillSetId, address _operator)
        external
        onlyPillSetOwner(_pillSetId)
    {
        _setOperator(_pillSetId, _operator);
    }
    function setRevenueRecipient(uint _pillSetId, address payable _revenueRecipient)
        external
        onlyPillSetOwner(_pillSetId)
    {
        _setRevenueRecipient(_pillSetId, _revenueRecipient);
    }

    // onlyOperator funcs
    function deployPillSet
    (
        uint _pillSetId,
        uint _price,
        uint _supplyLimit,
        address _exclusiveBuyerIfset,
        string calldata _appName,
        string calldata _metadataUrl
    )
        external
        onlyPillSetOperator(_pillSetId)
        returns (Pill)
    {
        PillSet storage pillSet = pillSets[_pillSetId];

        // implicitly checks that pillSet.operator != 0x0
        require(address(pillSet.nftContract) == address(0), "pillSet already deployed");

        _setPrice(_pillSetId, _price);
        _setSupplyLimit(_pillSetId, _supplyLimit);
        _setExclusiveBuyer(_pillSetId, _exclusiveBuyerIfset);
        return _deployContract(_pillSetId, _appName, _metadataUrl);
    }

    function setPrice(uint _pillSetId, uint _price)
        external
        onlyPillSetOperator(_pillSetId)
    {
        _setPrice(_pillSetId, _price);
    }
    function setSupplyLimit(uint _pillSetId, uint _supplyLimit)
        external
        onlyPillSetOperator(_pillSetId)
    {
        _setSupplyLimit(_pillSetId, _supplyLimit);
    }
    function setExclusiveBuyer(uint _pillSetId, address _exclusiveBuyerIfset)
        external
        onlyPillSetOperator(_pillSetId)
    {
        _setExclusiveBuyer(_pillSetId, _exclusiveBuyerIfset);
    }

    // internal setters
    function _setOwner(uint _pillSetId, address _owner) internal {
        pillSets[_pillSetId].owner = _owner;
    }
    function _setOperator(uint _pillSetId, address _operator) internal {
        pillSets[_pillSetId].operator = _operator;
    }
    function _setRevenueRecipient(uint _pillSetId, address payable _revenueRecipient) internal {
        pillSets[_pillSetId].revenueRecipient = _revenueRecipient;
    }
    function _setPrice(uint _pillSetId, uint _price) internal {
        pillSets[_pillSetId].price = _price;
    }
    function _setSupplyLimit(uint _pillSetId, uint _supplyLimit) internal {
        if (address(pillSets[_pillSetId].nftContract) != address(0)) {
            require(_supplyLimit == 0 || _supplyLimit >= pillSets[_pillSetId].nftContract.currentSupply(), "new supply limit < current supply");
        }
        pillSets[_pillSetId].supplyLimit = _supplyLimit;
    }
    function _setExclusiveBuyer(uint _pillSetId, address _exclusiveBuyer) internal {
        pillSets[_pillSetId].exclusiveBuyer = _exclusiveBuyer;
    }

    function _deployContract(uint _pillSetId, string calldata _appName, string calldata _metadataUrl)
        internal
        returns (Pill)
    {
        require(address(pillSets[_pillSetId].nftContract) == address(0), "contract already deployed");

        return pillSets[_pillSetId].nftContract = new Pill(_appName, _metadataUrl);
    }

    modifier onlyPillSetOwner(uint _pillSetId) {
        require(_pillSetId < pillSets.length, "Invalid _pillSetId");
        require(msg.sender == pillSets[_pillSetId].owner, "msg.sender != owner");
        _;
    }

    modifier onlyPillSetOperator(uint _pillSetId) {
        require(_pillSetId < pillSets.length, "Invalid _pillSetId");
        require(msg.sender == pillSets[_pillSetId].operator, "msg.sender != operator");
        _;
    }
    
    event PillSold(uint indexed pillSetId, uint nftId);

    function mintPill(uint _pillSetId, address _recipient)
        external
        payable
        returns (uint nftId)
    {
        PillSet storage pillSet = pillSets[_pillSetId];

        require(address(pillSet.nftContract) != address(0),                                            "pill contract not deployed");
        require(msg.value >= pillSet.price,                                                            "not enough ether included");
        require(pillSet.supplyLimit == 0 || pillSet.nftContract.currentSupply() < pillSet.supplyLimit, "pill sold out");
        require(pillSet.exclusiveBuyer == address(0) || msg.sender == pillSet.exclusiveBuyer,          "msg.sender not exclusiveBuyer");

        // implicly returns
        nftId = pillSet.nftContract.mint(_recipient);

        (bool success, ) = pillSet.revenueRecipient.call{value: msg.value}("");
        require(success, "revenue forward failed");

        emit PillSold(_pillSetId, nftId);
    }

    function getPillSetInfo(uint _pillSetId)
        external
        view
        returns(
            address owner,
            address operator,
            uint price,
            uint supplyLimit,
            address exclusiveBuyer,
            address payable revenueRecipient,
            Pill nftContract,
            string memory name,
            uint currentSupply
        )
    {
        PillSet storage pillSet = pillSets[_pillSetId];

        (nftContract, name, currentSupply) =
            address(pillSet.nftContract) == address(0) ?
                (Pill(address(0)), "", 0)
              : (pillSet.nftContract, pillSet.nftContract.name(), pillSet.nftContract.currentSupply());

        return (
            pillSet.owner,
            pillSet.operator,
            pillSet.price,
            pillSet.supplyLimit,
            pillSet.exclusiveBuyer,
            pillSet.revenueRecipient,
            nftContract,
            name,
            currentSupply
        );
    }

    function getPillSetContract(uint _pillSetId)
        external
        view
        returns (Pill)
    {
        return pillSets[_pillSetId].nftContract;
    }
}

contract Pill is ERC721 {
    string public appName;
    string baseURI;
    address public immutable storeAddress;

    uint public currentSupply;

    constructor(string memory _appName, string memory __baseURI)
        ERC721(string.concat("Pill: ", _appName), "PILL")
    {
        appName = _appName;
        baseURI = __baseURI;

        // We assume that only the PillFactory is constructing these.
        // We can ignore versions of this contract in which that is not the case,
        // since PillFactory is queried to find the canonical list of PillNFTs.
        storeAddress = msg.sender;
    }
    
    function mint(address who)
        public
        returns (uint nftId)
    {
        require(msg.sender == storeAddress, "msg.sender != PillStore"); // we rely on PillFactory to ensure and collect payment

        // implicitly returns
        nftId = currentSupply;
        _mint(who, nftId);

        currentSupply ++;
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }
}