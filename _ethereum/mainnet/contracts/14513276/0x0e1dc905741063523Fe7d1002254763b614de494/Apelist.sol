pragma solidity 0.8.11;

import "./ERC1155PresetMinterPauserUpgradeable.sol";
import "./ERC1155SupplyUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./OpenSeaGasFreeListing.sol";
import "./StringsUpgradeable.sol";

contract Apelist is Initializable, ERC1155PresetMinterPauserUpgradeable, ERC1155SupplyUpgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    string public name;
    string public symbol;

    bytes32 public URI_SETTER_ROLE;

    function initialize() virtual public initializer {
        name = "The Ape List";
        symbol = "The Ape List";
        URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
        __ERC1155PresetMinterPauser_init("https://ipfs.io/ipfs/QmYhLx5698G1GUnoUoUJhS1tzwusPaApLrRFLi7DjVyz4L/");
        __ERC1155Supply_init();
        __ReentrancyGuard_init();
        __Ownable_init();
        _setupRole(URI_SETTER_ROLE, msg.sender);
    }

    function apeMint(address to, uint256 id, uint256 quantity) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC1155PresetMinterPauser: must have minter role to mint");
        mint(to, id, quantity, "");
    }

    function grantMinter(address _to) external onlyOwner {
        _grantRole(MINTER_ROLE, _to);
    }

    function grantPauser(address _to) external onlyOwner {
        _grantRole(PAUSER_ROLE, _to);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return super.isApprovedForAll(owner, operator) || OpenSeaGasFreeListing.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155PresetMinterPauserUpgradeable, ERC1155Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI: nonexistent token");

        return string(abi.encodePacked(super.uri(_id), StringsUpgradeable.toString(_id), ".json"));
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155PresetMinterPauserUpgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
