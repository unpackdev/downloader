pragma solidity ^0.8.0;

import "./AdminControl.sol";
import "./ERC1155.sol";

import "./ERC1155CollectionBase.sol";

contract Multiplier is ERC1155, ERC1155CollectionBase, AdminControl {
    
    string public name = "Multipliers";

    bool public isSetCollectionUriDisabled = false;

    constructor(address signingAddress_) ERC1155('') {
        _setURI("https://gateway.pinata.cloud/ipfs/QmcM6YWyi6WUvJQ7UKGrtWdYiQmScfkEoJFuEQozvVDeAQ");
        _initialize(
            // total supply
            3000,
            // total supply available to purchase
            3000,
            // 0.03 eth public sale price
            30000000000000000,
            // purchase limit (0 for no limit)
            0,
            // transaction limit (0 for no limit)
            5,
            // 0.03 eth presale price
            30000000000000000,
            // presale limit (unused but 0 for no limit)
            0,
            signingAddress_,
            // use dynamic presale purchase limit
            true
        );
    }

    /**
    * @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155CollectionBase, AdminControl) returns (bool) {
      return ERC1155CollectionBase.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155Collection-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        return ERC1155.balanceOf(owner, TOKEN_ID);
    }

    /**
     * @dev See {IERC1155Collection-withdraw}.
     */
    function withdraw(address payable recipient, uint256 amount) external override adminRequired {
        _withdraw(recipient, amount);
    }

    /**
     * @dev See {IERC1155Collection-setTransferLocked}.
     */
    function setTransferLocked(bool locked) external override adminRequired {
        _setTransferLocked(locked);
    }

    /**
     * @dev See {IERC1155Collection-activate}.
     */
    function activate() override external adminRequired {
        _activate();
    }

    /**
     * @dev See {IERC1155Collection-deactivate}.
     */
    function deactivate() external override adminRequired {
        _deactivate();
    }

    /**
     *  @dev See {IERC1155Collection-setCollectionURI}.
     */
    function setCollectionURI(string calldata uri) external override adminRequired {
        require(isSetCollectionUriDisabled == false);
        _setURI(uri);
    }

    function disableSetCollectionUri() external adminRequired {
        isSetCollectionUriDisabled = true;
    }

    /**
     * @dev See {IERC1155Collection-burn}
     */
    function burn(address from, uint16 amount) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: caller is not owner nor approved");
        ERC1155._burn(from, TOKEN_ID, amount);
    }

    /**
     * @dev See {ERC1155CollectionBase-_mint}.
     */
    function _mintERC1155(address to, uint16 amount) internal virtual override {
        ERC1155._mint(to, TOKEN_ID, amount, "");
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address, address from, address, uint256[] memory, uint256[] memory, bytes memory) internal virtual override {
        _validateTokenTransferability(from);
    }
    
    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
      _updateRoyalties(recipient, bps);
    }

}