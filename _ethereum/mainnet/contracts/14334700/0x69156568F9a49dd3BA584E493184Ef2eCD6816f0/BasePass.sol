// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IUtilityERC20.sol";
import "./ERC1155Supply.sol";
import "./ChainScoutsExtension.sol";
import "./OpenSeaMetadata.sol";

/**
 * Base class for creating "passes" e.g. Scout Pass purchaseable with a Utility ERC20 token.
 */
abstract contract BasePass is ChainScoutsExtension, ERC1155Supply {
    IUtilityERC20 public token;
    uint256 public price;
    string public name;

    constructor(
        IUtilityERC20 _token,
        uint256 _price,
        string memory _name
    )
        ERC1155("")
    {
        token = _token;
        price = _price;
        name = _name;
    }

    /**
     * Sets the name of the pass. OpenSea uses this to determine the collection name.
     */
    function adminSetName(string memory _name) external onlyAdmin {
        name = _name;
    }

    /**
     * Sets the token used to purchase the pass.
     */
    function adminSetToken(IUtilityERC20 _token) external onlyAdmin {
        token = _token;
    }

    /**
     * Sets the amount of token() needed to purchase a pass. Remember that this is wei (10^-18 eth) for most tokens.
     */
    function adminSetPrice(uint256 _price) external onlyAdmin {
        price = _price;
    }

    /**
     * @dev Burns one or more passes. This is used by contracts that require passes in exchange for services.
     * You must be the owner of the pass(es) being burnt or an admin.
     */
    function burn(address owner, uint256 count) external virtual whenEnabled {
        require(
            chainScouts.isAdmin(msg.sender) || msg.sender == owner,
            "must be admin or owner"
        );
        _burn(msg.sender, 0, count);
    }

    /**
     * @dev Purchases one or more passes. Requires price() token() per pass.
     */
    function purchase(uint256 count) public virtual whenEnabled {
        require(count > 0, "Must mint at least one");
        token.burn(msg.sender, count * price);
        _mint(msg.sender, 0, count, hex"");
    }

    /**
     * @dev Returns the metadata of the pass. Used by OpenSea to render the image.
     */
    function metadata() public virtual view returns (OpenSeaMetadata memory);

    /**
     * @dev Returns the "symbol" of the pass. For example, Ethereum's symbol is "ETH".
     */
    function symbol() public virtual view returns (string memory);

    function uri(uint) public override view returns (string memory) {
        return OpenSeaMetadataLibrary.makeERC1155Metadata(metadata(), symbol());
    }
}
