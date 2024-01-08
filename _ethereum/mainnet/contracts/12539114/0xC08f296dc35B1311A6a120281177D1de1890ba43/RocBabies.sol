// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

// For Truffle Deployment
import "./ERC721.sol";
import "./Ownable.sol";

// For Remix
// import "./ERC721.sol";
// import "./Ownable.sol";

contract Rocbabies is ERC721, Ownable {
    using SafeMath for uint256;
    uint public constant MAX_BABIES = 10000;
    uint public NAME_CHANGE_FEE = 1500000000000000; // 0.0015 ETH
    bool public hasSaleStarted = false;
    uint256 public EARLY_BIRD_PRICE = 30000000000000000; // 0.03 ETH
    uint256 public LATE_BIRD_PRICE = 60000000000000000; // 0.06 ETH
    
    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;
    
    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _nameReserved;

    // Events
    event NameChange (uint256 indexed maskIndex, string newName);

    // The IPFS hash for all items
    string public METADATA_PROVENANCE_HASH = "";

    constructor(string memory baseURI) ERC721("Rocbabies","ROCBABIES")  {
        setBaseURI(baseURI);
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function calculatePrice() public view returns (uint256) {
        require(hasSaleStarted == true, "Sale hasn't started yet");
        require(totalSupply() < MAX_BABIES, "Maximum babies are adopted.");

        uint currentSupply = totalSupply();
        if (currentSupply >= 5000) {
            return LATE_BIRD_PRICE;        // 5000-9999
        } else {
            return EARLY_BIRD_PRICE;        // 0 - 4999
        }
    }

    function calculatePriceForToken(uint _id) public view returns (uint256) {
        require(_id < MAX_BABIES, "Maximum babies are adopted.");

        if (_id >= 5000) {
            return LATE_BIRD_PRICE;          // 5000-9999
        } else {
            return EARLY_BIRD_PRICE;          // 0 - 4999
        }
    }
    
    function adoptBabies(uint256 numBabies) external payable {
        require(totalSupply() < MAX_BABIES - 1, "Maximum babies are adopted.");
        require(numBabies > 0 && numBabies <= 20, "You can adopt minimum 1, maximum 20 babies");
        require(totalSupply().add(numBabies) <= MAX_BABIES - 1, "Exceeds MAX_BABIES");
        require(msg.value >= calculatePrice().mul(numBabies), "Ether value sent is below the price");

        for (uint i = 0; i < numBabies; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);

            string memory newName = strConcat("Rocbabies #", uint2str(mintIndex));
            toggleReserveName(newName, true);
            _tokenName[mintIndex] = newName;
        }
    }
    
    // Use this at the beginning to reserve some babies for giveaways.
    function adoptBabiesByOwner(uint256 numBabies, address _receiver) external onlyOwner {
        uint currentSupply = totalSupply();
        require(currentSupply.add(numBabies) <= 30 || currentSupply == MAX_BABIES.sub(1), "Owner can only adopt #0 ~ #29 or #9999 with this function.");
        require(currentSupply.add(numBabies) <= MAX_BABIES, "Exceeds MAX_BABIES");

        uint256 index;
        for (index = 0; index < numBabies; index++) {
            uint mintIndex = currentSupply + index;
            _safeMint(_receiver, mintIndex);
            
            string memory newName = strConcat("Rocbabies #", uint2str(mintIndex));
            toggleReserveName(newName, true);
            _tokenName[mintIndex] = newName;
        }
    }
    
    // Set Provenance Hash when we reveal all the items and fix all meta data.
    function setProvenanceHash(string memory _hash) external onlyOwner {
        METADATA_PROVENANCE_HASH = _hash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setEarlyBirdPrice(uint256 price) external onlyOwner {
        require(hasSaleStarted == false, "Sale has already started");
        require(totalSupply() <= 30, "Early Bird tier already stared");
        EARLY_BIRD_PRICE = price;
    }

    function setLateBirdPrice(uint256 price) external onlyOwner {
        require(totalSupply() < 5000, "Late bird tier already started");
        LATE_BIRD_PRICE = price;
    }

    function setNameChangeFee(uint256 price) external onlyOwner {
        NAME_CHANGE_FEE = price;
    }
    
    function startSale() external onlyOwner {
        hasSaleStarted = true;
    }
    function pauseSale() external onlyOwner {
        hasSaleStarted = false;
    }
    
    function withdrawAll() external payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }

    /**
     * Changeing Name Utilities
     */
    function changeName(uint256 tokenId, string memory newName) external payable {
        address owner = ownerOf(tokenId);
        require(msg.value >= NAME_CHANGE_FEE, "Ether value sent is below the fee cost");
        require(_msgSender() == owner, "Caller is not the owner");
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

    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
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

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        return string(babcde);
    }
}