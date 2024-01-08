pragma solidity ^0.5.0;

import "./ERC1155.sol";
import "./IDigitalArtCollectible.sol";
import "./IProxyRegistry.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract AbstractWrapper is ERC1155 {
    using SafeMath for uint256;
    using Address for address;

    IDigitalArtCollectible public _DigitalArtCollectibleContract;

    // OpenSea's Proxy Registry
    IProxyRegistry public proxyRegistry;

    // Standard attributes
    string public name;
    string public symbol;
    
    // starts as allowed
    bool isExecutionAllowed = true;

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // nft id => nft metadata IPFS URI
    mapping (uint256 => string) public metadatas;

    // nft id => nft total supply
    mapping(uint => uint) public tokenSupply;

    // print index => whether is wrapped
    mapping(uint => bool) public wrappedPrints;

    function initialize() internal;

    /**
        @notice Initialize an nft id's data.
    */
    function create(uint256 _id, uint256 _totalSupply, string memory _uri) internal {

        require(tokenSupply[_id] == 0, "id already exists");
        tokenSupply[_id] = _totalSupply;

        // mint 0 just to let explorers know it exists
        // emit TransferSingle(msg.sender, address(0), msg.sender, _id, 0);

        metadatas[_id] = _uri;
        emit URI(_uri, _id);
    }

    constructor(address _proxyRegistryAddress, address digitalArtCollectibleAddress) public {
        proxyRegistry = IProxyRegistry(_proxyRegistryAddress);
        _DigitalArtCollectibleContract = IDigitalArtCollectible(digitalArtCollectibleAddress);
        _owner = msg.sender;
        
        // Set the name for display purposes
        name = "Cryptocards";
        // Set the symbol for display purposes
        symbol = "WƉ";
        
        initialize();
    }

    /**
       @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Not owner");
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
        @dev override ERC1155 uri function to return IPFS ref.
        @param _id NFT ID
        @return IPFS URI pointing to NFT ID's metadata.
    */
    function uri(uint256 _id) public view returns (string memory) {
        return metadatas[_id];
    }

    /**
    * @dev Will update the metadata for a token
    * @param _tokenId The token to update. _msgSender() must be its creator.
    * @param _newURI New URI for the token.
    */
    function setCustomURI(uint256 _tokenId, string memory _newURI) public onlyOwner {
        metadatas[_tokenId] = _newURI;
        emit URI(_newURI, _tokenId);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _user     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _user, address _operator) public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(_user) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_user, _operator);
    }

     /**
    * @dev Returns the total quantity for a token ID
    * @param _id uint256 ID of the token to query
    * @return amount of token in existence
    */
    function totalSupply(
        uint256 _id
    ) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
        @dev helper function to see if NFT ID exists, makes OpenSea happy.
        @param _id NFT ID
        @return if NFT ID exists.
    */
    function exists(uint256 _id) external view returns(bool) {
        // requires the drawing id to actually exist
        return tokenSupply[_id] != 0;
    }

    /**
        @dev for an NFT ID, queries and transfers tokens from the appropriate
        collectible contract to itself, and mints and transfers corresponding new
        ERC-1155 tokens to caller.
     */
    function wrap(uint256 _id, uint256[] calldata _printIndexes) external {
        require(isExecutionAllowed);

        address _to = msg.sender;

        uint256 _quantity = _printIndexes.length;

        for (uint256 i=0; i < _quantity; ++i) {
            uint256 _printIndex = _printIndexes[i];

            address owner_address = _DigitalArtCollectibleContract.DrawingPrintToAddress(_printIndex);
            // Check if caller owns the ERC20
            require(owner_address == msg.sender, "Does not own ERC20");

            _DigitalArtCollectibleContract.buyCollectible(_id, _printIndex);

            // Check if buy succeeded
            require(_DigitalArtCollectibleContract.DrawingPrintToAddress(_printIndex) == address(this), "An error occured");

            wrappedPrints[_printIndex] = true;

            balances[_id][msg.sender] = balances[_id][msg.sender].add(1);
        }

        // mint
        emit TransferSingle(msg.sender, address(0), msg.sender, _id, _quantity);

        if (_to.isContract()) {
           _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, msg.sender, _id, _quantity, '');
        }
    }


    /**
        @dev for an NFT ID, burns ERC-1155 quantity and transfers cryptoart ERC-20
        tokens to caller.
     */
    function unwrap(uint256 _id, uint256[] calldata _printIndexes) external {
        require(isExecutionAllowed);

        uint256 _quantity = _printIndexes.length;

        require(balances[_id][msg.sender] >= _quantity, "insufficient balance");

        for (uint256 i=0; i < _quantity; ++i) {
            uint256 _printIndex = _printIndexes[i];
            bool success = _DigitalArtCollectibleContract.transfer(msg.sender, _id, _printIndex);

            // Check if transfer succeeded
            require(success, "An error occured while transferring");

            wrappedPrints[_printIndex] = false;

            balances[_id][msg.sender] = balances[_id][msg.sender].sub(1);
        }

        // burn
        emit TransferSingle(msg.sender, address(this), address(0), _id, _quantity);
    }

    /**
        @dev bulk buy presale items
     */
    function bulkPreBuyCollectible(uint256 _id, uint256[] calldata _printIndexes, uint256 initialPrintPrice) external payable  {
        require(isExecutionAllowed);

        address _to = msg.sender;
        uint256 _quantity = _printIndexes.length;
        

        for (uint256 i=0; i < _quantity; ++i) {
            uint256 _printIndex = _printIndexes[i];
             
            _DigitalArtCollectibleContract.alt_buyCollectible.value(initialPrintPrice)(_id, _printIndex);

            require(_DigitalArtCollectibleContract.DrawingPrintToAddress(_printIndex) == address(this), "An error occured");

            wrappedPrints[_printIndex] = true;

            balances[_id][msg.sender] = balances[_id][msg.sender].add(1);
        }

          // mint
        emit TransferSingle(msg.sender, address(0), msg.sender, _id, _quantity);

        if (_to.isContract()) {
           _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, msg.sender, _id, _quantity, '');
        }
    }

    function flipSwitchTo(bool state) public onlyOwner {
        isExecutionAllowed = state;
    }
}
