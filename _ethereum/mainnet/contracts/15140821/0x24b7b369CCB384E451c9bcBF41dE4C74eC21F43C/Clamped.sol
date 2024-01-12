// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./SafeMath.sol";
import "./IERC2981.sol";
import "./IERC20.sol";
import "./Pausable.sol";
import "./ClampedRandomizer.sol";


pragma solidity ^0.8.10;

contract Creameow is ERC721Enumerable, ERC721URIStorage, IERC2981, Pausable, Ownable, ERC721Burnable, ClampedRandomizer {
    
    using SafeMath for uint;
    using Address for address;

    // MODIFIERS
    modifier onlyDevs() {
        require(devFees[msg.sender].percent > 0, "Dev Only: caller is not the developer");
        _;
    }

    // STRUCTS
    struct DevFee {
        uint percent;
        uint amount;
    }

    //EVENTS
    event WithdrawFees(address indexed devAddress, uint amount);
    event WithdrawWrongTokens(address indexed devAddress, address tokenAddress, uint amount);
    event WithdrawWrongNfts(address indexed devAddress, address tokenAddress, uint tokenId);

    // CONSTANTS
    uint public constant MAX_SUPPLY = 5555;
    uint public constant START_ID = 0;

    string public baseURI;
    // VARIABLES
    uint public maxSupply = MAX_SUPPLY;
    uint public maxPerTx = 5;
    uint public maxPerPerson = 5555;
    uint public price = 30000000000000000;
    address public royaltyAddress = 0xA0E1A63E39D2C97d93c79115234c4cdFE6f33067;
    uint public royalty = 750;
    address[] private devList;
    

    // MAPPINGS
    mapping(address => bool) public whiteListed;
    mapping(address => DevFee) public devFees;

    constructor(
        address[] memory _devList,
        uint[] memory _fees
    ) ERC721("Creameow", "CRME") ClampedRandomizer(maxSupply) {
        require(_devList.length == _fees.length, "Error: invalid data");
        uint totalFee = 0;
        for (uint8 i = 0; i < _devList.length; i++) {
            devList.push(_devList[i]);
            devFees[_devList[i]] = DevFee(_fees[i], 0);
            totalFee += _fees[i];
        }
        require(totalFee == 10000, "Error: invalid total fee");
        _pause();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function splitFees(uint sentAmount) internal {
        for (uint8 i = 0; i < devList.length; i++) {
            address devAddress = devList[i];
            uint devFee = devFees[devAddress].percent;
            uint devFeeAmount = sentAmount.mul(devFee).div(10000);
            devFees[devAddress].amount += devFeeAmount;
        }
    }

    function mint(uint amount) public payable whenNotPaused {
        uint supply = totalSupply();
        require(supply + amount - 1 < maxSupply, "Error: cannot mint more than total supply");
        require(amount <= maxPerTx, "Error: max par tx limit");
        require(balanceOf(msg.sender) + 1 <= maxPerPerson, "Error: max per address limit");
        if(!whiteListed[msg.sender]) {
            if (price > 0) require(msg.value == price * amount, "Error: invalid price");
        } else {
            whiteListed[msg.sender] = false;
        }
        for (uint i = 0; i < amount; i++) {
            internalMint(msg.sender);
        }
        if (price > 0 && msg.value > 0) splitFees(msg.value);
    }

    function tokenURI(uint tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function Owned(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint index;
            for (index = 0; index < tokenCount; ++index) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function tokenExists(uint _id) external view returns (bool) {
        return (_exists(_id));
    }

    function royaltyInfo(uint, uint _salePrice) external view override returns (address receiver, uint royaltyAmount) {
        return (royaltyAddress, (_salePrice * royalty) / 10000);
    }

    //dev

    function whiteList(address[] memory _addressList) external onlyOwner {
        require(_addressList.length > 0, "Error: list is empty");
        for (uint i = 0; i < _addressList.length; ++i) {
            whiteListed[_addressList[i]] = true;
        }
    }

    function removeWhiteList(address[] memory addressList) external onlyOwner {
        require(addressList.length > 0, "Error: list is empty");
        for (uint i = 0; i < addressList.length; ++i) whiteListed[addressList[i]] = false;
    }

    function updatePausedStatus() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function setMaxPerPerson(uint newMaxBuy) external onlyOwner {
        maxPerPerson = newMaxBuy;
    }

    function setMaxPerTx(uint newMaxBuy) external onlyOwner {
        maxPerTx = newMaxBuy;
    }

    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }

    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }

    function setURI(uint tokenId, string memory uri) external onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function setRoyalty(uint16 _royalty) external onlyOwner {
        require(_royalty <= 750, "Royalty must be lower than or equal to 7,5%");
        royalty = _royalty;
    }

    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
    }

    //Overrides

    function internalMint(address to) internal {
        uint tokenId = _genClampedNonce() + START_ID;
        _safeMint(to, tokenId);
    }

    function safeMint(address to) public onlyOwner {
        internalMint(to);
    }

    function internalMintToken(address to, uint tokenId) internal {
        _safeMint(to, tokenId);
    }

    function safeMintToken(address to, uint tokenId) public onlyOwner {
        internalMintToken(to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /// @dev withdraw fees
    function withdraw() external onlyDevs {
        uint amount = devFees[msg.sender].amount;
        require(amount > 0, "Error: no fees :(");
        devFees[msg.sender].amount = 0;
        payable(msg.sender).transfer(amount);
        emit WithdrawFees(msg.sender, amount);
    }

    /// @dev emergency withdraw contract balance to the contract owner
    function emergencyWithdraw() external onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "Error: no fees :(");
        for (uint8 i = 0; i < devList.length; i++) {
            address devAddress = devList[i];
            devFees[devAddress].amount = 0;
        }
        payable(msg.sender).transfer(amount);
        emit WithdrawFees(msg.sender, amount);
    }

    function airdropsToken(address[] memory _addr, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < _addr.length; i++) {
            airdropTokenInternal(amount,_addr[i]);
        }
    }
    
    function airdropTokenInternal(uint256 amount, address _addr) internal {
        for (uint256 i = 0; i < amount; i++) {
            internalMint(_addr);
        }
    }

    /// @dev withdraw ERC20 tokens
    function withdrawTokens(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint _amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner(), _amount);
        emit WithdrawWrongTokens(msg.sender, _tokenContract, _amount);
    }

    /// @dev withdraw ERC721 tokens to the contract owner
    function withdrawNFT(address _tokenContract, uint[] memory _id) external onlyOwner {
        IERC721 tokenContract = IERC721(_tokenContract);
        for (uint i = 0; i < _id.length; i++) {
            tokenContract.safeTransferFrom(address(this), owner(), _id[i]);
            emit WithdrawWrongNfts(msg.sender, _tokenContract, _id[i]);
        }
    }
}
