pragma solidity ^0.8.18;

import "./ERC721.sol";

/// @title PillStore contract
/// @notice Allows anyone to define a "Pill" NFT set, with various permissions and settings, and allows other users to mint Pills from these sets.
/// @author Logan Brutsche
contract PillStore {
    PillSet[] public pillSets;

    /// @notice struct to represent PillSets
    struct PillSet {
        address owner; // 0 indicates the set has not been initialized
        address operator; // 0 indicates the contract has not been deployed
        uint price; // 0 indicates free
        uint supplyLimit; // 0 indicates no limit
        address exclusiveBuyer; // 0x0 indicates anyone can buy
        address payable revenueRecipient;
        Pill nftContract;
    }

    /// @notice Prepare a PillSet to be deployed later
    /// @param _owner The owner of the set. Can change operator and revenueRecipient, and transfer ownership
    /// @param _operator The address that will be allowed to deploy and manage the pill set.
    /// @param _revenueRecipient The address to which revenue from pill sales will be sent.
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

    /// @notice Sets the new owner of the stack.
    /// @dev Only callable by the stack owner.
    /// @param _pillSetId id of the set.
    /// @param _owner new owner of the set.
    function setOwner(uint _pillSetId, address _owner)
        external
        onlyPillSetOwner(_pillSetId)
    {
        _setOwner(_pillSetId, _owner);
    }
    /// @notice Sets the operator buyer of a PillSet.
    /// @dev Only callable by the stack owner.
    /// @param _pillSetId id of the set.
    /// @param _operator new operator of the set.
    function setOperator(uint _pillSetId, address _operator)
        external
        onlyPillSetOwner(_pillSetId)
    {
        _setOperator(_pillSetId, _operator);
    }
    /// @notice Sets the exclusive buyer of a PillSet.
    /// @dev Only callable by the stack owner.
    /// @param _pillSetId id of the set.
    /// @param _revenueRecipient new revenue recipient of the set.
    function setRevenueRecipient(uint _pillSetId, address payable _revenueRecipient)
        external
        onlyPillSetOwner(_pillSetId)
    {
        _setRevenueRecipient(_pillSetId, _revenueRecipient);
    }

    // onlyOperator funcs

    /// @notice Initialize a PillSet with full configuration, and deploy a Pill NFT contract.
    /// @param _pillSetId id of the set.
    /// @param _price Price to mint an token from this set. Zero indicates free.
    /// @param _supplyLimit Maximum number of tokens that can be minted. Zero indicates unlimited.
    /// @param _exclusiveBuyerIfSet If not the zero address, only this buyer can mint a token from this set.
    /// @param _appName The name of the Urbit app this NFT represents.
    /// @param _metadataUrl the URL for the NFT metadata.
    /// @return Returns the deployed Pill NFT contract.
    function deployPillSet
    (
        uint _pillSetId,
        uint _price,
        uint _supplyLimit,
        address _exclusiveBuyerIfSet,
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
        _setExclusiveBuyer(_pillSetId, _exclusiveBuyerIfSet);
        return _deployContract(_pillSetId, _appName, _metadataUrl);
    }

    /// @notice Sets the price of a PillSet.
    /// @dev Only callable by the set operator.
    /// @param _pillSetId id of the set.
    /// @param _price new price of the set.
    function setPrice(uint _pillSetId, uint _price)
        external
        onlyPillSetOperator(_pillSetId)
    {
        _setPrice(_pillSetId, _price);
    }
    /// @notice Sets the supply limit of a PillSet.
    /// @dev Only callable by the stack operator.
    /// @dev Will revert if the new supplyLimit is less than the current supply of the token.
    /// @param _pillSetId id of the set.
    /// @param _supplyLimit new supply limit of the set.
    function setSupplyLimit(uint _pillSetId, uint _supplyLimit)
        external
        onlyPillSetOperator(_pillSetId)
    {
        _setSupplyLimit(_pillSetId, _supplyLimit);
    }
    /// @notice Sets the exclusive buyer of a PillSet.
    /// @dev Only callable by the stack operator.
    /// @param _pillSetId id of the set.
    /// @param _exclusiveBuyerIfSet new exclusive buyer of the set.
    /// @dev If set to the zero address, anyone can buy pills from the set.
    function setExclusiveBuyer(uint _pillSetId, address _exclusiveBuyerIfSet)
        external
        onlyPillSetOperator(_pillSetId)
    {
        _setExclusiveBuyer(_pillSetId, _exclusiveBuyerIfSet);
    }

    // internal setters

    /// @notice Internal function to set the owner of a specific pill set.
    /// @param _pillSetId The ID of the pill set.
    /// @param _owner The new owner's address.
    /// @dev This is an internal function and can't be called externally.
    function _setOwner(uint _pillSetId, address _owner) internal {
        pillSets[_pillSetId].owner = _owner;
    }
    /// @notice Internal function to set the operator of a specific pill set.
    /// @param _pillSetId The ID of the pill set.
    /// @param _operator The new operator's address.
    /// @dev This is an internal function and can't be called externally.
    function _setOperator(uint _pillSetId, address _operator) internal {
        pillSets[_pillSetId].operator = _operator;
    }
    /// @notice Internal function to set the revenue recipient of a specific pill set.
    /// @param _pillSetId The ID of the pill set.
    /// @param _revenueRecipient The new revenue recipient's address.
    /// @dev This is an internal function and can't be called externally.
    function _setRevenueRecipient(uint _pillSetId, address payable _revenueRecipient) internal {
        pillSets[_pillSetId].revenueRecipient = _revenueRecipient;
    }
    /// @notice Internal function to set the price of a specific pill set.
    /// @param _pillSetId The ID of the pill set.
    /// @param _price The new price.
    /// @dev This is an internal function and can't be called externally.
    function _setPrice(uint _pillSetId, uint _price) internal {
        pillSets[_pillSetId].price = _price;
    }
    /// @notice Internal function to set the supply limit of a specific pill set.
    /// @param _pillSetId The ID of the pill set.
    /// @param _supplyLimit The new supply limit.
    /// @dev Cannot set the supplyLimit to lower than the current supply of the token
    /// @dev 0 is considered infinite supply, and thus _supplyLimit = 0 is always a valid argument.
    /// @dev This is an internal function and can't be called externally. Checks that the new supply limit is valid.
    function _setSupplyLimit(uint _pillSetId, uint _supplyLimit) internal {
        if (address(pillSets[_pillSetId].nftContract) != address(0)) {
            require(_supplyLimit == 0 || _supplyLimit >= pillSets[_pillSetId].nftContract.currentSupply(), "new supply limit < current supply");
        }
        pillSets[_pillSetId].supplyLimit = _supplyLimit;
    }
    /// @notice Internal function to set the exclusive buyer of a specific pill set.
    /// @param _pillSetId The ID of the pill set.
    /// @param _exclusiveBuyer The new value of the stack's exclusiveBuyer.
    /// @dev This is an internal function and can't be called externally.
    function _setExclusiveBuyer(uint _pillSetId, address _exclusiveBuyer) internal {
        pillSets[_pillSetId].exclusiveBuyer = _exclusiveBuyer;
    }

    /// @notice Internal function to deploy a new Pill contract for a specific pill set.
    /// @param _pillSetId The ID of the pill set.
    /// @param _appName The name of the application.
    /// @param _metadataUrl The URL for the metadata.
    /// @return The newly deployed Pill contract.
    /// @dev Throws if the contract is already deployed for the given pill set.
    function _deployContract(uint _pillSetId, string calldata _appName, string calldata _metadataUrl)
        internal
        returns (Pill)
    {
        require(address(pillSets[_pillSetId].nftContract) == address(0), "contract already deployed");

        return pillSets[_pillSetId].nftContract = new Pill(_appName, _metadataUrl);
    }

    /// @notice Modifier to check if the caller is the owner of a specific pill set.
    /// @param _pillSetId The ID of the pill set.
    /// @dev Throws if the caller is not the owner.
    /// @dev Also throws if the _pillSetId is invalid
    modifier onlyPillSetOwner(uint _pillSetId) {
        require(_pillSetId < pillSets.length, "Invalid _pillSetId");
        require(msg.sender == pillSets[_pillSetId].owner, "msg.sender != owner");
        _;
    }

    /// @notice Modifier to check if the caller is the operator of a specific pill set.
    /// @param _pillSetId The ID of the pill set.
    /// @dev Throws if the caller is not the operator.
    /// @dev Also throws if the _pillSetId is invalid
    modifier onlyPillSetOperator(uint _pillSetId) {
        require(_pillSetId < pillSets.length, "Invalid _pillSetId");
        require(msg.sender == pillSets[_pillSetId].operator, "msg.sender != operator");
        _;
    }
    
    /// @notice Emitted when a Pill NFT is sold.
    /// @param pillSetId The ID of the pill set.
    /// @param nftId The ID of the minted NFT.
    event PillSold(uint indexed pillSetId, uint nftId);

    /// @dev Mint a new NFT pill.
    /// @param _pillSetId The ID of the pill set.
    /// @param _recipient The address to receive the minted NFT.
    /// @dev The pill set must be deployed.
    /// @dev Sent value must be greater or equal to the pill price.
    /// @dev Supply limit must not be reached.
    /// @dev Sender must be the exclusive buyer if set.
    /// @return nftId The ID of the minted NFT.
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

    /// @notice Retrieve information about a specific pill set.
    /// @param _pillSetId The ID of the pill set.
    /// @return owner The owner of the pill set.
    /// @return operator The operator for the pill set.
    /// @return price The price to mint a pill from this set.
    /// @return supplyLimit The maximum supply for this pill set.
    /// @return exclusiveBuyer If set, only this address can buy from this set.
    /// @return revenueRecipient Address where revenue is forwarded.
    /// @return nftContract The contract of the pill NFT.
    /// @return name The name of the pill set.
    /// @return currentSupply The current supply of pills from this set.
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

    /// @notice Retrieve the contract for a specific pill set.
    /// @param _pillSetId The ID of the pill set to query.
    /// @return The Pill contract associated with the specified pill set.
    function getPillSetContract(uint _pillSetId)
        external
        view
        returns (Pill)
    {
        return pillSets[_pillSetId].nftContract;
    }
}

