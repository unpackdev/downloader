//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ERC721A.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./console.sol";
import "./EIP2981PerToken.sol"; 
import "./Strings.sol";

contract B2BNFT is ERC721A, EIP2981PerTokenRoyalties, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _totalCount;
    Counters.Counter private _mintCount;
    Counters.Counter private _teamMintCount;
    uint256 private supply;
    uint256 public constant teamSupply = 50;
    bool public isMintEnabled;
    uint256 public mintLimit;
    string private tokenBaseUri;
    uint256 public price;
    address private _admin;
    //mappings
    mapping(address => uint8) private _teamAddress; /// @dev address that can mint freely
    mapping(address => uint8) private _walletMints; /// @dev prevent multiple minting on 1 wallet

    //events
    event MintEvent(uint256 indexed tokenID, string message);
    event PriceUpdateEvent(uint256 indexed newPrice);
    event BurnEvent(uint256 indexed tokenID, string message);
    event AdminReplaced(address indexed previousAdmin, address indexed newAdmin);
    event MintToggleEvent(bool isEnabled);

    constructor(string memory _baseUri, uint256 _supply) ERC721A("Block2Block", "B2B") {
        _admin = msg.sender;
        supply = _supply;
        tokenBaseUri = _baseUri;
        price = 0.12 ether;
        mintLimit = 0;
    }

    /// @dev prevents calling of certain functions
    modifier onlyAdmin()  {
        require(msg.sender == owner() || msg.sender == admin(), 'Only the contract owner or contract admin can trigger this function');
        _;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC2981)
        returns (bool)
    {
        if(interfaceId == type(IERC721).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function _setPrice(uint256 _newPrice) private {
        require(_newPrice > 0, 'New price should be a positive value');
        price = _newPrice;
        emit PriceUpdateEvent(_newPrice);
    }
    
    function setPrice(uint256 _newPrice) external onlyAdmin {
        _setPrice(_newPrice);
    }

    function _disableMinting() private {
        isMintEnabled = false;
        _mintCount.reset();
        mintLimit = 0;
        emit MintToggleEvent(false);
    }

    function disableMinting() external onlyAdmin {
        require(isMintEnabled, 'Minting is currently disabled');

        _disableMinting();
    }

    function _getTotalPublicMint() private view returns (uint256) {
        return _totalCount.current() - _teamMintCount.current();
    }

    function _enableMinting(uint256 _limit, uint256 _newPrice) private {
        require(!isMintEnabled, 'Minting is currently enabled');
        require(_limit > 0, 'Specify a valid limit');
        require(_limit + _getTotalPublicMint() <= supply, 'Invalid limit, remaining supply is not enough');

        _setPrice(_newPrice);
        isMintEnabled = true;
        mintLimit = _limit;
        emit MintToggleEvent(true);
    } 
    
    function enableMinting(uint256 _limit) public onlyAdmin {
        _enableMinting(_limit, price);
    }
    function enableMintingWithNewPrice(uint256 _limit, uint256 _newPrice) public onlyAdmin {
        _enableMinting(_limit, _newPrice);
    }

    function getTotalSupply() external view returns (uint256) {
        return supply;
    }

    function remainingMintable() external view returns (uint256) {
        return mintLimit > 0 ? mintLimit - _mintCount.current() : 0;
    }

    function remainingSupply() external view returns (uint256) {
        return supply - _getTotalPublicMint();
    }

    function remainingTeamSupply() public view returns (uint256) {
        return teamSupply - _teamMintCount.current();
    }

    function isATeamMember(address userAddress) external view returns (bool) {
        return _teamAddress[userAddress] == 1;
    }

    function _replaceAdmin(address _newAdmin) internal virtual {
        address oldAdmin = _admin;
        _admin = _newAdmin;
        emit AdminReplaced(oldAdmin, _newAdmin);
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    function replaceAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "New admin is the zero address");
        require(_admin != _newAdmin, 'New admin is the same as the current admin');
        _replaceAdmin(_newAdmin);
    }

    function addTeamAddress(address[] calldata _newAddress) external onlyAdmin {
        for (uint256 i = 0; i < _newAddress.length; i++) {
            _teamAddress[_newAddress[i]] = 1;
        }
    }
    function removeTeamAddress(address[] calldata _address) external onlyAdmin {
        for (uint256 i = 0; i < _address.length; i++) {
            delete _teamAddress[_address[i]];
        }
    }
    
    function mintToken() external payable returns (uint256) {
        bool isAMember = _teamAddress[msg.sender] == 1;
        Counters.Counter storage mintCounter = isAMember ? _teamMintCount : _mintCount;
        uint256 currentItemId = mintCounter.current();
        uint256 maxMint = isAMember ? teamSupply : mintLimit;
        require(isAMember || isMintEnabled, "Minting is not open.");
        require(_walletMints[msg.sender] != 1 && _walletMints[msg.sender] != 2, "1 Platinum Pass mint per wallet only");
        require(currentItemId < maxMint, "Supply of platinum pass ran out");
        require(isAMember || msg.value == price, "Invalid amount value");
        
        _walletMints[msg.sender] = isAMember ? 2 : 1;
        uint256 newItemId = _totalCount.current();
        mintCounter.increment();
        _totalCount.increment();
        if(!isAMember) {
            if(_getTotalPublicMint() >= supply) {
                _disableMinting();
            } else {
                if(mintCounter.current() >= mintLimit) {
                    _disableMinting();
                }
            }
        }
        
        _safeMint(msg.sender, 1);
        _setTokenRoyalty(newItemId, owner());
        if(!isAMember) {
            payable(owner()).transfer(msg.value);
        }
        emit MintEvent(newItemId, "An NFT was minted successfully");
        return newItemId;  
    }

    function burnToken(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender,  "You are not the owner of this token");
        _burn(tokenId);
        emit BurnEvent(tokenId, "An NFT was burned");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'Token not yet existing');
        string memory zeros = tokenId < 100 ? tokenId < 10 ? "00" : "0" : "";
        
        return string(abi.encodePacked(tokenBaseUri, zeros, _toString(tokenId)));
    }
}