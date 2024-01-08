// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice MetamalData struct might be bound for change
 */

import "./MetamalsERC721.sol";
import "./Initializable.sol";

interface Feed {
    function burn(address _from, uint256 amount) external;

    function updateReward(address _from, address _to) external;
}

contract Metamals is Initializable, MetamalsERC721 {
    string private constant _name = "Metamals";
    string private constant _symbol = "MM";

    struct MetamalData {
        string name;
        string data;
    }

    Feed public feed;

    modifier metamalOwner(uint256 metamalId) {
        require(ownerOf(metamalId) == msg.sender, "Not your Metamal!");
        _;
    }

    // Initialization function
    function initialize(
        uint256 mintCount,
        uint256 mintPrice,
        string memory uri
    ) public initializer {
        __ERC721_init_unchained(_name, _symbol);
        __Ownable_init_unchained();
        maxMetamalCount = mintCount;
        price = mintPrice;
        presaleActive = false;
        saleActive = false;
        baseURI = uri;
    }

    /**
     * @dev $F33D functionalities
     */
    mapping(uint256 => uint256) public babyMetamal;
    mapping(uint256 => MetamalData) public metamalData;

    uint256 breedCost;
    uint256 cost1;
    uint256 cost2;
}
