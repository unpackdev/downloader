// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./ECDSA.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract NinjaDaoEntertainmentPassport is ERC1155, AccessControl, Ownable, Pausable {
    using Strings for uint256;
    using ECDSA for bytes32;

    // Role
    bytes32 public constant ADMIN = "ADMIN";

    // Sell
    mapping(uint256 => uint256) public mintCosts;
    address public withdrawAddress;
    address private signer;
    uint256 public mintLimitPerTerm = 1;
    uint256 public timezoneOffsetSec = 13 hours;

    // Mint
    mapping(uint256 => uint256) public mintedAmount;
    mapping(uint256 => uint256) public totalSupply;

    // Metadata
    string public name = "Ninja DAO Entertainment Passport";
    string public symbol = "NINDAOEP";
    string public baseURI;
    string public baseExtension;

    // Modifier
    modifier tokenExists(uint256 _tokenId) {
        require(mintCosts[_tokenId] > 0, 'Token Not Exists');
        _;
    }
    modifier enoughEth(uint256 _tokenId) {
        require(msg.value >= mintCosts[_tokenId], 'Not Enough Eth');
        _;
    }
    modifier withinMintLimit() {
        require(mintedAmount[getCurrentTerm()] < mintLimitPerTerm, 'Over Mint Limit');
        _;
    }
    modifier isValidSignature (uint256 _tokenId, bytes calldata _signature) {
        address recoveredAddress = keccak256(
            abi.encodePacked(
                msg.sender,
                _tokenId,
                getCurrentTerm()
            )
        ).toEthSignedMessageHash().recover(_signature);
        require(recoveredAddress == signer, "Invalid Signature");
        _;
    }


    // Constructor
    constructor() ERC1155("") {
        _grantRole(ADMIN, msg.sender);
        setWithdrawAddress(msg.sender);
    }

    // Mint
    function mint(uint256 _tokenId, bytes calldata _signature) external payable
        whenNotPaused
        tokenExists(_tokenId)
        enoughEth(_tokenId)
        isValidSignature(_tokenId, _signature)
    {
        _mintCommon(msg.sender, _tokenId, 1);
        mintedAmount[getCurrentTerm()]++;
    }
    function airdrop(address[] calldata _addresses, uint256 _tokenId, uint256 _amount) external onlyRole(ADMIN)
        tokenExists(_tokenId)
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            _mintCommon(_addresses[i], _tokenId, _amount);
        }
    }
    function _mintCommon(address _to, uint256 _tokenId, uint256 _amount) private {
        _mint(_to, _tokenId, _amount, "");
        totalSupply[_tokenId] += _amount;
    }
    function withdraw() public payable onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // Getter
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }
    function getCurrentTerm() public view returns (uint256) {
        return (block.timestamp + timezoneOffsetSec) / 1 days;
    }
    function getAdjustedTimestamp(uint256 timestamp) external view returns (uint256) {
        return timestamp + timezoneOffsetSec;
    }
    function getRemainMintLimit() external view returns (uint256) {
        return mintLimitPerTerm - mintedAmount[getCurrentTerm()];
    }

    // Setter
    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }
    function resetBaseExtension() external onlyRole(ADMIN) {
        baseExtension = "";
    }
    function setMintCost(uint256 _tokenId, uint256 _cost) external onlyRole(ADMIN) {
        mintCosts[_tokenId] = _cost;
    }
    function setWithdrawAddress(address _value) public onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setSigner(address _value) external onlyRole(ADMIN) {
        signer = _value;
    }
    function setMintLimitPerTerm(uint256 _value) external onlyRole(ADMIN) {
        mintLimitPerTerm = _value;
    }
    function setTimezoneOffsetMin(uint256 _value) external onlyRole(ADMIN) {
        timezoneOffsetSec = _value;
    }

    // Pausable
    function pause() public onlyRole(ADMIN) {
        _pause();
    }
    function unpause() public onlyRole(ADMIN) {
        _unpause();
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}