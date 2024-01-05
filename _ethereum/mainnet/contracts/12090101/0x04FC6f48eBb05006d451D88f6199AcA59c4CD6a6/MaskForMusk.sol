// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./CosmoMasksERC721.sol";

interface IERC20BurnTransfer {
    function burn(uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ICosmoTokenMint {
    function mintToFund(uint256 amount) external returns (bool);
}


contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


// https://eips.ethereum.org/EIPS/eip-721 tokenURI
/**
 * @title MaskForMusk contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract MaskForMusk is Ownable, CosmoMasksERC721 {
    using SafeMath for uint256;

    // This is the provenance record of all MaskForMusk artwork in existence
    uint256 public constant NAME_CHANGE_PRICE = 1830e18;
    uint256 public constant MAX_SUPPLY = 7;
    string  public constant PROVENANCE = "4bda02a6364e150b73c88618f7e2e96a4f31531735bfbf29a8218a4ac8aa1756";

    // Mapping from token ID to name
    mapping(uint256 => string) private _tokenName;
    // Mapping if certain name string has already been reserved
    mapping(string => bool) private _nameReserved;

    address private _cosmoToken = 0x27cd7375478F189bdcF55616b088BE03d9c4339c;
    address private _cmpAddress = 0xB9FDc13F7f747bAEdCc356e9Da13Ab883fFa719B;
    address proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    string private _contractURI;

    event NameChange(uint256 indexed tokenId, string newName);

    constructor() public CosmoMasksERC721("MaskForMusk", "MUSK") {
        _setBaseURI("https://TheCosmoMasks.com/mask-for-musk-metadata/");
        _setURL("https://TheCosmoMasks.com/");
        _contractURI = "https://TheCosmoMasks.com/mask-for-musk-contract-metadata.json";
    }

    function getCosmoToken() public view returns (address) {
        return _cosmoToken;
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
    * @dev Mints Masks
    */
    function mint(address owner, uint256 numberOfMasks) public onlyOwner {
        require(totalSupply() < MAX_SUPPLY, "MaskForMusk: sale has already ended");
        require(totalSupply().add(numberOfMasks) <= MAX_SUPPLY, "MaskForMusk: Exceeds MAX_SUPPLY");

        for (uint256 i = 0; i < numberOfMasks; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(owner, mintIndex);
            ICosmoTokenMint(_cosmoToken).mintToFund(1e24);
        }
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
     * @dev Changes the name for CosmoMask tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "MaskForMusk: caller is not the token owner");
        require(validateName(newName) == true, "MaskForMusk: not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])), "MaskForMusk: new name is same as the current one");
        require(isNameReserved(newName) == false, "MaskForMusk: name already reserved");

        IERC20BurnTransfer(_cmpAddress).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
        IERC20BurnTransfer(_cmpAddress).burn(NAME_CHANGE_PRICE);
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

    function setCosmoToken(address token) public onlyOwner {
        require(_cosmoToken == address(0), "MaskForMusk: CosmosToken has already setted");
        require(token != address(0), "MaskForMusk: CosmoToken is the zero address");
        _cosmoToken = token;
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