/// @title Pill - NFT Contract for Pill Minting and Management
/// @notice This contract allows for the minting and basic management of Pill NFTs. It extends ERC721 for NFT functionality.
/// @dev The contract is designed to work specifically with a PillFactory for minting operations. It assumes that the PillFactory is the sole legitimate minter.
/// @author Logan Brutsche
contract Pill is ERC721 {
    string public appName;
    string baseURI;
    address public immutable storeAddress;

    uint public currentSupply;

    /// @notice Create a new Pill NFT contract.
    /// @param _appName The name of the application.
    /// @param __baseURI The base URI for metadata.
    /// @dev We assume that only the PillFactory constructs these; our system ignores any other instances.
    constructor(string memory _appName, string memory __baseURI)
        ERC721(string.concat("Pill: ", _appName), "PILL")
    {
        appName = _appName;
        baseURI = __baseURI;

        storeAddress = msg.sender;
    }
    
    /// @notice Mint a new Pill NFT.
    /// @param who The address to receive the minted NFT.
    /// @return nftId The ID of the minted NFT.
    /// @dev Requires sender to be the store address. Relies on PillFactory for payment and validation.
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

    /// @notice Retrieve the base URI for metadata.
    /// @return baseURI The base URI string.
    /// @dev This function overrides the `_baseURI` function from ERC721.
    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseURI;
    }
}