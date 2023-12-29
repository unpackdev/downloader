// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ERC1155.sol";
import "./ERC2981.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./IERC5192.sol";

contract TukuruERC1155 is ERC1155, AccessControl, Ownable, Pausable, IERC5192, ERC2981 {
    using Strings for uint256;

    // Role
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant MINTER = "MINTER";

    // Metadata
    string public name;
    string public symbol;
    string public baseURI;
    string public baseExtension;

    // Mint
    mapping(uint256 => uint256) public mintCosts;
    mapping(uint256 => uint256) public maxSupply;
    mapping(uint256 => uint256) public totalSupply;
    bool isLocked;

    // Withdraw
    uint256 public usageFee = 0.1 ether;
    address public withdrawAddress;
    uint256 public systemRoyalty;
    address public royaltyReceiver;

    // Modifier
    modifier withinMaxSupply(uint256 _tokenId, uint256 _amount) {
        require(totalSupply[_tokenId] + _amount <= maxSupply[_tokenId], 'Over Max Supply');
        _;
    }
    modifier enoughEth(uint256 _tokenId, uint256 _amount) {
        require(mintCosts[_tokenId] > 0, 'Not Set Mint Cost');
        require(msg.value >= _amount * mintCosts[_tokenId], 'Not Enough Eth');
        _;
    }

    constructor() ERC1155("") Ownable(msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
    }

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        bool _isLocked,
        uint96 _royaltyFee,
        address _withdrawAddress,
        uint256 _systemRoyalty,
        address _royaltyReceiver
    ) external {
        // Role
        transferOwnership(_owner);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(ADMIN, _owner);

        // Feature
        name = _name;
        symbol = _symbol;
        isLocked = _isLocked;

        // Payment
        _setDefaultRoyalty(_withdrawAddress, _royaltyFee);
        withdrawAddress = _withdrawAddress;
        systemRoyalty = _systemRoyalty;
        royaltyReceiver = _royaltyReceiver;
    }
    function updateToNoSystemRoyalty() external payable {
        require(systemRoyalty > 0, "No System Royalty");
        require(msg.value >= usageFee, "Not Enough Eth");
        systemRoyalty = 0;
    }

    // Mint
    function airdrop(address[] calldata _addresses, uint256 _tokenId, uint256 _amount) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _addresses.length; i++) {
            if (totalSupply[_tokenId] + _amount <= maxSupply[_tokenId]) {
                mintCommon(_addresses[i], _tokenId, _amount);
            }
        }
    }
    function mint(address _address, uint256 _tokenId, uint256 _amount) external payable
        whenNotPaused
        withinMaxSupply(_tokenId, _amount)
        enoughEth(_tokenId, _amount)
    {
        mintCommon(_address, _tokenId, _amount);
    }
    function externalMint(address _address, uint256 _tokenId, uint256 _amount) external payable onlyRole(MINTER) {
        mintCommon(_address, _tokenId, _amount);
    }
    function mintCommon(address _address, uint256 _tokenId, uint256 _amount) private {
        _mint(_address, _tokenId, _amount, "");
        totalSupply[_tokenId] += _amount;
    }
    function withdraw() public onlyRole(ADMIN) {
        bool success;
        if (systemRoyalty > 0) {
            (success, ) = payable(royaltyReceiver).call{value: address(this).balance * systemRoyalty / 100}("");
            require(success);
        }
        (success, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(success);
    }

    // Getter
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }

    // Setter
    function setWithdrawAddress(address _value) public onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setMetadataBase(string memory _baseURI, string memory _baseExtension) external onlyRole(ADMIN) {
        baseURI = _baseURI;
        baseExtension = _baseExtension;
    }
    function setIsLocked(bool _isLocked) external onlyRole(ADMIN) {
        isLocked = _isLocked;
    }
    function setTokenInfo(uint256 _tokenId, uint256 _mintCost, uint256 _maxSupply) external onlyRole(ADMIN) {
        mintCosts[_tokenId] = _mintCost;
        maxSupply[_tokenId] = _maxSupply;
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl, ERC2981) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            interfaceId == type(IERC5192).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // Locked
    function locked(uint256) override public view returns (bool){
        return isLocked;
    }
    function emitLockState(uint256 _tokenId) external onlyRole(ADMIN) {
        if (isLocked) {
            emit Locked(_tokenId);
        } else {
            emit Unlocked(_tokenId);
        }
    }
    function setApprovalForAll(address _operator, bool _approved) public virtual override {
        require (!_approved || !isLocked, "Locked");
        super.setApprovalForAll(_operator, _approved);
    }
    function _update(address _from, address _to, uint256[] memory _ids, uint256[] memory _values) internal virtual override {
        require (!isLocked, "Locked");
        super._update(_from, _to, _ids, _values);
    }
}