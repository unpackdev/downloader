// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";
import "./Strings.sol";

abstract contract Shit {
    function burnFrom(address account, uint256 amount) public virtual;
}

contract VoodooSalad is ERC721Enumerable, Ownable {
    using Strings for uint256;

    mapping(address => bool) private _mints;

    string public _baseTokenURI = "";
    string private _hardURI = "";

    bool public _saleIsActive = false;

    uint256 public startTimePreSale = 1634932800;
    uint256 public endTimePreSale = 1635192000;

    uint256 public startTimeSale = 1635192000;

    Shit public token;

    using MerkleProof for bytes32[];
    bytes32 public root;

    uint256 public nameChangePrice = 90000000000000000000;
    mapping(uint256 => string) private _tokenName;
    mapping(string => bool) private _nameReserved;

    uint256 public buyPrice = 180000000000000000000;
    uint256 public _maxToBuy = 444;
    bool public _saleForOtherPeople = false;
    bool public _abbilityToChangeName = false;

    constructor(address _shit, string memory baseURI, bytes32 _root)
        ERC721("Voodoo Salad Buttheads", "VOODOOBUTT")
    {
        token = Shit(_shit);
        _baseTokenURI = baseURI;
        root = _root;
        _safeMint(msg.sender, 0);
    }

    function mint(bytes32[] memory proof) public {
        require(!_mints[_msgSender()], "You already minted");
        require(_saleIsActive, "Mint not active");
        require(totalSupply() + 1 <= _maxToBuy, "Purchase exceeds max supply");
        require(
            block.timestamp >= startTimePreSale,
            "OG Sale did not start yet"
        );
        require(block.timestamp <= endTimePreSale, "OG Sale is finised");
        require(
            proof.verify(root, keccak256(abi.encodePacked(msg.sender))),
            "You are not on the list"
        );

        _mints[_msgSender()] = true;
        _safeMint(msg.sender, totalSupply());
    }

    function publicMint() public {
        require(!_mints[_msgSender()], "You already minted");
        require(_saleForOtherPeople, "Mint not active");
        require(block.timestamp >= startTimeSale, "Public Sale did not start yet");
        require(totalSupply() + 1 <= _maxToBuy, "Purchase exceeds max supply");
        token.burnFrom(msg.sender, buyPrice);
        _mints[_msgSender()] = true;
        _safeMint(msg.sender, totalSupply());
    }

    function changeName(uint256 tokenId, string memory newName) public {
        require(_abbilityToChangeName, "The Change Name Function is blocked");
        token.burnFrom(msg.sender, nameChangePrice);
        address owner = ownerOf(tokenId);

        require(_msgSender() == owner, "You are not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(
            sha256(bytes(newName)) != sha256(bytes(_tokenName[tokenId])),
            "New name is same as the current one"
        );
        require(isNameReserved(newName) == false, "Name already reserved");

        // If already named, dereserve old name
        if (bytes(_tokenName[tokenId]).length > 0) {
            toggleReserveName(_tokenName[tokenId], false);
        }

        toggleReserveName(newName, true);
        _tokenName[tokenId] = newName;
    }

    function giftTo(address _to, uint256 _supply) public onlyOwner {
        for (uint256 i = 0; i < _supply; i++) {
            uint256 mintIndex = totalSupply();
            _safeMint(_to, mintIndex);
        }
    }

    function changeNamePrice(uint256 _price) external onlyOwner {
        nameChangePrice = _price;
    }

    function changeMaxPublicBuy(uint256 maxForPublicToBuy) external onlyOwner {
        uint256 previous = _maxToBuy;
        if (maxForPublicToBuy < previous) {
            _maxToBuy = maxForPublicToBuy;
        }
    }

    function changeBuyPrice(uint256 _price) external onlyOwner {
        buyPrice = _price;
    }

    function setShitToken(address _shit) external onlyOwner {
        token = Shit(_shit);
    }

    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setSaleStatePublic(bool val) public onlyOwner {
        _saleForOtherPeople = val;
    }

    function setAbbilityToChangeName(bool val) public onlyOwner {
        _abbilityToChangeName = val;
    }

    function setSaleState(bool val) public onlyOwner {
        _saleIsActive = val;
    }

    function setStartAndEndTimePreSale(uint256 _start, uint256 _end)
        external
        onlyOwner
    {
        startTimePreSale = _start;
        endTimePreSale = _end;
    }

    function setStartTimeSale(uint256 _startSale) external onlyOwner {
        startTimeSale = _startSale;
    }

    function setRoots(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setHardURI(string calldata hardURI) external onlyOwner {
        _hardURI = hardURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory finalURI = _hardURI;

        return
            bytes(finalURI).length > 0
                ? string(abi.encodePacked(finalURI, tokenId.toString()))
                : string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    function onAccesslist(bytes32[] memory proof, address _address)
        external
        view
        returns (bool)
    {
        return proof.verify(root, keccak256(abi.encodePacked(_address)));
    }

    function isNameReserved(string memory nameString)
        public
        view
        returns (bool)
    {
        return _nameReserved[toLower(nameString)];
    }

    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    function toLower(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function nameOf(uint256 tokenId) public view returns (string memory) {
        string memory name = _tokenName[tokenId];
        return
            bytes(name).length > 0
                ? name
                : string(abi.encodePacked("Voodoo BUTT #", tokenId.toString()));
    }

    function getAllNames() public view returns (string[] memory) {
        string[] memory ret = new string[](totalSupply());
        for (uint256 i = 0; i < totalSupply(); i++) {
            ret[i] = nameOf(i);
        }
        return ret;
    }
}
