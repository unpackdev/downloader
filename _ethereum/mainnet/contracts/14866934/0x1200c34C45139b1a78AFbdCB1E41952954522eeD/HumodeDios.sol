// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// @title Humo de Dios - HUMO
// @author @David_LoDico

import "./ERC721A.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

contract HumodeDios is ERC721A, IERC2981, Ownable, ReentrancyGuard {
    // Address
    address private _baseWallet;

    // NFT collection values
    uint256 public constant MAX_SUPPLY = 69;
    uint256 public constant TOKEN_PRICE = 0 ether;
    uint256 public royaltyPercentage = 10;

    // // Track token count
    uint256 private _nextTokenIdNumber = 1;

    // Requires that the recipient is approved for transfer and minting
    bool public requiresApprovedAddress = true;

    // Track all the allowed addresses for transfer and minting
    mapping(address => bool) public addressApproved;

    // Metadata URIs
    string private _contractURI;
    string public baseURI;

    // Checks if token amount minted is within the max supply
    modifier whenSupplyAvailable(uint256 _numberOfTokens) {
        require(
            totalSupply() + _numberOfTokens <= MAX_SUPPLY,
            "Exceeds max supply"
        );
        _;
    }

    // Checks if it is required that the receiver is approved. If that is required, then check the approval status of the receiver
    modifier whenAddressIsApproved(address _address) {
        if (requiresApprovedAddress) {
            require(addressApproved[_address], "Address is not approved");
            _;
        }
        _;
    }

    // Check if correct ETH amount is send
    modifier whenCorrectEtherSent(uint256 _numberOfTokens) {
        require(
            msg.value == TOKEN_PRICE * _numberOfTokens,
            "Incorrect ether sent"
        );
        _;
    }

    constructor(
        address w1,
        string memory _startingContractURI,
        string memory _startingBaseURI
    ) ERC721A("Humo de Dios", "HUMO") {
        _baseWallet = w1;
        _contractURI = _startingContractURI;
        baseURI = _startingBaseURI;
    }

    /**
     * @notice Get contractURI
     * @return contractURI The URI for the collection metadata
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Get baseURI
     * @dev Overrides {ERC721A-_baseURI}
     * @return baseURI The base token URI for the collection
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Mint all available tokens to the _baseWallet
     */
    function teamClaim() external onlyOwner {
        require(totalSupply() == 0, "Tokens already claimed");

        _safeMint(_baseWallet, 69); // Community wallet
    }

    /**
     * @notice Before any transfer of ownership, check if the receiver needs approval.
     * @notice If so, then check the approval status of the receiver.
     * @dev Overrides {ERC721A-_beforeTokenTransfers}
     * @param _from The address of the sender
     * @param _to The address of the receiver
     * @param startTokenId The ID of the first token to be transferred
     * @param quantity The number of tokens to be transferred
     */
    function _beforeTokenTransfers(
        address _from,
        address _to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenAddressIsApproved(_to) {
        super._beforeTokenTransfers(_from, _to, startTokenId, quantity);
    }

    /**
     * @notice Sets the Base Wallet
     * @param _newBaseWallet The address of the new base wallet
     */
    function setBaseWallet(address _newBaseWallet) external onlyOwner {
        _baseWallet = _newBaseWallet;
    }

    /**
     * @notice Sets the Required Approved Address
     * @param _required boolean Whether or not the receiver needs approval
     */
    function setRequiresApprovedAddress(bool _required) external onlyOwner {
        requiresApprovedAddress = _required;
    }

    /**
     * @notice Set a single addres to either approved or not approved
     * @param _address The address to set
     * @param _approved boolean Whether or not the address is approved
     */
    function setAddressApproved(address _address, bool _approved)
        external
        onlyOwner
    {
        addressApproved[_address] = _approved;
    }

    /**
     * @notice Set a list of addresses to either approved or not approved
     * @param _addresses The list of addresses to set
     * @param _approved boolean Whether or not the addresses are approved
     */
    function setAddressApprovedList(address[] memory _addresses, bool _approved)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addressApproved[_addresses[i]] = _approved;
        }
    }

    /**
     * @notice Update the contractURI
     * @dev This is the collection level metadata URL
     * @param _newContractURI The new contractURI for the collection
     */
    function setContractURI(string memory _newContractURI) external onlyOwner {
        _contractURI = _newContractURI;
    }

    /**
     * @notice Update the baseURI
     * @dev Must include trailing slash
     * @param _newBaseURI The new baseURI for the collection
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Withdraw funds from the contract
     * @dev Community wallet 39.25%, Founder 18.22%, Design 15.19%, Story 15.19%, Dev 12.15%
     * @dev Any balance left is sent to the community wallet
     * @dev Prefer call pattern over transfer to prevent potential out of gas revert for multisigs
     */
    function withdraw() external nonReentrant {
        uint256 balance = address(this).balance;

        _internalWithdraw(balance, _baseWallet, 10000);

        (bool success, ) = payable(_baseWallet).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Internal withdraw function
     * @param _balance The balance to be split
     * @param _address The address to send the balance to
     * @param _split The % split of the balance to send to the address
     */
    function _internalWithdraw(
        uint256 _balance,
        address _address,
        uint256 _split
    ) private {
        (bool success, ) = payable(_address).call{
            value: (_balance / 10000) * _split
        }("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Declare support for interfaces used (IERC2981)
     * @dev Overrides {IERC165-supportsInterface}
     * @return bool Whether a checked interface is supported or not
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Set royalty info according to IERC2981 standard
     * @dev Royalties paid to the community wallet
     * @dev Overrides {IERC2981-royaltyInfo}
     * @return address The royalties reciever
     * @return royaltyAmount The amount to be paid
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address, uint256 royaltyAmount)
    {
        require(_exists(_tokenId), "Non-existent token");

        royaltyAmount = (_salePrice / 100) * royaltyPercentage;

        return (_baseWallet, royaltyAmount);
    }
}
