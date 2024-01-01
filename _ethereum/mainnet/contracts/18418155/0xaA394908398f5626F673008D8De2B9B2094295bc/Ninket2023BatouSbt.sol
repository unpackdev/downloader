// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ERC1155.sol";
import "./AccessControl.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract Ninket2023BatouSbt is ERC1155, AccessControl, Ownable, Pausable {
    using Strings for uint256;

    // Role
    bytes32 public constant ADMIN = "ADMIN";

    // Mint
    mapping(uint256 => uint256) public mintCosts;
    mapping(uint256 => uint256) public totalSupply;
    address public withdrawAddress;

    // Metadata
    string public name = "Ninket2023 Batou SBT";
    string public symbol = "NBSBT";
    string public baseURI;
    string public baseExtension = ".json";

    // Modifier
    modifier tokenExists(uint256 _tokenId) {
        require(mintCosts[_tokenId] > 0, 'Token Not Exists');
        _;
    }
    modifier enoughEth(uint256 _tokenId, uint256 _amount) {
        require(msg.value >= _amount * mintCosts[_tokenId], 'Not Enough Eth');
        _;
    }

    // Constructor
    constructor() ERC1155("") {
        _grantRole(ADMIN, msg.sender);
        setWithdrawAddress(msg.sender);
    }

    // Mint
    function mint(address _to, uint256 _tokenId, uint256 _amount) external payable
        whenNotPaused
        tokenExists(_tokenId)
        enoughEth(_tokenId, _amount)
    {
        _mintCommon(_to, _tokenId, _amount);
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
    function withdraw() public onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // Getter
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
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
    function setWithdrawAddress(address _value) public onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setMintCost(uint256 _tokenId, uint256 _cost) external onlyRole(ADMIN) {
        mintCosts[_tokenId] = _cost;
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

    // SBT
    function setApprovalForAll(address, bool) public virtual override {
        revert("This token is SBT");
    }
    function _beforeTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory, bytes memory) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            require(from == address(0) || to == address(0), "This token is SBT");
        }
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}