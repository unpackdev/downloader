// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC1155.sol";
import "./ERC1155Holder.sol";
import "./ERC1155Receiver.sol";
import "./Ownable.sol";

/**
 * @title CrookedGiants
 * CrookedGiants - Smart contract for Crooked Giants
 */
contract CrookedGiants is ERC1155, ERC1155Holder, Ownable {
    // Constants
    uint256 private constant MINT_PRICE = 0.03 ether;
    uint256 private constant MAX_TOTAL_SUPPLY = 150;
    uint16 private constant TOTAL_SHARES = 10000;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;
    // Indicates if the owner can still change the metadata URI
    bool public isUriLocked;

    // Contract shareholders
    struct Shareholder {
        uint256 share;
        address payable shareholder_address;
    }
    Shareholder[] public shareholders;

    // Current minted token ID
    uint256 private _currentTokenID;

    event Payout(address indexed _to, uint256 _value);

    /**
     * @dev Constructor
     * @param _name Contract name
     * @param _symbol Contract symbol
     * @param _uri Sets initial URI for metadata. Same for all tokens. Relies on id substitution by the client - https://token-cdn-domain/{id}.json
     * @param _shares The number of shares each shareholder has
     * @param _shareholder_addresses Payment address for each shareholder
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        uint256[] memory _shares,
        address payable[] memory _shareholder_addresses
    ) ERC1155(_uri) {
        name = _name;
        symbol = _symbol;
        isUriLocked = false;
        _currentTokenID = 0;

        // there should be at least one shareholder
        require(_shareholder_addresses.length > 0, "_shareholder_addresses must have at least one item.");

        // the _shares and _shareholder_addresses provided should be the same length
        require(_shares.length == _shareholder_addresses.length, "_shareholder_addresses and _shares must be of the same length");

        // keep track of the total number of shares
        uint256 _total_number_of_shares = 0;
        for (uint256 i = 0; i < _shares.length; i++) {
            _total_number_of_shares += _shares[i];
            Shareholder memory x = Shareholder({
                share: _shares[i],
                shareholder_address: _shareholder_addresses[i]
            });
            shareholders.push(x);
        }

        // there should be exactly 10,000 shares, this amount is used to calculate payouts
        require(_total_number_of_shares == TOTAL_SHARES, "Total number of shares must be 10,000");
    }


    /**
     * @dev See https://forum.openzeppelin.com/t/derived-contract-must-override-function-supportsinterface/6315
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Requires amount to be between 1 and 3
     */
    modifier validAmount(uint8 amount) {
        require(amount >= 1 && amount <= 3, "Mint amount must be between 1 and 3");
        _;
    }

    /**
     * @dev Returns the max total supply of all tokens
     */
    function totalSupply() public view returns (uint256) {
        return _currentTokenID;
    }

    /**
     * @dev For owner to set the base metadata URI while isUriLocked is false
     * @param _uri string - new value for metadata URI
     */
    function setURI(string memory _uri) public onlyOwner {
        require(isUriLocked == false, "URI is locked. Cannot set the base URI");
        _setURI(_uri);
    }

    /**
     * @dev For owner to lock the metadata URI - this is not reversable
     */
    function lockURI() public onlyOwner {
        isUriLocked = true;
    }


    /**
     * @dev Mint items
     * @param amount The number of items to mint. Must be between 1 and 3
     */
    function mint(uint8 amount) public payable  validAmount(amount){
        require(msg.value == (MINT_PRICE * amount), "Wrong minting fee");
        require(amount + _currentTokenID <= MAX_TOTAL_SUPPLY, "Token limit exceeded");
        for(uint8 i=0; i < amount; i++){
            _mint(msg.sender, _currentTokenID + 1, 1, "");
            _currentTokenID++;
        }
    }

    /**
     * @dev Once the royalty contract has a balance, call this to payout to the shareholders
     */
    function payout() public payable {
        // the balance must be greater than 0
        require(address(this).balance > 0, "Contract balance is 0");

        // get the balance of ETH held by the royalty contract
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < shareholders.length; i++) {
            // 10,000 shares represents 100.00% ownership
            uint256 amount = (balance * shareholders[i].share) / TOTAL_SHARES;

            // https://solidity-by-example.org/sending-ether/
            // this considered the safest way to send ETH
            (bool success, ) = shareholders[i].shareholder_address.call{
                value: amount
            }("");

            // it should not fail
            require(success, "Transfer failed.");

            emit Payout(shareholders[i].shareholder_address, amount);
        }
    }

    // https://solidity-by-example.org/sending-ether/
    // receive is called when msg.data is empty.
    receive() external payable {}

    // https://solidity-by-example.org/sending-ether/
    // fallback function is called when msg.data is not empty.
    fallback() external payable {}  
}
