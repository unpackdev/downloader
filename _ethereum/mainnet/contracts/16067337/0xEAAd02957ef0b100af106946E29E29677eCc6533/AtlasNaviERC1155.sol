// SPDX-License-Identifier: NO LICENSE

pragma solidity ^0.8.9;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC1155Upgradeable.sol";

contract AtlasNaviERC1155 is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 public constant TOKEN_TYPE_DEFAULT = 1;
    mapping(address => bool) public controllers;

    string public baseURI;

    /** INITIALIZER */

    /**
     * @notice instantiates contract
     * @param _baseURI   uri for token url
     */
    function initialize(
        string memory _baseURI
    ) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ERC1155_init('');

        baseURI = _baseURI;
    }


    /** PUBLIC */

    /**
     * @notice mints new ERC1155 default tokes
     * @dev must implement correct checks on controller contract for allowed mints
     * @param recipient address to mint the token to
     * @param amount amount to be minted
     */
    function mint(address recipient, uint256 amount) external whenNotPaused {
        require(controllers[_msgSender()], "Only controllers can mint");
        _mint(recipient, TOKEN_TYPE_DEFAULT, amount, '');
    }

    /** OWNER */

    /**
     * @notice enables owner to pause / unpause minting
     * @param paused   true / false for pausing / unpausing minting
     */
    function setPaused(bool paused) external onlyOwner {
        if (paused) _pause();
        else _unpause();
    }

    /**
     * @notice enables an address to mint
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * @notice disables an address from minting
     * @param controller the address to disable
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    /**
     * @notice sets the baseURI value to be returned by _baseURI() & tokenURI() methods.
     * @param newBaseURI the new baseUri
     */
    function setBaseURI(string memory newBaseURI) external virtual onlyOwner {
        baseURI = newBaseURI;
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                baseURI,
                StringsUpgradeable.toString(_tokenId)
            )
        );
    }
}
