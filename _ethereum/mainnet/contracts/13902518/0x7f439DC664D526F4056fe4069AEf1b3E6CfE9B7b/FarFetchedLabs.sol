pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT

import "./ERC721.sol";

import "./Ownable.sol";
import "./IERC1155.sol";
import "./Strings.sol";

abstract contract VIAL {
    function burnFrom(address account, uint256 amount) public virtual;

    function burn(address from, uint256 amount) external virtual;
}

contract FarFetchedLabs is ERC721, Ownable {
    using Strings for uint256;

    uint256 public nameChangePrice = 1 ether;
    mapping(uint256 => string) private _tokenName;
    mapping(string => bool) private _nameReserved;

    uint256 public _mintPrice = 0.0333 ether;
    uint256 public _maxMintPerTx = 25;
    uint256 public MAX_SUPPLY = 4614;

    bool public _changeNameFeature = false;

    bool public _saleIsActive = false;
    uint256 public startTimeSale = 1640816400;

    address[] private _team;
    uint256[] private _shares;

    mapping(address => uint256) private _claimed;

    string private baseURI;

    IERC1155 private _nft;
    VIAL public _token;

    uint256 private _t = 0;
    uint256 public _pass = 0;

    constructor(
        string memory uriBASE,
        address[] memory team,
        uint256[] memory teamShares,
        address nft
    ) ERC721("Far Fetched Labs", "FFLABZ") {
        baseURI = uriBASE;
        _team = team;
        _shares = teamShares;
        _nft = IERC1155(nft);
    }

    function _mint(uint256 toMint, address to) internal {
        uint256 t = _t;
        for (uint256 i = 0; i < toMint; i++) {
            _t += 1;
            _safeMint(to, t + i + 1);
        }
        delete t;
    }

    function mint(uint256 toMint) external payable {
        require(_saleIsActive, "Sale is not active");
        require(toMint <= _maxMintPerTx, "You requested too many Apes");
        require(block.timestamp >= startTimeSale, "Sale did not start yet");
        require(_mintPrice * toMint <= msg.value, "ETH value not correct");
        require(_t + toMint <= MAX_SUPPLY, "Purchase exceeds max supply");
        _mint(toMint, _msgSender());
    }

    function collab(uint256 toMint) external {
        uint256 balance = _nft.balanceOf(_msgSender(), 420);
        require(balance > 0, "You need to hold a Chumpass");
        require(_saleIsActive, "Sale is not active");
        require(
            _claimed[_msgSender()] + toMint <= balance,
            "You request to many mints"
        );
        require(block.timestamp >= startTimeSale, "Sale did not start yet");
        require(_t + toMint <= MAX_SUPPLY, "Purchase exceeds max supply");
        require(_pass + toMint <= 699, "No more free mints");

        _pass += toMint;
        _claimed[_msgSender()] = toMint;
        _mint(toMint, _msgSender());
    }

    function reserve(uint256 toMint, address to) external onlyOwner {
        require(_t + toMint <= MAX_SUPPLY, "Purchase exceeds max supply");
        _mint(toMint, to);
    }

    function setSaleState(bool val) external onlyOwner {
        _saleIsActive = val;
    }

    function setChangeNameFeature(bool val) external onlyOwner {
        _changeNameFeature = val;
    }

    function setPrice(uint256 price) external onlyOwner {
        _mintPrice = price;
    }

    function setPriceNameChange(uint256 price) external onlyOwner {
        nameChangePrice = price;
    }

    function setMaxPerTX(uint256 maxValue) external onlyOwner {
        _maxMintPerTx = maxValue;
    }

    function setStartTimeSale(uint256 startSale) external onlyOwner {
        startTimeSale = startSale;
    }

    function setBaseURI(string memory newURI) public onlyOwner {
        baseURI = newURI;
    }

    function cut(uint256 max) external onlyOwner {
        uint256 previous = MAX_SUPPLY;
        if (max < previous) {
            MAX_SUPPLY = max;
        }
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        for (uint256 i = 0; i < _shares.length; i++) {
            address wallet = _team[i];
            uint256 share = _shares[i];
            payable(wallet).transfer((balance * share) / 1000);
        }
    }

    function setShares(address[] memory team, uint256[] memory teamShares)
        public
        onlyOwner
    {
        _team = team;
        _shares = teamShares;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function totalSupply() external view returns (uint256) {
        return _t;
    }

    function setShitToken(address tokenAddress) external onlyOwner {
        _token = VIAL(tokenAddress);
    }

    function changeName(uint256 tokenId, string memory newName) public {
        require(_changeNameFeature, "The Change Name Function is blocked");
        _token.burnFrom(msg.sender, nameChangePrice);
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

    function toggleReserveName(string memory str, bool isReserve) internal {
        _nameReserved[toLower(str)] = isReserve;
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
                : string(abi.encodePacked("Scientist #", tokenId.toString()));
    }

    function getAllNames() public view returns (string[] memory) {
        string[] memory ret = new string[](_t);
        for (uint256 i = 0; i < _t; i++) {
            ret[i] = nameOf(i);
        }
        return ret;
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
