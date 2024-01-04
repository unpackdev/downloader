pragma solidity >=0.7.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IMintedBeforeReveal.sol";

contract Rexes is ERC721, Ownable, IMintedBeforeReveal {

    // This is the original provenance record of all CyberRexes in existence at the time.
    string public constant CYBERREXES_PROVENANCE = "7325ec1daac9ff26ac1a0c9cce64deb2a76d7f0e1d0d31a0c19658414ad8457e";

    // Time of when the sale starts.
    uint256 public constant SALE_START_TIMESTAMP = 1616353200;

    // Time after which the CyberRexes are randomized and revealed (14 days from initial launch).
    uint256 public constant REVEAL_TIMESTAMP = SALE_START_TIMESTAMP + (86400 * 14);

    // Maximum amount of CyberRexes in existance. Ever.
    uint256 public constant MAX_CYBERREXES_SUPPLY = 10000;

    // The block in which the starting index was created.
    uint256 public startingIndexBlock;

    // The index of the item that will be #1.
    uint256 public startingIndex;

    // Mapping from token ID to name
    mapping (uint256 => string) private _tokenName;

    // Mapping if certain name string has already been reserved
    mapping (string => bool) private _nameReserved;

    // Mapping from token ID to whether the CyberRexes was minted before reveal.
    mapping (uint256 => bool) private _mintedBeforeReveal;

    // Events
    event NameChange (uint256 indexed rexIndex, string newName);

    constructor(string memory name, string memory symbol, string memory baseURI) ERC721(name, symbol) {
        _setBaseURI(baseURI);
    }

    /**
    * @dev Returns if the CyberRexes was minted before reveal phase. This could come in handy later.
    */
    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }

    /**
    * @dev Gets current CyberRexes price based on current supply.
    */
    function getRexMaxAmount() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_CYBERREXES_SUPPLY, "Sale has already ended, no more CyberRexes left to sell.");

        uint currentSupply = totalSupply();
        
        return 20; 
    }

    /**
    * @dev Gets current CyberRexes price based on current supply.
    */
    function getRexPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "Sale has not started yet so you can't get a price yet.");
        require(totalSupply() < MAX_CYBERREXES_SUPPLY, "Sale has already ended, no more CyberRexes left to sell.");

        uint currentSupply = totalSupply();

        if (currentSupply >= 9990) {
            return 3000000000000000000; // 9990 - 9999 3 ETH
        } else if (currentSupply >= 9700) {
            return 1300000000000000000; // 9700 - 9989 1.3 ETH
        } else if (currentSupply >= 9000) {
            return 900000000000000000; // 9000 - 9699 0.9 ETH
        } else if (currentSupply >= 7500) {
            return 500000000000000000; // 7500  - 8999 0.5 ETH
        } else if (currentSupply >= 5500) {
            return 300000000000000000; // 5500 - 7499 0.3 ETH
        } else if (currentSupply >= 3000) {
            return 100000000000000000; // 3000 - 5499 0.1 ETH
        } else if (currentSupply >= 1000) {
            return 50000000000000000; // 1000 - 2999 0.05 ETH
        } else {
            return 10000000000000000; // 0 - 999 0.01 ETH 
        }
    }

    /**
    * @dev Mints yourself a CyberRexes. Or more. You do you.
    */
    function mintRex(uint256 numberOfRexes) public payable {
        // Some exceptions that need to be handled.
        require(totalSupply() < MAX_CYBERREXES_SUPPLY, "Sale has already ended.");
        require(numberOfRexes > 0, "You cannot mint 0 CyberRexes.");
        require(numberOfRexes <= getRexMaxAmount(), "You are not allowed to buy this many CyberRexes at once in this price tier.");
        require(SafeMath.add(totalSupply(), numberOfRexes) <= MAX_CYBERREXES_SUPPLY, "Exceeds maximum CyberRex supply. Please try to mint less CyberRexes.");
        require(SafeMath.mul(getRexPrice(), numberOfRexes) == msg.value, "Amount of Ether sent is not correct.");

        // Mint the amount of provided CyberRexes.
        for (uint i = 0; i < numberOfRexes; i++) {
            uint mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        // Source of randomness. Theoretical miner withhold manipulation possible but should be sufficient in a pragmatic sense
        // Set the starting block index when the sale concludes either time-wise or the supply runs out.
        if (startingIndexBlock == 0 && (totalSupply() == MAX_CYBERREXES_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            startingIndexBlock = block.number;
        }
    }

    /**
    * @dev Finalize starting index
    */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "Starting index is already set");
        require(startingIndexBlock != 0, "Starting index block must be set");
        
        startingIndex = uint(blockhash(startingIndexBlock)) % MAX_CYBERREXES_SUPPLY;

        // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes).
        if (SafeMath.sub(block.number, startingIndexBlock) > 255) {
            startingIndex = uint(blockhash(block.number-1)) % MAX_CYBERREXES_SUPPLY;
        }

        // Prevent default sequence because that would be a bit boring.
        if (startingIndex == 0) {
            startingIndex = SafeMath.add(startingIndex, 1);
        }
    }

    /**
    * @dev Withdraw ether from this contract (Callable by owner only)
    */
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        msg.sender.transfer(balance);
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
    * @dev Changes the name for CyberRex tokenId
    */
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");
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

    /**
     * @dev Converts the string to lowercase
     */
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
    /**
    * @dev Changes the base URI if we want to move things in the future (Callable by owner only)
    */
    function changeBaseURI(string memory baseURI) onlyOwner public {
       _setBaseURI(baseURI);
    }
}