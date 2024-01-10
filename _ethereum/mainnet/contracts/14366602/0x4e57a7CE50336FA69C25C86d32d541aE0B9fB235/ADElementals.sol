// SPDX-License-Identifier: MIT
/*
-- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- -- -- - -- - -- - -- - -- - -- - -- - --
-  ______     __   __     ______     __  __     _____     ______     __    __     __     ______     __   __     -
- /\  __ \   /\ "-.\ \   /\  ___\   /\ \/ /    /\  __-.  /\  __ \   /\ "-./  \   /\ \   /\  __ \   /\ "-.\ \    -
- \ \  __ \  \ \ \-.  \  \ \  __\   \ \  _"-.  \ \ \/\ \ \ \  __ \  \ \ \-./\ \  \ \ \  \ \  __ \  \ \ \-.  \   -
-  \ \_\ \_\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \____-  \ \_\ \_\  \ \_\ \ \_\  \ \_\  \ \_\ \_\  \ \_\\"\_\  -
-   \/_/\/_/   \/_/ \/_/   \/_____/   \/_/\/_/   \/____/   \/_/\/_/   \/_/  \/_/   \/_/   \/_/\/_/   \/_/ \/_/  -
-                                                                                                               -    
-- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- -- -- - -- - -- - -- - -- - -- - -- - --


*/

pragma solidity ^0.8.4;

import "./ERC1155Burnable.sol";
import "./ERC1155Supply.sol";
import "./Ownable.sol";
import "./Strings.sol";

interface IADRandomizer {
    function rand(address) external view returns (uint256);
}

contract ADElementals is ERC1155Supply, ERC1155Burnable, Ownable {
    using Strings for uint256;

    // Token IDs
    uint256 public constant GRASS = 0;
    uint256 public constant WATER = 1;
    uint256 public constant FIRE = 2;
    uint256 public constant PSYCHIC = 3;
    uint256 public constant SPECIAL = 4;

    uint256 public constant ELEMENTALS_PER_BATCH = 3;

    string private name_;
    string private symbol_;

    address public adBoosterPackAddress;
    address private adRandomizerAddress;

    IADRandomizer adRandomizer;

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier callerIsADBoosterPack() {
        require(
            msg.sender == adBoosterPackAddress,
            "Caller is not ADBoosterPack contract"
        );
        _;
    }

    constructor(
        address _adBoosterPackAddress,
        address _adRandomizerAddress,
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) ERC1155(_uri) {
        adBoosterPackAddress = _adBoosterPackAddress;
        adRandomizer = IADRandomizer(_adRandomizerAddress);
        name_ = _name;
        symbol_ = _symbol;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============

    /**
     * @dev Generic mint function to be called by the ADBoosterPacks contract for both
     * whitelist and public sales.
     * Can only be called by the ADBoosterPacks contract.
     * Probability of minting each Elemental card:
     * - special 3%
     * - psychic 12%
     * - fire 15%
     * - water 30%
     * - grass 40%
     */
    function mint(uint256 _batch, address _to) external callerIsADBoosterPack {
        unchecked {
            uint256 numElementals = _batch * ELEMENTALS_PER_BATCH;
            uint256[] memory randomValues = expandRandomness(
                rand(_to),
                numElementals
            );
            for (uint256 i = 0; i < numElementals; i++) {
                uint256 rarityScore = randomValues[i] % 100;

                if (rarityScore < 40) {
                    _mint(_to, GRASS, 1, "");
                } else if (rarityScore < 70) {
                    _mint(_to, WATER, 1, "");
                } else if (rarityScore < 85) {
                    _mint(_to, FIRE, 1, "");
                } else if (rarityScore < 97) {
                    _mint(_to, PSYCHIC, 1, "");
                } else {
                    _mint(_to, SPECIAL, 1, "");
                }
            }
        }
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "Nonexistent token");

        return string(abi.encodePacked(super.uri(_id), _id.toString()));
    }

    // ============ INTERNAL UTIL FUNCTIONS ============

    function expandRandomness(uint256 randomValue, uint256 n)
        internal
        pure
        returns (uint256[] memory expandedValues)
    {
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)));
        }
        return expandedValues;
    }

    function rand(address _to) internal view returns (uint256 randomValue) {
        randomValue = adRandomizer.rand(_to);
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function setADBoosterPackAddress(address _adBoosterPackAddress)
        external
        onlyOwner
    {
        adBoosterPackAddress = _adBoosterPackAddress;
    }

    function setADRandomizerAddress(address _adRandomizerAddress)
        external
        onlyOwner
    {
        adRandomizerAddress = _adRandomizerAddress;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        _setURI(_baseURI);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
