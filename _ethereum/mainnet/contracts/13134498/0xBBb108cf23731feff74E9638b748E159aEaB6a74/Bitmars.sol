// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external returns (bool);
}

contract BitMars is ERC721Enumerable, ERC721Burnable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256;

    event PlotMinted(
        address who,
        uint256 indexed tokenId
        );

    event NameChanged(
        uint256 indexed tokenId,
        string oldName,
        string newName
        );

    //Provenance Record of all Bit Mars Plots.
    string public BITMARS_PROVENANCE = "";

    string public baseTokenURI;

    string public _contractURI;

    uint256 public constant MAX_PLOTS = 6144;

    uint256 public constant MAX_MINTABLE_AT_ONCE = 20;

    uint256 private leftToReserve = 200;

    uint256 private _numOfAvailableTokens = 6144;

    uint256[6144] private _availableTokens;

    uint256 public NAME_CHANGE_PRICE = 10000 * (10 ** 18);

    bool public isSaleActive;

    address private _creditsAddress;

    mapping(uint256 => string) private _tokenIdToName;

    mapping(string => bool) private _nameReserved;

    constructor(string memory baseURI, string memory contractURI)
    ERC721('Bit Mars', 'MARS')
    {
        setURI(baseURI,contractURI);
    }

    function setURI(string memory baseURI, string memory contractURI) public onlyOwner returns(bool) {
        baseTokenURI = baseURI;
        _contractURI = contractURI;
        return true;
    }

    function setProvenanceHash(string memory _hash) public onlyOwner {
        BITMARS_PROVENANCE = _hash;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for non-existant token");

        string memory _tokenURI = Strings.toString(_tokenId);
        string memory base = _baseURI();

        return bytes(base).length == 0 ? _tokenURI : string(abi.encodePacked(base, _tokenURI));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenNameByIndex (uint256 index) public view returns (string memory) {
        return _tokenIdToName[index];
    }

    function _getPrice() public view returns (uint256) {
        require(isSaleActive, "Sale has not started.");
        require(totalSupply() < MAX_PLOTS,"Sale has already ended.");

        uint256 currentSupply = totalSupply();
        uint256 result;

        if (currentSupply >= 4125) {
            result = 0.09 ether;
            return result;
        } else if (currentSupply >= 2163) {
            result = 0.06 ether;
            return result;
        } else {
            result = 0.03 ether;
            return result;
        }
    }

    function mint(uint256 _numberToMint) public payable nonReentrant() {
        require(isSaleActive, "Sale not yet started.");
        require(totalSupply() < MAX_PLOTS, "Sale has already ended.");
        require(_numberToMint > 0 && _numberToMint <= 20, "Cannot mint 0, or more than 20 Plots");
        require(totalSupply().add(_numberToMint) <= MAX_PLOTS, "Too many plots.");
        require(_getPrice().mul(_numberToMint) <= msg.value, "Ether value sent too small.");

        _mint(_numberToMint);

    }

    function _mint(uint256 _numberToMint) internal {
        require(_numberToMint > 0 && _numberToMint <= 20, "Cannot mint 0, or more than 20 Plots");
        uint256 updatedNumAvailableTokens = _numOfAvailableTokens;
        for (uint256 i = 0; i < _numberToMint; i++) {
            uint256 RandomTokenId = _useRandomAvailableToken(_numberToMint, i);
            updatedNumAvailableTokens--;
            _safeMint(msg.sender,RandomTokenId);
            emit PlotMinted(msg.sender, RandomTokenId);
        }
        _numOfAvailableTokens = updatedNumAvailableTokens;

    }

    function reserve(uint256 _numberOfPlots) public onlyOwner {
        require(_numberOfPlots <= leftToReserve, "Already Reserved 200");
        require(totalSupply().add(_numberOfPlots) <= MAX_PLOTS, "Exceeds MAX_PLOTS");
        for ( uint256 i = 0; i < _numberOfPlots; i++) {
            uint256 index = totalSupply();
            leftToReserve--;
            _safeMint(msg.sender, index);
            emit PlotMinted(msg.sender, index);
        }
    }

    function toggleSaleAndReturnSaleState() public onlyOwner returns(bool) {
        isSaleActive = !isSaleActive;
        return isSaleActive;
    }

    function withdraw() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
    }

    function forwardERC20s(IERC20 _token, address _to, uint256 _amount) public onlyOwner {
        require(address(_to) != address(0), "can not send to zero address.");
        _token.transfer(_to, _amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
        ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function setCreditsAddress(address _address) external onlyOwner {
        _creditsAddress = _address;
    }

    function changeName(uint256 tokenId, string memory newName) public {
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_tokenIdToName[tokenId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        string memory oldName = _tokenIdToName[tokenId];

        IERC20(_creditsAddress).transferFrom(msg.sender, address(this), NAME_CHANGE_PRICE);
        // If already named, dereserve old name
        if (bytes(_tokenIdToName[tokenId]).length > 0) {
            toggleReserveName(_tokenIdToName[tokenId], false);
        }
        toggleReserveName(newName, true);
        _tokenIdToName[tokenId] = newName;
        IERC20Burnable(_creditsAddress).burn(NAME_CHANGE_PRICE);
        emit NameChanged(tokenId, oldName, newName);
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

    //----------RANDOM TOKEN----------//

    function _useRandomAvailableToken(
        uint256 _numberToFetch,
        uint256 _indexToUse
        ) internal returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encode(
                    msg.sender,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    blockhash(block.number-1),
                    _numberToFetch,
                    _indexToUse
                    )
                )
            );
        uint256 randomIndex = randomNumber % _numOfAvailableTokens;
        return _useAvailableTokenAtIndex(randomIndex);
    }

    function _useAvailableTokenAtIndex(uint256 indexToUse)
    internal
    returns (uint256)
    {
        uint256 valAtIndex = _availableTokens[indexToUse];
        uint256 result;
        if (valAtIndex == 0) {
            result = indexToUse;
        } else {
            result = valAtIndex;
        }
        uint256 lastIndex = _numOfAvailableTokens - 1;
        if(indexToUse != lastIndex) {
            uint256 lastValInArray = _availableTokens[lastIndex];
            if (lastValInArray == 0) {
                _availableTokens[indexToUse] = lastIndex;
            } else {
                _availableTokens[indexToUse] = lastValInArray;
            }
        }
        _numOfAvailableTokens--;
        return result;
    }
}

