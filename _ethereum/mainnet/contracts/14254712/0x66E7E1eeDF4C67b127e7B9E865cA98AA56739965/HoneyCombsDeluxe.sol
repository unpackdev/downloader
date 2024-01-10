//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Enums.sol";

contract HoneyCombsDeluxe is ERC1155Supply, AccessControlEnumerable, Ownable {
    mapping(HONEY_COMB_RARITY => uint16) public maxSupplies;
    uint8 public lockedUrlChange = 0;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    string[5] private baseUris;

    string public constant name = "Honey Combs Deluxe";
    string public constant symbol = "HoneyCombsDeluxe";

    event LockedUrl();
    event UrlChanged(uint256 indexed _id, string newUrl);

    constructor() ERC1155("") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(BURNER_ROLE, _msgSender());
        baseUris[uint256(HONEY_COMB_RARITY.COMMON)] = "";
        baseUris[uint256(HONEY_COMB_RARITY.UNCOMMON)] = "";
        baseUris[uint256(HONEY_COMB_RARITY.RARE)] = "";
        baseUris[uint256(HONEY_COMB_RARITY.EPIC)] = "";
        baseUris[uint256(HONEY_COMB_RARITY.LEGENDARY)] = "";
    }

    //****** EXTERNAL *******/

    function burn(
        address _owner,
        uint256 _rarity,
        uint256 _amount
    ) external {
        require(hasRole(BURNER_ROLE, _msgSender()), "Missing BURNER_ROLE");
        _burn(_owner, _rarity, _amount);
    }

    /**
     * @notice initiating the combs to the owner(usually the BeeKeeper)
     * @param _owner the BeeKeeper should be
     */
    function init(address _owner) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        require(maxSupplies[HONEY_COMB_RARITY.COMMON] < 6000, "Already called");
        _mint(_owner, uint256(HONEY_COMB_RARITY.COMMON), 6000, "");
        _mint(_owner, uint256(HONEY_COMB_RARITY.UNCOMMON), 4000, "");
        _mint(_owner, uint256(HONEY_COMB_RARITY.RARE), 2000, "");
        _mint(_owner, uint256(HONEY_COMB_RARITY.EPIC), 1200, "");
        _mint(_owner, uint256(HONEY_COMB_RARITY.LEGENDARY), 600, "");
        maxSupplies[HONEY_COMB_RARITY.COMMON] = 6000;
        maxSupplies[HONEY_COMB_RARITY.UNCOMMON] = 4000;
        maxSupplies[HONEY_COMB_RARITY.RARE] = 2000;
        maxSupplies[HONEY_COMB_RARITY.EPIC] = 1200;
        maxSupplies[HONEY_COMB_RARITY.LEGENDARY] = 600;
    }

    /**
     * @notice Changing base uri for reveals or in case something happens with the IPFS
     * @param _rarity from 0 to 4
     * @param _newBaseUri new base uri for a rarity
     */
    function setBaseUri(uint256 _rarity, string calldata _newBaseUri) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        require(lockedUrlChange == 0, "Locked");

        baseUris[_rarity] = _newBaseUri;
        emit UrlChanged(_rarity, _newBaseUri);
    }

    /**
     * @notice lock changing url for ever.
     */
    function lockUrlChanging() external {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Missing DEFAULT_ADMIN_ROLE");
        lockedUrlChange = 1;
        emit LockedUrl();
    }

    //****** PUBLIC *******/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function uri(uint256 _rarity) public view virtual override returns (string memory) {
        return baseUris[_rarity];
    }
}
