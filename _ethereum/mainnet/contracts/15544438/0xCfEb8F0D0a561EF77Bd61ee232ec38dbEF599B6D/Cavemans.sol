// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";

contract Cavemans is Ownable, ERC721A, ReentrancyGuard {

    //using
    using Address for address;
    using SafeMath for uint256;

    mapping(address => uint256) public mintMap;
    uint256 public immutable maxSupply = 4488;
    uint256 public normalMinted = 0;
    uint256 public maxMint = 5;
    uint256 public price = 24000000000000000; //0.024
    string public _baseTokenURI;
    address public immutable openseaAddress;
    address payable public immutable shareholderAddress;

    constructor(
        string memory name, //Cavemans Club
        string memory symbol, //CVMC
        address payable _shareholderAddress, //0xF3C36810d5d0e9c739d2099320e6342aB19F5040
        address _openseaAddress, //0x1E0049783F008A0085193E00003D00cd54003c71
        string memory _baseURI //https://cavemans.xyz/nft/json/
    )ERC721A(name, symbol){
        openseaAddress = _openseaAddress;
        shareholderAddress = _shareholderAddress;
        _baseTokenURI = _baseURI;
    }

    function mint(uint256 _amount) external payable nonReentrant returns (bool) {
        require((normalMinted + _amount) <= maxSupply, "Cavemans: exceeds the total amount.");
        require((mintMap[msg.sender] + _amount) <= maxMint, "Cavemans: You have already minted.");
        uint256 _price = _amount * price;
        require(
            msg.value >= _price,
            "Insufficient funds."
        );
        mintMap[msg.sender] = mintMap[msg.sender] + _amount;
        normalMinted = normalMinted + _amount;
        _safeMint(msg.sender, _amount);
        setApprovalForAll(openseaAddress, true);
        return true;
    }

    function setPrice(uint96 _maxMint, uint256 _price) public onlyOwner {
        maxMint = _maxMint;
        price = _price;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721A)
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "Cavemans: URI query for nonexistent token"
        );
        return string(
            abi.encodePacked(
                _baseTokenURI,
                Strings.toString(tokenId),
                ".json"
            ));
    }
}
