// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./ERC1155Pausable.sol";
import "./Context.sol";
import "./Counters.sol";


contract OwnableDelegateProxy { 

}


contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


/**
 * @title Authentix ERC1155 compliant contract
 * @author Authentix Management Limited <https://authentix.io>
 * @notice This contract can extended to provide a tradeable, pausable, burnable and 
 * limited supply  ERC1155 with access control.
 * @dev Delegates to the Open Zeppelin implementation of ERC1155 but also limits the amount of tokens per Token ID.
 */
contract ERC1155Tradeable is Context, AccessControlEnumerable, Ownable, ERC1155Pausable, ERC1155Burnable {
    
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    address proxyRegistryAddress;

    Counters.Counter private _currentTokenID;

    /// Mapping of Token ID to Creator's Address;
    mapping(uint256 => address) public creators;

    /// Mapping of Token ID to total circulating supply of token;
    mapping(uint256 => uint256) public tokenSupply;

    /// Mapping of Token ID to the maximum amount permitted;
    mapping(uint256 => uint256) public tokenMaxSupply;

    /// Contract name;
    string public name;

    /// Contract symbol;
    string public symbol;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract and configures name, symbol and OpenSea proxy registry address.
     * Open Zeppelin's ERC1155 is instantiated with a blank URL and should be set by the extending
     * contract using _setURI().
     * @param _name Contract name
     * @param _symbol Contract symbol
     * @param _proxyRegistryAddress Address of the OpenSea Proxy Registry
     */
    constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress) 
        ERC1155("") 
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        name = _name;
        symbol = _symbol;
        proxyRegistryAddress = _proxyRegistryAddress;  
    }

    /// External functions;

    /**
     * @notice Allocates the next available Token ID and will mint the `initialSupply` to the caller if required.
     * @dev Increments `_currentTokenID`, assigns caller as the `creator`, sets `tokenSupply` 
     * and `tokenMaxSupply` for the Token ID which is validated when minting.
     *
     * Emits a {TransferSingle} event if `initialSupply` was minted.
     *
     * Requirements:
     *
     * - Caller must have `MINTER_ROLE`.
     * - `initialSupply` must be less than or equal to `maximumSupply`.
     *
     * @param maximumSupply Maximum supply allowed for the token being created
     * @param initialSupply Amount of created token to mint directly to caller
     * @param data Data to pass if receiver is a contract
     * @return The newly created tokenID
     */
    function create(
        uint256 maximumSupply,
        uint256 initialSupply,
        bytes calldata data
    ) 
        external
        returns (uint256) 
    {

        require(
            hasRole(MINTER_ROLE, _msgSender()), 
            "ERC1155Tradeable#create: must have minter role to create"
        );

        require(
            initialSupply <= maximumSupply,
            "ERC1155Tradeable#create: initial supply exceeds max supply"
        );

        _currentTokenID.increment();
        uint256 _id = _currentTokenID.current();

        creators[_id] = _msgSender();
        tokenSupply[_id] = initialSupply;
        tokenMaxSupply[_id] = maximumSupply;

        if (initialSupply != 0) {
            _mint(_msgSender(), _id, initialSupply, data);
        }

        return _id;
    }

    /**
     * @notice Mints some amount of the passed Token ID to an address.
     * @dev Mints `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - Caller must have `MINTER_ROLE`.
     * - `amount` must not exceed the remaining supply of token.
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     *
     * @param to Address to receieve the tokens
     * @param id Token ID to mint
     * @param amount Amount of Token ID to mint
     * @param data Data to pass if receiver is a contract
     */
    function mint(
        address to, 
        uint256 id, 
        uint256 amount, 
        bytes memory data
    ) 
        external
    {

        require(
            hasRole(MINTER_ROLE, _msgSender()), 
            "ERC1155Tradeable#mint: must have minter role to mint"
        );

        uint256 newTokenSupply = tokenSupply[id] + amount;

        require(
            newTokenSupply <= tokenMaxSupply[id],
            "ERC1155Tradeable#mint: max supply of token reached or will be exceeded"
        );

        tokenSupply[id] += amount;

        _mint(to, id, amount, data);
    }

    /**
     * @notice Mints a batch of tokens to a single address.
     * @dev Mints `amount` tokens of token type `id`, and assigns them to `account`.
     * Will only succeed if the whole batch can be minted otherwise it will revert.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - Caller must have `MINTER_ROLE`.
     * - ids and amounts arrays must be the same length.
     * - Each index in the `amounts` array must not exceed the remaining supply of the Token ID.
     * - Each index in the `ids` array must have a corresponding amount in the `amounts` array.
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     *
     * @param to Address to receieve the tokens
     * @param ids Array of Token IDs to mint
     * @param amounts Array of amount of tokens to mint
     * @param data Data to pass if receiver is a contract
     */
    function mintBatch(
        address to, 
        uint256[] memory ids, 
        uint256[] memory amounts, 
        bytes memory data
    ) 
        external 
    {

        require(
            hasRole(MINTER_ROLE, _msgSender()), 
            "ERC1155Tradeable#mintBatch: must have minter role to mint"
        );

        require(
            ids.length == amounts.length,
            "ERC1155Tradeable#mintBatch: arrays must be equal in length"
        );

        uint256 newTokenSupply;

        for (uint256 i = 0; i < ids.length; i++) {

            newTokenSupply = tokenSupply[ids[i]] + amounts[i];

            require(
                newTokenSupply <= tokenMaxSupply[ids[i]],
                "ERC1155Tradeable#mintBatch: max supply of token reached or will be exceeded"
            );

            tokenSupply[ids[i]] += amounts[i];
        }

        _mintBatch(to, ids, amounts, data);
    }

    /// Public functions;

    /**
     * @notice Permanently destroys an amount of the specified token ID held by an address.
     * @dev Destroys `amount` tokens of token type `id` from `account`.
     *
     * Requirements:
     * - caller must be target `account` or `account` must have previously given permission to caller
     * via proxy.
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     *
     * @param account Address to burn tokens from
     * @param id Token ID to burn
     * @param amount Amount of tokens to burn
     */
    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) 
        public 
        override 
    {

        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155Tradeable#burn: caller is not owner nor approved"
        );

        tokenMaxSupply[id] -= amount;
        tokenSupply[id] -= amount;

        _burn(account, id, amount);
    }

    /**
     * @notice Permanently destroys a batch of Token IDs and amounts held by a single address.
     * @dev Will only succeed if the whole batch can be burnt otherwise it will revert.
     * Loops over the `ids` array and for each Token ID, gets the amount to burn from the 
     * `amounts` array at the same index. 
     * `tokenSupply` and `tokenMaxSupply` for each Token ID are decreased by the burn amount.
     *
     * Requirements:
     * - caller must be target `account` or `account` must have previously given permission to caller
     * via proxy.
     * - `ids` and `amounts` arrays must be the same length.
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     *
     * @param account Address to burn tokens from
     * @param ids Array of token IDs to burn
     * @param amounts Array of amounts to burn
     */
    function burnBatch(
        address account, 
        uint256[] memory ids, 
        uint256[] memory amounts
    ) 
        public 
        override 
    {

        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155Tradeable#burnBatch: caller is not owner nor approved"
        );

        require(
            ids.length == amounts.length,
            "ERC1155Tradeable#burnBatch: arrays must be equal in length"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            tokenSupply[ids[i]] -= amounts[i];
            tokenMaxSupply[ids[i]] -= amounts[i];
        }

        _burnBatch(account, ids, amounts);
    }

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     * Override ERC1155.isApprovedForAll to check if `operator` has approved OpenSea to transfer
     * ``account``'s  tokens.
     *
     * @param owner Address of the owner
     * @param operator Address of the operator
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) 
        public 
        view 
        override 
        returns (bool isOperator) 
    {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);

        // Check if `owner` has approved OpenSea proxy;
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Returns the maximum permitted quantity for a Token ID.
     *
     * @param id Token ID to query
     * @return Maximum ammount of Token ID permitted
     */
    function maxSupply(uint256 id) public view returns (uint256) {
        return tokenMaxSupply[id];
    }

    /**
     * @dev Pauses all token transfers.
     *
     * Requirements:
     *
     * - caller must have `PAUSER_ROLE`.
     */
    function pause() public {

        require(
            hasRole(PAUSER_ROLE, _msgSender()), 
            "ERC1155Tradeable#pause: must have pauser role to pause"
        );

        _pause();
    }

    /**
     * @dev Changes the metadata URI for all Token IDs.
     *
     * Requirements:
     *
     * - caller must have `DEFAULT_ADMIN_ROLE`.
     *
     * @param uri New URI
     */
    function setURI(string memory uri) public {

        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 
            "ERC1155Tradeable#setURI: must have admin role to set uri"
        );

        _setURI(uri);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(AccessControlEnumerable, ERC1155) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the total minted supply for a Token ID.
     *
     * @param id Token ID to query
     * @return Amount of Token ID minted
     */
    function totalSupply(uint256 id) 
        public 
        view 
        returns (uint256) 
    {
        return tokenSupply[id];
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * Requirements:
     *
     * - caller must have `PAUSER_ROLE`.
     */
    function unpause() public virtual {

        require(
            hasRole(PAUSER_ROLE, _msgSender()), 
            "ERC1155Tradeable#unpause: must have pauser role to unpause"
        );
        
        _unpause();
    }

    /// Internal / private functions;

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal 
        virtual 
        override(ERC1155, ERC1155Pausable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Returns whether the specified token exists by checking to see if it has a creator.
     *
     * @param id Token ID to query
     * @return bool whether the token exists
     */
    function _exists(uint256 id) 
        internal 
        view 
        returns (bool) 
    {
        return creators[id] != address(0);
    }
}

