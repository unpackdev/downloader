// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./CosmoDoodleERC721.sol";

interface IERC20BurnTransfer {
    function burn(uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC20BurnTransfer2 {
    function burn(uint256 amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ICosmoDoodle {
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}


contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


// https://eips.ethereum.org/EIPS/eip-721 tokenURI
/**
 * @title CosmoDoodle contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract CosmoDoodle is Ownable, CosmoDoodleERC721, ICosmoDoodle {
    using SafeMath for uint256;

    // This is the provenance record of all CosmoDoodle artwork in existence
    uint256 public constant COSMO_PRICE = 1_500_000_000_000e18;
    uint256 public constant CUP_PRICE = 7_500e18;
    uint256 public constant NAME_CHANGE_PRICE = 1_830e18;
    
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant MAX_SUPPLY = 16410;
    string  public constant PROVENANCE = "d13299f09395904e2a53366161121cd8f1250bce078afb73b34d410c8bdabb24";
    uint256 public constant SALE_START_TIMESTAMP = 1625410800; // "2021-07-04T15:00:00.000Z"
    // Time after which CosmoDoodle are randomized and allotted
    uint256 public constant REVEAL_TIMESTAMP = 1626620400; // "2021-07-18T15:00:00.000Z"

    uint256 public startingIndexBlock;
    uint256 public startingIndex;

    // tokens
    address public nftPower;
    address public constant tokenCosmo = 0x27cd7375478F189bdcF55616b088BE03d9c4339c;
    address public constant tokenCup = 0x1faDbb8D7c2D84DAad1c6f52f92480ceF8c96024;

    address public proxyRegistryAddress;
    string private _contractURI;

    // Mapping from token ID to name
    mapping(uint256 => string) private _tokenName;
    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;
    // Mapping from token ID to whether the CosmoMask was minted before reveal
    mapping(uint256 => bool) private _mintedBeforeReveal;

    event NameChange(uint256 indexed tokenId, string newName);
    event SetStartingIndexBlock(uint256 startingIndexBlock);
    event SetStartingIndex(uint256 startingIndex);


    constructor(address _nftPowerAddress, address _proxyRegistryAddress) public CosmoDoodleERC721("CosmoDoodle", "COSDDL") {
        nftPower = _nftPowerAddress;
        proxyRegistryAddress = _proxyRegistryAddress;
        _setURL("https://thecosmodoodle.com/");
        _setBaseURI("https://thecosmodoodle.com/metadata/");
        _contractURI = "https://thecosmodoodle.com/metadata/contract.json";
    }


    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns name of the CosmoMask at index.
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
     * @dev Returns if the CosmoMask has been minted before reveal phase
     */
    function isMintedBeforeReveal(uint256 index) public view override returns (bool) {
        return _mintedBeforeReveal[index];
    }

    /**
     * @dev Gets current CosmoMask Price
     */
    function getPrice() public view returns (uint256) {
        require(block.timestamp >= SALE_START_TIMESTAMP, "CosmoDoodle: sale has not started");
        require(totalSupply() < MAX_SUPPLY, "CosmoDoodle: sale has already ended");

        uint256 currentSupply = totalSupply();

        if (currentSupply >= 16409) {
            return 3_000_000e18;
        } else if (currentSupply >= 16407) {
            return 300_000e18;
        } else if (currentSupply >= 16400) {
            return 30_000e18;
        } else if (currentSupply >= 16381) {
            return 3_000e18;
        } else if (currentSupply >= 16000) {
            return 300e18;
        } else if (currentSupply >= 15000) {
            return 51e18;
        } else if (currentSupply >= 11000) {
            return 27e18;
        } else if (currentSupply >= 7000) {
            return 15e18;
        } else if (currentSupply >= 3000) {
            return 9e18;
        } else {
            return 3e18;
        }
    }

    /**
    * @dev Mints CosmoDoodle
    */
    function mint(uint256 numberOfMasks) public payable {
        require(totalSupply() < MAX_SUPPLY, "CosmoDoodle: sale has already ended");
        require(numberOfMasks > 0, "CosmoDoodle: numberOfMasks cannot be 0");
        require(numberOfMasks <= 20, "CosmoDoodle: You may not buy more than 20 CosmoDoodle at once");
        require(totalSupply().add(numberOfMasks) <= MAX_SUPPLY, "CosmoDoodle: Exceeds MAX_SUPPLY");
        require(getPrice().mul(numberOfMasks) == msg.value, "CosmoDoodle: Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfMasks; i++) {
            uint256 mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        if (startingIndex == 0 && (totalSupply() == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            _setStartingIndex();
        }
    }

    function mintByCosmo(uint256 numberOfMasks) public {
        require(totalSupply() < MAX_SUPPLY, "CosmoDoodle: sale has already ended");
        require(numberOfMasks > 0, "CosmoDoodle: numberOfMasks cannot be 0");
        require(numberOfMasks <= 20, "CosmoDoodle: You may not buy more than 20 CosmoDoodle at once");
        require(totalSupply().add(numberOfMasks) <= (MAX_SUPPLY - 10), "CosmoDoodle: The last 10 masks can only be purchased for ETH");

        uint256 purchaseAmount = COSMO_PRICE.mul(numberOfMasks);
        require(
            IERC20BurnTransfer(tokenCosmo).transferFrom(msg.sender, address(this), purchaseAmount),
            "CosmoDoodle: Transfer COSMO amount exceeds allowance"
        );

        for (uint256 i = 0; i < numberOfMasks; i++) {
            uint256 mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        if (startingIndex == 0 && (totalSupply() == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            _setStartingIndex();
        }

        IERC20BurnTransfer(tokenCosmo).burn(purchaseAmount);
    }

    function mintByCup(uint256 numberOfMasks) public {
        require(totalSupply() < MAX_SUPPLY, "CosmoDoodle: sale has already ended");
        require(numberOfMasks > 0, "CosmoDoodle: numberOfMasks cannot be 0");
        require(numberOfMasks <= 20, "CosmoDoodle: You may not buy more than 20 CosmoDoodle at once");
        require(totalSupply().add(numberOfMasks) <= (MAX_SUPPLY - 10), "CosmoDoodle: The last 10 masks can only be purchased for ETH");

        uint256 purchaseAmount = CUP_PRICE.mul(numberOfMasks);
        require(
            IERC20BurnTransfer2(tokenCup).transferFrom(msg.sender, address(this), purchaseAmount),
            "CosmoDoodle: Transfer CUP amount exceeds allowance"
        );

        for (uint256 i = 0; i < numberOfMasks; i++) {
            uint256 mintIndex = totalSupply();
            if (block.timestamp < REVEAL_TIMESTAMP) {
                _mintedBeforeReveal[mintIndex] = true;
            }
            _safeMint(msg.sender, mintIndex);
        }

        if (startingIndex == 0 && (totalSupply() == MAX_SUPPLY || block.timestamp >= REVEAL_TIMESTAMP)) {
            _setStartingIndex();
        }

        IERC20BurnTransfer2(tokenCup).burn(purchaseAmount);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev Finalize starting index
     */
    function finalizeStartingIndex() public {
        require(startingIndex == 0, "CosmoDoodle: starting index is already set");
        require(block.timestamp >= REVEAL_TIMESTAMP, "CosmoDoodle: Too early");
        _setStartingIndex();
    }

    function _setStartingIndex() internal {
        startingIndexBlock = block.number - 1;
        emit SetStartingIndexBlock(startingIndexBlock);

        startingIndex = uint256(blockhash(startingIndexBlock)) % 16400;
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }
        emit SetStartingIndex(startingIndex);
    }

    /**
     * @dev Changes the name for CosmoMask tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "CosmoDoodle: caller is not the token owner");
        require(validateName(newName) == true, "CosmoDoodle: not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "CosmoDoodle: new name is same as the current one");
        require(isNameReserved(newName) == false, "CosmoDoodle: name already reserved");

        IERC20BurnTransfer(nftPower).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        IERC20BurnTransfer(nftPower).burn(NAME_CHANGE_PRICE);
        emit NameChange(tokenId, newName);
    }

    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        msg.sender.transfer(balance);
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
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1)
            return false;
        // Cannot be longer than 25 characters
        if (b.length > 25)
            return false;
        // Leading space
        if (b[0] == 0x20)
            return false;
        // Trailing space
        if (b[b.length - 1] == 0x20)
            return false;

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];
            // Cannot contain continous spaces
            if (char == 0x20 && lastChar == 0x20)
                return false;
            if (
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
    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90))
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            else
                bLower[i] = bStr[i];
        }
        return string(bLower);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function setURL(string memory newUrl) public onlyOwner {
        _setURL(newUrl);
    }
}
