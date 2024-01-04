// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    function mint(address to, uint256 amount) external;
}


/**
 * @title BlockChainedELite
 * Limited run NFT collection of 2021's most popular pop culture icons
 * Inspired by the Mock provided by OpenZeppelin
 */
contract BlockChainedElite is ERC721, Ownable {
    using SafeMath for uint256;

    // state variables
    uint256 constant HotSaleLength = 14 days;
    uint256 start;

    // mapping
    mapping (uint256 => string) public tokenNames;
    mapping (string => bool) private nameReserved;
    mapping (uint256 => uint256) public flips;
    mapping (uint256 => string) public presetCID;

    // bce coin
    address private bceNCTAddress;
    address payable public adminAddress_1;
    address payable public adminAddress_2;

    bool public initialized;

    event Purchase(uint256 ID, address Purchaser);
    event NameChange(uint256 ID, string Name);

    modifier whileSale() { 
        require (block.timestamp <= start.add(HotSaleLength), "BCE: has ended");
        require (block.timestamp >= start, "BCE: has not started"); 
        _; 
    }

    constructor (string memory name, string memory symbol, uint256 _start, address payable _adminAddress_1, address payable _adminAddress_2, address _bceNCT) ERC721(name, symbol) { 
        start = _start;
        adminAddress_1 = _adminAddress_1;
        adminAddress_2 = _adminAddress_2;
        bceNCTAddress = _bceNCT;
        _setBaseURI("ipfs://");
        initialized = false;
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }    

    function mint(address to, uint256 tokenId) private {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function purchase(uint256 tokenId) payable public whileSale{
        if(_exists(tokenId)){
            address prevOwner = ownerOf(tokenId);
            
            // get price and require this payment to be sent
            require(msg.value == getPrice(tokenId), "BCE: Invalid Price");
            require (prevOwner != _msgSender(), "BCE: Already Owned");
            
            _transfer(prevOwner, _msgSender(), tokenId);

            // split ETH 70% owner 30% stays in BCE
            uint256 amountToOwner = (((msg.value).div(100)).mul(70));
            address(prevOwner).call{value: amountToOwner}('');
            uint256 remaining = (msg.value).sub(amountToOwner);
            splitFee(remaining);

            // add to flips
            flips[tokenId] = flips[tokenId].add(1);

            // emit purchase of token
            Purchase(tokenId, _msgSender());

        } else{
            //require this ID to be valid -- min if correct ETH
            require (tokenId <= 100, "BCE: Invalid");
            require (tokenId >= 1, "BCE: Invalid");
            require (msg.value == 5e16, "BCE: 0.05 ETH");
            
            //mint
            _safeMint(_msgSender(), tokenId);
            _setTokenURI(tokenId, presetCID[tokenId]);
            splitFee(msg.value);

            flips[tokenId] = 1;
        }

        //if successful, mint the corresponding amount of bceNCT
        IERC20(bceNCTAddress).mint(_msgSender(),(msg.value).mul(1000));
    }

    function setBatchPresetTokenCID(uint256[] memory ids, string[] memory uris) onlyOwner external {
        require(!initialized, "BCE: initialized");
        for(uint256 i = 0; i < ids.length; i++){
            presetCID[ids[i]] = uris[i];
        }
        initialized = true;
    }

    function getPrice(uint256 tokenId) public view returns(uint256) {
        return((uint256(5e16)).mul(2**flips[tokenId]));
    }

    function splitFee(uint256 amount) internal {
        uint256 remaining_1 = ((amount).div(100)).mul(80);
        uint256 remaining_2 = (amount).sub(remaining_1);
        address(adminAddress_1).call{value: remaining_1}('');
        address(adminAddress_2).call{value: remaining_2}('');
    }
   
    /**
     * @dev Reserves the name if isReserve is set to true, de-reserves if set to false
     */
    function toggleReserveName(string memory str, bool isReserve) internal {
        nameReserved[toLower(str)] = isReserve;
    }

    /**
     * @dev Returns if the name has been reserved.
     */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return nameReserved[toLower(nameString)];
    }

    /**
     * @dev Changes the name for given tokenId
     */
    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "BCE: Ownership");
        require(validateName(newName) == true, "BCE: Invalid");
        require(sha256(bytes(newName)) != sha256(bytes(tokenNames[tokenId])), "BCE: Used");
        require(isNameReserved(newName) == false, "BCE: Taken");

        IERC20(bceNCTAddress).transferFrom(_msgSender(), address(this), 1e20);

        // If already named, dereserve old name
        if (bytes(tokenNames[tokenId]).length > 0) {
            toggleReserveName(tokenNames[tokenId], false);
        }

        toggleReserveName(newName, true);
        tokenNames[tokenId] = newName;
        IERC20(bceNCTAddress).burn(1e20);
        emit NameChange(tokenId, newName);
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

    function marketRead() public view returns(uint256[] memory, uint256[] memory, string[] memory){
        uint256[] memory _flips = new uint256[](100);
        uint256[] memory _prices= new uint256[](100);
        string[] memory _names= new string[](100);

        for (uint256 i=0;i<100;i++){
            _flips[i] = flips[i+1];
            _prices[i] = getPrice(i+1);
            _names[i] = tokenNames[i+1];
        }

        return (_flips, _prices, _names);
    }


}