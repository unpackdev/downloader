// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./ERC721Upgradeable.sol";
import "./ERC721BurnableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./AddressUpgradeable.sol";

import "./ERC2981Upgradeable.sol";

contract ERC721Burnable is
    Initializable,
    ERC721Upgradeable,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    string private _baseTokenURI;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {} // solhint-disable-line no-empty-blocks

    function initialize(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address royaltyReceiver_,
        uint256 royaltyBps_,
        uint256 initialSupply_,
        address initialSupplyReceiver_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Burnable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        // Initialize the contents
        if (bytes(baseTokenURI_).length > 0) {
            _baseTokenURI = baseTokenURI_;
        }

        _setRoyaltyInfo(royaltyReceiver_, royaltyBps_);

        for (uint256 i = 0; i < initialSupply_; i++) {
            // mint the initial supply to the initial owner starting with token ID 1
            _safeMint(initialSupplyReceiver_, i + 1);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function contractURI() public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "collection")) : "";
    }

    function safeMint(address to, uint256 tokenId) external onlyOwner {
        _safeMint(to, tokenId);
    }

    /**
     * @dev Updates royalty info.
     * @param receiver_ - the address of who should be sent the royalty payment
     * @param royaltyBps_ - the share of the sale price owed as royalty to the receiver, expressed as BPS (1/10,000)
     */
    function setRoyaltyInfo(address receiver_, uint256 royaltyBps_) external onlyOwner {
        _setRoyaltyInfo(receiver_, royaltyBps_);
    }

    /**
     * @dev It's sufficient to restrict upgrades to the upgrader role.
     */
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Receives and executes a batch of function calls on this contract.
     * This was copied from `utils/MulticallUpgradeable.sol` with the exception of renaming the `_functionDelegateCall`
     * helper, since `UUPSUpgradeable` also defines a private `_functionDelegateCall`.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _multicallFunctionDelegateCall(address(this), data[i]);
        }
        return results;
    }

    /**
     * @dev `_functionDelegateCall` implementation is the same for both Multicall
     * and ERC1967Upgrade, so we provide it here without differentiation.
     */
    function _multicallFunctionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
