// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./ICards.sol";

/**
 * @title Cards
 */
contract Cards is ERC721Tradable, ICards {
    using SafeMath for uint256;

    // Name change token address
    address private _nctAddress;

    constructor(address _proxyRegistryAddress,  address nctAddress)
        ERC721Tradable("Parable", "PAR", _proxyRegistryAddress)
    {
      _nctAddress = nctAddress;
    }

    string public constant CARDS_PROVENANCE = "8a76b6238f7b5f14fefe90d2f176f9c9c3d410347d769e7183a25e95b78e4e69";  // Sha256 hash of the concatenated hashes of the image files
    uint256 public constant SALE_START_TIMESTAMP = 1630346400;  // Start date of the sale. timestamps in solidity are in seconds https://docs.soliditylang.org/en/latest/units-and-global-variables.html?highlight=block#block-and-transaction-properties
    // Time after which cards are randomized and allotted
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 14); // 14 days after release
    uint256 public constant NAME_CHANGE_PRICE = 1830 * (10 ** 18);  // Cost for changing the name of a Parable
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public constant MAX_NFT_SUPPLY = 42000;

    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _nameReserved;

    // Mapping from token ID to when the token was minted
    mapping (uint256 => uint256) private _mintTime;

    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;

    // Events
    event NameChange (uint256 indexed cardIndex, string newName);

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    /**
     * @dev Returns if the NFT has been minted before reveal phase
     */
    function isMintedBeforeReveal(uint256 index) override public view returns (bool) {
        return _mintTime[index] < REVEAL_TIMESTAMP;
    }

    /**
     * @dev Returns when the NFT has been minted
     */
    function mintedTimestamp(uint256 index) override public view returns (uint256) {
        return _mintTime[index];
    }

    function baseTokenURI() override public pure returns (string memory) {
        return "https://parablenft.com/api/parables/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://parablenft.com/api/contractmeta/";
    }

    /**
     * @dev Returns name of the NFT at index.
     */
    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    function mintNftTo(address _to) public onlyOwner {

      require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started");

      uint mintIndex = totalSupply().add(1);
      _mintTime[mintIndex] = block.timestamp;

      mintTo(_to);

      if (startingIndexBlock == 0 && (totalSupply() == MAX_NFT_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
          startingIndexBlock = block.number;
      }

    }

    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");

        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_NFT_SUPPLY;
        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
        if (block.number.sub(startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_NFT_SUPPLY;
        }
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
    }

    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        IERC20(_nctAddress).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);
        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        IERC20(_nctAddress).burn(NAME_CHANGE_PRICE);
        emit NameChange(tokenId, newName);
    }

    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Check if the name string is valid (Alphanumeric and spaces without leading or trailing space)
     */
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
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }


}
