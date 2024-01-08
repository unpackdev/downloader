// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.3;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract StarNFT is ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Address of interface identifier for royalty standard
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 public MAX_MINT = 20;

    // Timestamp for activating crowdsale
    uint256 public activationTimestamp;

    // Timestamp for activating presale
    uint256 public presaleTimestamp;
    
    // Timestamp for stopping presale
    uint256 public presaleEndTimestamp;

    // Maximum amount of tokens at presale
    uint256 public maxPresaleAmount;

    // Prepend baseURI to tokenId
    string private baseURI;

    // Address of payment splitter contract
    address public beneficiary;

    // Max supply of total tokens
    uint256 public maxSupply = 4444;

    // Max number of reserved tokens
    uint256 public maxReserve;

    // Boolean value for locking metadata
    bool public metadataFrozen = false;

    // Mint price of each token in Wei 
    uint256 public mintPrice;

    // Presale price of each token in Wei 
    uint256 public presalePrice;

    // Number of public tokens minted
    uint256 private numPublicMinted;

    // Number of reserve tokens claimed
    uint256 private numReserveClaimed;

    // Royalty percentage for secondary sales
    uint256 public royaltyPercentage = 3;

    mapping (uint256 => string) private _tokenName;

    mapping (string => bool) private _nameReserved;

    // Events
    event NameChange (uint256 indexed pepeIndex, string newName);

    constructor(
        string memory _initialBaseURI,
        uint256 _activationTimestamp,
        uint256 _presaleStartTimestamp,
        uint256 _presaleEndTimestamp,
        uint256 _maxReserve,
        uint256 _mintPrice,
        uint256 _presalePrice,
        uint256 _maxPresaleAmount,
        address _beneficiary
    ) ERC721("StarNFT", "SLR") {
        baseURI = _initialBaseURI;
        activationTimestamp = _activationTimestamp;
        presaleTimestamp = _presaleStartTimestamp;
        presaleEndTimestamp = _presaleEndTimestamp;
        presalePrice = _presalePrice;
        mintPrice = _mintPrice;
        beneficiary = _beneficiary;
        maxReserve = _maxReserve;
        maxPresaleAmount = _maxPresaleAmount;
    }

    /**
     * @dev Mints specified number of tokens in a single transaction
     * @param _amount Total number of tokens to be minted and sent to `_msgSender()`
    * 
     * Requirements:
     *
     * - `amount` must be less than max limit for a single transaction
     * - `msg.value` must be exact payment amount in wei
     * - `numPublicMinted` plus amount must not exceed max public supply
     */
    function mint(uint256 _amount) public payable {
        bool isPresale = presaleTimestamp <= block.timestamp && presaleEndTimestamp >= block.timestamp;
        require(activationTimestamp <= block.timestamp || isPresale, "Minting has not yet begun");
        require(_amount <= MAX_MINT, "The max mint amount in a single transaction is limited");
        require((isPresale ? presalePrice : mintPrice) * _amount == msg.value, "Incorrect payment amount");
        require(!isPresale || numPublicMinted + _amount <= maxPresaleAmount, "No more tokens available to presale mint");
        require(numPublicMinted + _amount <= maxSupply - maxReserve, "No more public tokens available to mint");

        numPublicMinted += _amount;
        _mint(_amount, _msgSender());

        payable(beneficiary).transfer(msg.value);
    }

    /**
     * @dev Mints specified number of tokens to a recipient
     * @param _amount Number of tokens to be minted
     * @param _recipient Address of recipient to transfer tokens to
     *
     * Requirements:
     *
     * - `activationTimestamp` must be less than or equal to the current block time
     * - `currentTotal` in addition to mint `amount` must not exceed the `maxSupply`
     */
    function _mint(uint256 _amount, address _recipient) private {
        require(_tokenIds.current() + _amount <= maxSupply, "Insufficienct number of tokens available");

        for (uint256 i = 0; i < _amount; i++) {
            uint256 newItemId = _tokenIds.current();
            _tokenIds.increment();
            _safeMint(_recipient, newItemId);
        }
    }

    /**
     * @dev Mints specified amount of tokens to list of recipients
     * @param _amount Number of tokens to be minted for each recipient
     * @param _recipients List of addresses to send tokens to
     *
     * Requirements:
     *
     * - `owner` must be function caller
     * - `numReserveClaimed` must not exceed the total max reserve
     */
    function mintReserved(uint256 _amount, address[] memory _recipients) public onlyOwner {
        numReserveClaimed += _recipients.length * _amount;
        require(numReserveClaimed <= maxReserve, "No more reserved tokens available to claim");

        for (uint256 i = 0; i < _recipients.length; i++) {
            _mint(_amount, _recipients[i]);
        }
    }


    /**
     * @dev Sets mint price
     * @param _mintPrice New mint price 
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * @dev Updates pre-sale information
     * @param _presalePrice New presale price
     * @param _presaleStart New presale start timestamp
     * @param _presalePrice New presale end timestamp
     *
     * Requirement:s
     *
     * - `owner` must be function caller
     */
    function updatePresaleInformation(uint256 _presalePrice, uint256 _presaleStart, uint256 _presaleEnd, uint256 _maxPresaleAmount) public onlyOwner {
        presalePrice = _presalePrice;
        presaleTimestamp = _presaleStart;
        presaleEndTimestamp = _presaleEnd;
        maxPresaleAmount = _maxPresaleAmount;
    }

    /**
     * @dev Mints specified amount of tokens to list of recipients
     * @param _maxReserve New amount of reserved tokens 
     *
     * Requirements:
     *
     * - `owner` must be function caller
     * - `_maxReserve` must not be less than `numReserveClaimed`
     * - `_maxReserve` must not be more than `maxReserve`
     */
    function setMaxReserve(uint256 _maxReserve) public onlyOwner {
        require(_maxReserve < maxReserve, "New reserved amount should be less than current reserved amount");
        require(_maxReserve >= numReserveClaimed, "New reserved amount should be less than claimed reserved amount");
        maxReserve = _maxReserve;
    }
    
    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }
    
    /**
     * @dev Changes the name for Neural Pepe tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public {
        require(_msgSender() == ownerOf(tokenId), "ERC721: caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        emit NameChange(tokenId, newName);
    }

    /**
     * @dev See {IERC721-baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Sets the baseURI with the official metadataURI
     * @param _newBaseURI Metadata URI used for overriding initialBaseURI
     *
     * Requirements:
     *
     * - `owner` must be function caller
     * - `metadataFrozen` must be false
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(metadataFrozen == false, "Metadata can no longer be altered");

        baseURI = _newBaseURI;
    }

    /**
     * @dev freezes the metadata URI so it can't be changed
     *
     * Requirements:
     *
     * - `owner` must be function caller
     */
    function freezeMetadata() public onlyOwner {
        metadataFrozen = true;
    }

    /**
     * @dev See {IERC2981-royaltyInfo}.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
        _tokenId; // silence solc warning
        royaltyAmount = (_salePrice * royaltyPercentage) / 100;

        return (beneficiary, royaltyAmount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC2981 || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    function validateName(string memory str) public pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 25) return false; // Cannot be longer than 25 characters
        if(b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
                return false;

            lastChar = char;
        }

        return true;
    }

    function toLower(string memory str) public pure returns (string memory){
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bStr[i] = bytes1(uint8(bStr[i]) + 32);
            }
        }
        return string(bStr);
    }
}