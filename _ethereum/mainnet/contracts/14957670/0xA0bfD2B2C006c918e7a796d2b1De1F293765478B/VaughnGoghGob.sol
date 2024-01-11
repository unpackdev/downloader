// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract VaughnGoghGob is Ownable, ERC721A, ReentrancyGuard {
    uint256 private immutable MAX_TOKEN_SUPPLY;
    uint256 public maxPerAddress;
    uint256 public maxPerTransaction;
    bool public publicFlag;
    mapping(address => uint256) public allowlist;

    string private baseURI;
    string private presaleURI;
    string public uriExtension;


    // --------------------------------------------------------------
    // EVENTS
    // --------------------------------------------------------------

    event BaseURIUpdated(string uri);
    event TokenURIExtentionSet(string extention);
    event NewPublicMintPriceSet(uint256 newPrice);
    event PresaleURIUpdated(string uri);
    event FlagSwitched(bool value);


    // --------------------------------------------------------------
    // CUSTOM ERRORS
    // --------------------------------------------------------------

    error PublicMintNotActive();
    error InsufficientEth();
    error MintExceedsMaxPerAddress();
    error NftIDOutOfRange();
    error MintExceedsMaxSupply();
    error WithdrawEthFailed();
    error OnlyOwnerOfTokenCanSetDarkMode();
    error NoChangeToDarkModeValue();

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 maxBatchSize_,
        uint256 maxPerAddress_,
        uint256 maxTokenSupply_
    ) ERC721A(_name, _symbol){
        MAX_TOKEN_SUPPLY = maxTokenSupply_;
        maxPerAddress = maxPerAddress_;
        maxPerTransaction = maxBatchSize_;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function allowlistMint(uint256 quantity) external payable callerIsUser {
        require(
        publicFlag == false,
        "Public mint is live. AL minting is over"
        );
        require(allowlist[msg.sender] > 0, "Not eligible for any allowlist mint");
        require(allowlist[msg.sender] >= quantity, "Not eligible to mint this many");
        require(totalSupply() + quantity <= MAX_TOKEN_SUPPLY, "reached max supply");
        allowlist[msg.sender] = allowlist[msg.sender] - quantity;
        _safeMint(msg.sender, quantity);
    }
    
    function publicSaleMint(uint256 quantity)
        external
        payable
        callerIsUser
    {
        require(
        publicFlag == true,
        "public sale has not begun yet"
        );
        require(quantity <= maxPerTransaction, "exceeded mints per transaction");
        require(totalSupply() + quantity <= MAX_TOKEN_SUPPLY, "reached max supply");
        require(
        numberMinted(msg.sender) + quantity <= maxPerAddress,
        "can not mint this many"
        );
        _safeMint(msg.sender, quantity);
    }

  
    // --------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    // --------------------------------------------------------------

    function switchPublicFlag(bool state) public onlyOwner {
        string memory boolString = state == true ? "true" : "false";
        require(publicFlag != state, string(abi.encodePacked("Phase Status already ", boolString)));
        publicFlag = state;
        emit FlagSwitched(state);
    }

    function setPresaleURI(string memory uri) external onlyOwner {
        presaleURI = uri;
        emit PresaleURIUpdated(uri);
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
        emit BaseURIUpdated(_baseURI);
    }

    function setURIExtention(string memory _extention) public onlyOwner {
        uriExtension = _extention;
        emit TokenURIExtentionSet(_extention);
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        if (!os) revert WithdrawEthFailed();
    }

    function setMaxPerAddress(uint256 _maxPerAddress) external onlyOwner{
        maxPerAddress = _maxPerAddress;
    }

    function setMaxPerTransaction(uint256 _maxPerTx) external onlyOwner{
        maxPerTransaction = _maxPerTx;
    }

    function seedTeamList(address[] memory addresses, uint256[] memory numSlots)
        external
        onlyOwner
    {
        require(
        addresses.length == numSlots.length,
        "addresses do not match numSlots length"
        );
        for (uint256 i = 0; i < addresses.length; i++) {
        allowlist[addresses[i]] = numSlots[i];
        }
    }

    // VIEW FUNCTIONS //
    function tokenURI(uint256 _tokenID) public view override returns (string memory) {
        if (_tokenID > totalSupply()) revert NftIDOutOfRange();
        if (!_exists(_tokenID)) revert URIQueryForNonexistentToken();
        if (bytes(baseURI).length == 0) {
            return presaleURI;
        } else {
            return string(abi.encodePacked(baseURI, toString(_tokenID), uriExtension));
        }
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return _ownershipOf(tokenId);
    }

    /**
     * @dev from OpenZeppelin
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}